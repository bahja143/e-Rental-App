const {
  ListingRental,
  Listing,
  User,
  Coupon,
  ThirdPartyPayment,
  sequelize,
} = require('../models');
const rentalService = require('../services/rentalService');
const notificationService = require('../services/notificationService');
const waafiPayService = require('../services/waafiPayService');

const requireAdmin = (req, res, next) => {
  const role = `${req.user?.role ?? ''}`.toLowerCase();
  if (role !== 'admin') {
    return res.status(403).json({ error: 'Admin access required' });
  }
  return next();
};

const toAmount = (value) => {
  const parsed = Number(value ?? 0);
  return Number.isFinite(parsed) ? Number(parsed.toFixed(2)) : 0;
};

const parseDate = (value, fieldName) => {
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) {
    const error = new Error(`Valid ${fieldName} is required`);
    error.statusCode = 400;
    throw error;
  }
  return date;
};

const buildRentalQuote = async ({ listId, renterId, startDate, endDate, rentType, couponId, couponCode }) => {
  const listing = await Listing.findByPk(listId);
  if (!listing) {
    const error = new Error('Listing not found');
    error.statusCode = 404;
    throw error;
  }

  const renter = await User.findByPk(renterId);
  if (!renter) {
    const error = new Error('Renter not found');
    error.statusCode = 404;
    throw error;
  }

  if (parseInt(listing.user_id, 10) === parseInt(renterId, 10)) {
    const error = new Error('You cannot rent your own listing');
    error.statusCode = 400;
    throw error;
  }

  const { available } = await rentalService.checkListingAvailability(listId, startDate, endDate);
  if (!available) {
    const error = new Error('Listing is not available for the selected dates');
    error.statusCode = 409;
    throw error;
  }

  const listingRentType = listing.rent_type || rentType;
  if (!listing.rent_price || Number(listing.rent_price) <= 0) {
    const error = new Error('Listing has no rent price configured');
    error.statusCode = 400;
    throw error;
  }

  const subtotal = rentalService.calculateRentalSubtotal(listing.rent_price, listingRentType, startDate, endDate);
  let discount = 0;
  let coupon = null;
  let resolvedCouponId = null;
  let resolvedCouponCode = null;

  if (couponId || couponCode) {
    coupon = await rentalService.resolveCoupon(couponId ? parseInt(couponId, 10) : null, couponCode);
    const couponResult = await rentalService.validateAndApplyCoupon(coupon, subtotal, 'listing_rent', renterId);
    if (!couponResult.valid) {
      const error = new Error(couponResult.error);
      error.statusCode = 400;
      throw error;
    }
    discount = couponResult.discount;
    if (coupon) {
      resolvedCouponId = coupon.id;
      resolvedCouponCode = coupon.code;
    }
  }

  const total = waafiPayService.safeAmount(subtotal - discount);

  return {
    listing,
    renter,
    coupon,
    rentalData: {
      list_id: listId,
      renter_id: renterId,
      start_date: startDate,
      end_date: endDate,
      rent_type: rentType,
      status: 'pending',
      date: new Date(),
      bank_name: 'Waafi Pay',
      branch: null,
      bank_account: null,
      account_holder_name: renter.name,
      swift: null,
      subtotal,
      coupon_code: resolvedCouponCode,
      coupon_id: resolvedCouponId,
      discount,
      total,
      commission: 0,
      sellers_value: total,
    },
  };
};

