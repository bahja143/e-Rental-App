const { ListingRental, Listing, User, Coupon } = require('../models');
const { Op } = require('sequelize');
const rentalService = require('../services/rentalService');
const notificationService = require('../services/notificationService');

// Get all listing rentals with pagination, filtering, and related data
// Non-admin users only see rentals they're involved in (as renter or listing owner)
const getListingRentals = async (req, res) => {
  try {
    const userId = req.user?.userId ?? req.user?.id;
    const isAdmin = req.user?.role === 'admin';

    const {
      page = 1,
      limit = 10,
      status,
      rent_type,
      list_id,
      renter_id,
      start_date,
      end_date,
      sortBy = 'createdAt',
      sortOrder = 'DESC',
    } = req.query;

    // Input validation and sanitization
    const pageNum = parseInt(page);
    const limitNum = parseInt(limit);

    if (isNaN(pageNum) || pageNum < 1) {
      return res.status(400).json({ error: 'Invalid page number' });
    }
    if (isNaN(limitNum) || limitNum < 1 || limitNum > 100) {
      return res.status(400).json({ error: 'Invalid limit (1-100)' });
    }

    const offset = (pageNum - 1) * limitNum;
    const whereClause = {};

    // Status filter with validation
    const validStatuses = ['pending', 'confirmed', 'cancelled', 'completed'];
    if (status && validStatuses.includes(status)) {
      whereClause.status = status;
    }

    // Rent type filter with validation
    const validRentTypes = ['daily', 'monthly', 'yearly'];
    if (rent_type && validRentTypes.includes(rent_type)) {
      whereClause.rent_type = rent_type;
    }

    // List ID filter with validation
    if (list_id) {
      const listIdNum = parseInt(list_id);
      if (isNaN(listIdNum) || listIdNum < 1) {
        return res.status(400).json({ error: 'Invalid list ID' });
      }
      whereClause.list_id = listIdNum;
    }

    // Renter ID filter with validation
    if (renter_id) {
      const renterIdNum = parseInt(renter_id);
      if (isNaN(renterIdNum) || renterIdNum < 1) {
        return res.status(400).json({ error: 'Invalid renter ID' });
      }
      if (!isAdmin && renterIdNum !== userId) {
        return res.status(403).json({ error: 'You can only filter by your own renter_id' });
      }
      whereClause.renter_id = renterIdNum;
    }

    // Non-admin: only show rentals where user is renter or listing owner
    if (!isAdmin && userId) {
      whereClause[Op.or] = [
        { renter_id: userId },
        { '$listing.user_id$': userId },
      ];
    }

    // Date range filter with validation
    if (start_date || end_date) {
      whereClause.start_date = {};
      if (start_date) {
        const startDate = new Date(start_date);
        if (isNaN(startDate.getTime())) {
          return res.status(400).json({ error: 'Invalid start_date format' });
        }
        whereClause.start_date[Op.gte] = startDate;
      }
      if (end_date) {
        const endDate = new Date(end_date);
        if (isNaN(endDate.getTime())) {
          return res.status(400).json({ error: 'Invalid end_date format' });
        }
        whereClause.start_date[Op.lte] = endDate;
      }
    }

    // Sorting with validation
    const validSortFields = ['id', 'start_date', 'end_date', 'rent_type', 'status', 'subtotal', 'total', 'createdAt', 'updatedAt'];
    const sortField = validSortFields.includes(sortBy) ? sortBy : 'createdAt';
    const sortDirection = sortOrder.toUpperCase() === 'ASC' ? 'ASC' : 'DESC';

    const includeList = [
      {
        model: Listing,
        as: 'listing',
        attributes: ['id', 'title', 'address', 'rent_price', 'rent_type', 'user_id'],
        required: !!whereClause[Op.or],
      },
      { model: User, as: 'renter', attributes: ['id', 'name', 'email', 'phone'] },
      { model: Coupon, as: 'coupon', attributes: ['id', 'code', 'type', 'value'] },
    ];

    const { count, rows: listingRentals } = await ListingRental.findAndCountAll({
      where: whereClause,
      limit: limitNum,
      offset: offset,
      order: [[sortField, sortDirection]],
      include: includeList,
    });

    const totalPages = Math.ceil(count / limitNum);

    res.json({
      data: listingRentals,
      pagination: {
        currentPage: pageNum,
        totalPages,
        totalItems: count,
        itemsPerPage: limitNum,
        hasNextPage: pageNum < totalPages,
        hasPrevPage: pageNum > 1,
      },
    });
  } catch (error) {
    console.error('Error fetching listing rentals:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// Get single listing rental (must be renter or listing owner)
const getListingRentalById = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user?.userId ?? req.user?.id;
    const isAdmin = req.user?.role === 'admin';

    const rentalId = parseInt(id);
    if (isNaN(rentalId) || rentalId < 1) {
      return res.status(400).json({ error: 'Invalid listing rental ID' });
    }

    const listingRental = await ListingRental.findByPk(rentalId, {
      include: [
        {
          model: Listing,
          as: 'listing',
          attributes: ['id', 'title', 'address', 'rent_price', 'rent_type', 'user_id'],
        },
        { model: User, as: 'renter', attributes: ['id', 'name', 'email', 'phone'] },
        { model: Coupon, as: 'coupon', attributes: ['id', 'code', 'type', 'value'] },
      ],
    });

    if (!listingRental) {
      return res.status(404).json({ error: 'Listing rental not found' });
    }

    if (!isAdmin && userId) {
      const isRenter = parseInt(listingRental.renter_id) === parseInt(userId);
      const isOwner = parseInt(listingRental.listing?.user_id) === parseInt(userId);
      if (!isRenter && !isOwner) {
        return res.status(403).json({ error: 'You do not have permission to view this rental' });
      }
    }

    res.json(listingRental);
  } catch (error) {
    console.error('Error fetching listing rental:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// Create new listing rental (renter_id from auth; availability check; price calculation; coupon validation)
const createListingRental = async (req, res) => {
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
      status = 'pending',
      date,
      bank_name,
      branch,
      bank_account,
      account_holder_name,
      swift,
      coupon_code,
      coupon_id,
      commission = 0,
      sellers_value,
    } = req.body;

    // Input validation
    const listIdNum = parseInt(list_id);
    if (isNaN(listIdNum) || listIdNum < 1) {
      return res.status(400).json({ error: 'Valid list_id is required' });
    }

    const startDate = new Date(start_date);
    const endDate = new Date(end_date);
    if (isNaN(startDate.getTime())) {
      return res.status(400).json({ error: 'Valid start_date is required' });
    }
    if (isNaN(endDate.getTime())) {
      return res.status(400).json({ error: 'Valid end_date is required' });
    }
    if (endDate <= startDate) {
      return res.status(400).json({ error: 'End date must be after start date' });
    }

    const validRentTypes = ['daily', 'monthly', 'yearly'];
    const rentType = rent_type || 'daily';
    if (!validRentTypes.includes(rentType)) {
      return res.status(400).json({ error: 'Valid rent_type is required' });
    }

    if (status !== 'pending') {
      return res.status(400).json({ error: 'New rentals must be created with status "pending"' });
    }

    // Fetch listing and renter
    const listing = await Listing.findByPk(listIdNum);
    if (!listing) {
      return res.status(404).json({ error: 'Listing not found' });
    }

    const renter = await User.findByPk(renterId);
    if (!renter) {
      return res.status(404).json({ error: 'Renter not found' });
    }

    // Prevent self-rental
    if (parseInt(listing.user_id) === parseInt(renterId)) {
      return res.status(400).json({ error: 'You cannot rent your own listing' });
    }

    // Availability check - prevent double-booking
    const { available } = await rentalService.checkListingAvailability(listIdNum, startDate, endDate);
    if (!available) {
      return res.status(409).json({ error: 'Listing is not available for the selected dates' });
    }

    // Server-side price calculation
    const listingRentType = listing.rent_type || rentType;
    const rentPrice = listing.rent_price;
    if (!rentPrice || rentPrice <= 0) {
      return res.status(400).json({ error: 'Listing has no rent price configured' });
    }

    const subtotalFloat = rentalService.calculateRentalSubtotal(rentPrice, listingRentType, startDate, endDate);
    let discountFloat = 0;
    let coupon = null;
    let sanitizedCouponCode = null;
    let couponIdResolved = null;

    if (coupon_id || coupon_code) {
      coupon = await rentalService.resolveCoupon(coupon_id ? parseInt(coupon_id) : null, coupon_code);
      const result = await rentalService.validateAndApplyCoupon(coupon, subtotalFloat, 'listing_rent', renterId);
      if (!result.valid) {
        return res.status(400).json({ error: result.error });
      }
      discountFloat = result.discount;
      if (coupon) {
        couponIdResolved = coupon.id;
        sanitizedCouponCode = coupon.code;
      }
    }

    const totalFloat = Math.round((subtotalFloat - discountFloat) * 100) / 100;
    const commissionFloat = parseFloat(commission) || 0;
    const sellersValueFloat = parseFloat(sellers_value);
    const finalSellersValue = isNaN(sellersValueFloat) || sellersValueFloat < 0 ? totalFloat - commissionFloat : sellersValueFloat;

    // Validate date if provided
    let validatedDate = new Date();
    if (date) {
      const dateObj = new Date(date);
      if (!isNaN(dateObj.getTime())) validatedDate = dateObj;
    }

    const sanitizedBankName = bank_name ? String(bank_name).trim().substring(0, 255) : null;
    const sanitizedBranch = branch ? String(branch).trim().substring(0, 255) : null;
    const sanitizedBankAccount = bank_account ? String(bank_account).trim().substring(0, 255) : null;
    const sanitizedAccountHolder = account_holder_name ? String(account_holder_name).trim().substring(0, 255) : null;
    const sanitizedSwift = swift ? String(swift).trim().substring(0, 50) : null;

    const rentalData = {
      list_id: listIdNum,
      renter_id: renterId,
      start_date: startDate,
      end_date: endDate,
      rent_type: rentType,
      status,
      date: validatedDate,
      bank_name: sanitizedBankName,
      branch: sanitizedBranch,
      bank_account: sanitizedBankAccount,
      account_holder_name: sanitizedAccountHolder,
      swift: sanitizedSwift,
      subtotal: subtotalFloat,
      coupon_code: sanitizedCouponCode,
      coupon_id: couponIdResolved,
      discount: discountFloat,
      total: totalFloat,
      commission: commissionFloat,
      sellers_value: finalSellersValue,
    };

    const listingRental = await ListingRental.create(rentalData);

    // Increment coupon usage
    if (coupon) {
      await coupon.increment('used');
    }

    // Notify listing owner
    try {
      await notificationService.notifyOwnerRentalRequest(
        listing.user_id,
        renter.name,
        listing.title,
        listingRental.id
      );
    } catch (notifErr) {
      console.error('Failed to send owner notification:', notifErr);
    }

    const createdRental = await ListingRental.findByPk(listingRental.id, {
      include: [
        { model: Listing, as: 'listing', attributes: ['id', 'title', 'address', 'rent_price', 'rent_type'] },
        { model: User, as: 'renter', attributes: ['id', 'name', 'email', 'phone'] },
        { model: Coupon, as: 'coupon', attributes: ['id', 'code', 'type', 'value'] },
      ],
    });

    res.status(201).json({
      message: 'Listing rental created successfully',
      listingRental: createdRental,
    });
  } catch (error) {
    console.error('Error creating listing rental:', error);
    if (error.name === 'SequelizeValidationError') {
      return res.status(400).json({ error: error.errors[0].message });
    }
    res.status(500).json({ error: 'Internal server error' });
  }
};

// Update listing rental
const updateListingRental = async (req, res) => {
  try {
    const { id } = req.params;

    // Input validation
    const rentalId = parseInt(id);
    if (isNaN(rentalId) || rentalId < 1) {
      return res.status(400).json({ error: 'Invalid listing rental ID' });
    }

    const {
      start_date,
      end_date,
      rent_type,
      status,
      date,
      bank_name,
      branch,
      bank_account,
      account_holder_name,
      swift,
      subtotal,
      coupon_code,
      coupon_id,
      discount,
      total,
      commission,
      sellers_value,
    } = req.body;

    const listingRental = await ListingRental.findByPk(rentalId, {
      include: [
        { model: Listing, as: 'listing', attributes: ['id', 'title', 'user_id'] },
        { model: User, as: 'renter', attributes: ['id', 'name'] },
      ],
    });
    if (!listingRental) {
      return res.status(404).json({ error: 'Listing rental not found' });
    }

    const userId = req.user?.userId ?? req.user?.id;
    const isAdmin = req.user?.role === 'admin';
    const isRenter = parseInt(listingRental.renter_id) === parseInt(userId);
    const isOwner = parseInt(listingRental.listing?.user_id) === parseInt(userId);
    if (!isAdmin && !isRenter && !isOwner) {
      return res.status(403).json({ error: 'You do not have permission to modify this rental' });
    }
    if (status === 'confirmed' && !isAdmin && !isOwner) {
      return res.status(403).json({ error: 'Only the listing owner can confirm a rental' });
    }

    const updateData = {};

    // Validate and sanitize provided fields
    if (start_date !== undefined) {
      const startDate = new Date(start_date);
      if (isNaN(startDate.getTime())) {
        return res.status(400).json({ error: 'Invalid start_date format' });
      }
      updateData.start_date = startDate;
    }

    if (end_date !== undefined) {
      const endDate = new Date(end_date);
      if (isNaN(endDate.getTime())) {
        return res.status(400).json({ error: 'Invalid end_date format' });
      }
      updateData.end_date = endDate;
    }

    // Validate date range if both dates are being updated
    if (updateData.start_date && updateData.end_date) {
      if (updateData.end_date <= updateData.start_date) {
        return res.status(400).json({ error: 'End date must be after start date' });
      }
    } else if (updateData.start_date && !updateData.end_date) {
      if (updateData.start_date >= listingRental.end_date) {
        return res.status(400).json({ error: 'Start date must be before end date' });
      }
    } else if (!updateData.start_date && updateData.end_date) {
      if (updateData.end_date <= listingRental.start_date) {
        return res.status(400).json({ error: 'End date must be after start date' });
      }
    }

    if (rent_type !== undefined) {
      const validRentTypes = ['daily', 'monthly', 'yearly'];
      if (!validRentTypes.includes(rent_type)) {
        return res.status(400).json({ error: 'Invalid rent_type value' });
      }
      updateData.rent_type = rent_type;
    }

    // When dates change, check availability
    const newStart = updateData.start_date || listingRental.start_date;
    const newEnd = updateData.end_date || listingRental.end_date;
    if (updateData.start_date || updateData.end_date) {
      const { available } = await rentalService.checkListingAvailability(
        listingRental.list_id, newStart, newEnd, rentalId
      );
      if (!available) {
        return res.status(409).json({ error: 'Listing is not available for the selected dates' });
      }
    }

    if (status !== undefined) {
      const validStatuses = ['pending', 'confirmed', 'cancelled', 'completed'];
      if (!validStatuses.includes(status)) {
        return res.status(400).json({ error: 'Invalid status value' });
      }
      updateData.status = status;
    }

    if (date !== undefined) {
      const dateObj = new Date(date);
      if (isNaN(dateObj.getTime())) {
        return res.status(400).json({ error: 'Invalid date format' });
      }
      updateData.date = dateObj;
    }

    // Validate monetary values
    if (subtotal !== undefined) {
      const val = parseFloat(subtotal);
      if (isNaN(val) || val < 0) {
        return res.status(400).json({ error: 'Subtotal must be a non-negative number' });
      }
      updateData.subtotal = val;
    }

    if (discount !== undefined) {
      const val = parseFloat(discount);
      if (isNaN(val) || val < 0) {
        return res.status(400).json({ error: 'Discount must be a non-negative number' });
      }
      updateData.discount = val;
    }

    if (total !== undefined) {
      const val = parseFloat(total);
      if (isNaN(val) || val < 0) {
        return res.status(400).json({ error: 'Total must be a non-negative number' });
      }
      updateData.total = val;
    }

    if (commission !== undefined) {
      const val = parseFloat(commission);
      if (isNaN(val) || val < 0) {
        return res.status(400).json({ error: 'Commission must be a non-negative number' });
      }
      updateData.commission = val;
    }

    if (sellers_value !== undefined) {
      const val = parseFloat(sellers_value);
      if (isNaN(val) || val < 0) {
        return res.status(400).json({ error: 'Sellers value must be a non-negative number' });
      }
      updateData.sellers_value = val;
    }

    // Validate total calculation if subtotal, discount, or total are being updated
    const currentSubtotal = updateData.subtotal !== undefined ? updateData.subtotal : listingRental.subtotal;
    const currentDiscount = updateData.discount !== undefined ? updateData.discount : listingRental.discount;
    const currentTotal = updateData.total !== undefined ? updateData.total : listingRental.total;

    if (updateData.subtotal !== undefined || updateData.discount !== undefined || updateData.total !== undefined) {
      const expectedTotal = parseFloat(currentSubtotal) - parseFloat(currentDiscount);
      if (Math.abs(parseFloat(currentTotal) - expectedTotal) > 0.01) {
        return res.status(400).json({ error: 'Total must equal subtotal minus discount' });
      }
    }

    // Check coupon if provided
    if (coupon_id !== undefined) {
      if (coupon_id === null) {
        updateData.coupon_id = null;
      } else {
        const couponIdNum = parseInt(coupon_id);
        if (isNaN(couponIdNum) || couponIdNum < 1) {
          return res.status(400).json({ error: 'Invalid coupon ID' });
        }
        const coupon = await Coupon.findByPk(couponIdNum);
        if (!coupon) {
          return res.status(404).json({ error: 'Coupon not found' });
        }
        updateData.coupon_id = couponIdNum;
      }
    }

    // Sanitize optional string fields
    if (bank_name !== undefined) {
      updateData.bank_name = bank_name === null ? null : bank_name.toString().trim().substring(0, 255);
    }
    if (branch !== undefined) {
      updateData.branch = branch === null ? null : branch.toString().trim().substring(0, 255);
    }
    if (bank_account !== undefined) {
      updateData.bank_account = bank_account === null ? null : bank_account.toString().trim().substring(0, 255);
    }
    if (account_holder_name !== undefined) {
      updateData.account_holder_name = account_holder_name === null ? null : account_holder_name.toString().trim().substring(0, 255);
    }
    if (swift !== undefined) {
      updateData.swift = swift === null ? null : swift.toString().trim().substring(0, 50);
    }
    if (coupon_code !== undefined) {
      updateData.coupon_code = coupon_code === null ? null : coupon_code.toString().trim().substring(0, 50);
    }

    const previousStatus = listingRental.status;
    await listingRental.update(updateData);

    // Notify on status change (notify the other party, not the one who made the change)
    if (updateData.status && updateData.status !== previousStatus) {
      const newStatus = updateData.status;
      if (['confirmed', 'cancelled', 'completed'].includes(newStatus)) {
        try {
          const listing = listingRental.listing;
          const renter = listingRental.renter;
          const renterName = renter?.name || 'A renter';
          if (newStatus === 'confirmed') {
            await notificationService.notifyRenterStatusChange(listingRental.renter_id, listing.title, rentalId, newStatus);
          } else if (newStatus === 'cancelled') {
            if (isOwner) {
              await notificationService.notifyRenterStatusChange(listingRental.renter_id, listing.title, rentalId, newStatus);
            } else {
              await notificationService.notifyOwnerRentalStatusChange(listing.user_id, renterName, listing.title, rentalId, newStatus);
            }
          } else if (newStatus === 'completed') {
            await notificationService.notifyRenterStatusChange(listingRental.renter_id, listing.title, rentalId, newStatus);
            await notificationService.notifyOwnerRentalStatusChange(listing.user_id, renterName, listing.title, rentalId, newStatus);
          }
        } catch (notifErr) {
          console.error('Failed to send status change notifications:', notifErr);
        }
      }
    }

    // Fetch updated record with related data
    const updatedRental = await ListingRental.findByPk(rentalId, {
      include: [
        {
          model: Listing,
          as: 'listing',
          attributes: ['id', 'title', 'address', 'rent_price', 'rent_type'],
        },
        {
          model: User,
          as: 'renter',
          attributes: ['id', 'name', 'email', 'phone'],
        },
        {
          model: Coupon,
          as: 'coupon',
          attributes: ['id', 'code', 'type', 'value'],
        },
      ],
    });

    res.json({
      message: 'Listing rental updated successfully',
      listingRental: updatedRental,
    });
  } catch (error) {
    console.error('Error updating listing rental:', error);

    if (error.name === 'SequelizeValidationError') {
      return res.status(400).json({ error: error.errors[0].message });
    }

    res.status(500).json({ error: 'Internal server error' });
  }
};

// Delete listing rental (participant only; only pending rentals should be deletable in practice)
const deleteListingRental = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user?.userId ?? req.user?.id;
    const isAdmin = req.user?.role === 'admin';

    const rentalId = parseInt(id);
    if (isNaN(rentalId) || rentalId < 1) {
      return res.status(400).json({ error: 'Invalid listing rental ID' });
    }

    const listingRental = await ListingRental.findByPk(rentalId, {
      include: [{ model: Listing, as: 'listing', attributes: ['user_id'] }],
    });
    if (!listingRental) {
      return res.status(404).json({ error: 'Listing rental not found' });
    }

    const isRenter = parseInt(listingRental.renter_id) === parseInt(userId);
    const isOwner = parseInt(listingRental.listing?.user_id) === parseInt(userId);
    if (!isAdmin && !isRenter && !isOwner) {
      return res.status(403).json({ error: 'You do not have permission to delete this rental' });
    }

    await listingRental.destroy();

    res.json({ message: 'Listing rental deleted successfully' });
  } catch (error) {
    console.error('Error deleting listing rental:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

module.exports = {
  getListingRentals,
  getListingRentalById,
  createListingRental,
  updateListingRental,
  deleteListingRental,
};