const initiateWaafiListingRentalPayment = async (req, res) => {
  try {
    const renterId = req.user?.userId ?? req.user?.id;
    if (!renterId) {
      return res.status(401).json({ error: 'Authentication required' });
    }

    const {
      list_id,
      start_date,
      end_date,
      rent_type,
      coupon_id,
      coupon_code,
      phone_number,
    } = req.body || {};

    const listId = parseInt(list_id, 10);
    if (Number.isNaN(listId) || listId < 1) {
      return res.status(400).json({ error: 'Valid list_id is required' });
    }

    const rentType = `${rent_type || 'monthly'}`.toLowerCase();
    if (!['daily', 'monthly', 'yearly'].includes(rentType)) {
      return res.status(400).json({ error: 'Valid rent_type is required' });
    }

    const startDate = parseDate(start_date, 'start_date');
    const endDate = parseDate(end_date, 'end_date');
    if (endDate <= startDate) {
      return res.status(400).json({ error: 'End date must be after start date' });
    }

    const quote = await buildRentalQuote({
      listId,
      renterId,
      startDate,
      endDate,
      rentType,
      couponId: coupon_id,
      couponCode: coupon_code,
    });

    const payerPhone = phone_number || quote.renter.phone;
    const normalizedPayerPhone = waafiPayService.normalizeSomaliPhone(payerPhone);
    if (!normalizedPayerPhone) {
      return res.status(400).json({ error: 'Invalid phone number format. Use +2526XXXXXXXX or 2526XXXXXXXX.' });
    }
    const currency = process.env.WAAFI_PAY_CURRENCY || process.env.APP_CURRENCY || 'USD';
    const transactionRef = `WAAFI_${Date.now()}_${renterId}_${listId}`;
    const invoiceId = `INV_${Date.now()}_${renterId}_${listId}`;
    const amount = toAmount(quote.rentalData.total);

    const pendingPayment = await ThirdPartyPayment.create({
      user_id: renterId,
      provider: 'waafi',
      context: 'listing_rental',
      status: 'pending',
      amount,
      currency,
      payer_account: normalizedPayerPhone,
      transaction_ref: transactionRef,
      invoice_id: invoiceId,
      request_id: 'pending',
      metadata: {
        list_id: listId,
        start_date: startDate.toISOString(),
        end_date: endDate.toISOString(),
        rent_type: rentType,
        coupon_id: coupon_id || null,
        coupon_code: coupon_code || null,
      },
    });

    const waafiResult = await waafiPayService.initiatePurchase({
      amount,
      currency,
      payerPhone,
      transactionRef,
      invoiceId,
      description: `Listing rental #${listId}`,
      metadata: {
        userId: String(renterId),
        listId: String(listId),
        paymentContext: 'listing_rental',
      },
    });

    await pendingPayment.update({
      request_id: waafiResult.requestId,
      payer_account: waafiResult.normalizedPhone,
      response_code: String(waafiResult.result?.responseCode || ''),
      response_message: waafiResult.result?.params?.description || waafiResult.result?.responseMsg || null,
      raw_response: waafiResult.result,
      status: waafiResult.approved ? 'success' : 'failed',
    });

    if (!waafiResult.approved) {
      return res.status(402).json({
        error: pendingPayment.response_message || 'Waafi payment failed',
        payment: pendingPayment,
      });
    }

    const createdRental = await sequelize.transaction(async (transaction) => {
      const listingRental = await ListingRental.create(quote.rentalData, { transaction });
      await pendingPayment.update({ listing_rental_id: listingRental.id }, { transaction });
      if (quote.coupon) {
        await Coupon.increment('used', { by: 1, where: { id: quote.coupon.id }, transaction });
      }
      return listingRental;
    });

    try {
      await notificationService.notifyOwnerRentalRequest(
        quote.listing.user_id,
        quote.renter.name,
        quote.listing.title,
        createdRental.id
      );
    } catch (notifErr) {
      console.error('Failed to send owner notification:', notifErr);
    }

    const listingRental = await ListingRental.findByPk(createdRental.id, {
      include: [
        { model: Listing, as: 'listing', attributes: ['id', 'title', 'address', 'user_id'] },
        { model: User, as: 'renter', attributes: ['id', 'name', 'email', 'phone'] },
      ],
    });

    res.status(201).json({
      message: 'Waafi payment approved and booking created',
      payment: pendingPayment,
      listingRental,
    });
  } catch (error) {
    console.error('Waafi listing rental payment error:', error);
    res.status(error.statusCode || 500).json({ error: error.message || 'Internal server error' });
  }
};

const getThirdPartyPayments = async (req, res) => {
  try {
    const {
      page = 1,
      limit = 10,
      provider,
      status,
      start_date,
      end_date,
    } = req.query;

    const pageNum = Math.max(parseInt(page, 10) || 1, 1);
    const limitNum = Math.min(Math.max(parseInt(limit, 10) || 10, 1), 100);
    const where = {};

    if (provider && ['waafi'].includes(provider)) where.provider = provider;
    if (status && ['pending', 'success', 'failed'].includes(status)) where.status = status;

    if (start_date || end_date) {
      const { Op } = require('sequelize');
      where.createdAt = {};
      if (start_date) where.createdAt[Op.gte] = parseDate(start_date, 'start_date');
      if (end_date) where.createdAt[Op.lte] = parseDate(end_date, 'end_date');
    }

    const { count, rows } = await ThirdPartyPayment.findAndCountAll({
      where,
      limit: limitNum,
      offset: (pageNum - 1) * limitNum,
      order: [['createdAt', 'DESC']],
      include: [
        { model: User, as: 'user', attributes: ['id', 'name', 'email', 'phone'] },
        {
          model: ListingRental,
          as: 'listingRental',
          attributes: ['id', 'list_id', 'total', 'status'],
          include: [{ model: Listing, as: 'listing', attributes: ['id', 'title'] }],
        },
      ],
    });

    const summary = await ThirdPartyPayment.findAll({
      attributes: ['status', [sequelize.fn('COUNT', sequelize.col('id')), 'count'], [sequelize.fn('SUM', sequelize.col('amount')), 'amount']],
      group: ['status'],
      raw: true,
    });

    res.json({
      data: rows,
      summary: summary.reduce((acc, row) => {
        acc[row.status] = {
          count: Number(row.count || 0),
          amount: toAmount(row.amount),
        };
        return acc;
      }, {}),
      pagination: {
        currentPage: pageNum,
        totalPages: Math.ceil(count / limitNum),
        totalItems: count,
        itemsPerPage: limitNum,
      },
    });
  } catch (error) {
    console.error('Third-party payment report error:', error);
    res.status(error.statusCode || 500).json({ error: error.message || 'Failed to load third-party payments' });
  }
};

module.exports = {
  requireAdmin,
  initiateWaafiListingRentalPayment,
  getThirdPartyPayments,
};
