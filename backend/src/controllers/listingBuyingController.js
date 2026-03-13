const { ListingBuying, User, Listing, Coupon } = require('../models');
const { Op } = require('sequelize');

// Get all listing buyings with pagination, filtering, and related data
const getListingBuyings = async (req, res) => {
  try {
    const {
      page = 1,
      limit = 10,
      status,
      buyer_id,
      listing_id,
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
    const validStatuses = ['pending', 'paid', 'confirmed', 'cancelled', 'completed'];
    if (status && validStatuses.includes(status)) {
      whereClause.status = status;
    }

    // Buyer ID filter with validation
    if (buyer_id) {
      const buyerIdNum = parseInt(buyer_id);
      if (isNaN(buyerIdNum) || buyerIdNum < 1) {
        return res.status(400).json({ error: 'Invalid buyer ID' });
      }
      whereClause.buyer_id = buyerIdNum;
    }

    // Listing ID filter with validation
    if (listing_id) {
      const listingIdNum = parseInt(listing_id);
      if (isNaN(listingIdNum) || listingIdNum < 1) {
        return res.status(400).json({ error: 'Invalid listing ID' });
      }
      whereClause.listing_id = listingIdNum;
    }

    // Sorting with validation
    const validSortFields = ['id', 'subtotal', 'discount', 'total', 'status', 'createdAt', 'updatedAt'];
    const sortField = validSortFields.includes(sortBy) ? sortBy : 'createdAt';
    const sortDirection = sortOrder.toUpperCase() === 'ASC' ? 'ASC' : 'DESC';

    const { count, rows: listingBuyings } = await ListingBuying.findAndCountAll({
      where: whereClause,
      limit: limitNum,
      offset: offset,
      order: [[sortField, sortDirection]],
      include: [
        {
          model: User,
          as: 'buyer',
          attributes: ['id', 'name', 'email', 'available_balance', 'pending_balance'],
        },
        {
          model: Listing,
          as: 'listing',
          attributes: ['id', 'title', 'sell_price', 'address'],
        },
        {
          model: Coupon,
          as: 'coupon',
          attributes: ['id', 'code', 'type', 'value'],
        },
      ],
    });

    const totalPages = Math.ceil(count / limitNum);

    res.json({
      data: listingBuyings,
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
    console.error('Error fetching listing buyings:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// Get single listing buying by ID
const getListingBuyingById = async (req, res) => {
  try {
    const { id } = req.params;

    // Input validation
    const listingBuyingId = parseInt(id);
    if (isNaN(listingBuyingId) || listingBuyingId < 1) {
      return res.status(400).json({ error: 'Invalid listing buying ID' });
    }

    const listingBuying = await ListingBuying.findByPk(listingBuyingId, {
      include: [
        {
          model: User,
          as: 'buyer',
          attributes: ['id', 'name', 'email', 'available_balance', 'pending_balance'],
        },
        {
          model: Listing,
          as: 'listing',
          attributes: ['id', 'title', 'sell_price', 'address', 'images'],
        },
        {
          model: Coupon,
          as: 'coupon',
          attributes: ['id', 'code', 'type', 'value'],
        },
      ],
    });

    if (!listingBuying) {
      return res.status(404).json({ error: 'Listing buying not found' });
    }

    res.json(listingBuying);
  } catch (error) {
    console.error('Error fetching listing buying:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// Create new listing buying
const createListingBuying = async (req, res) => {
  try {
    const {
      listing_id,
      buyer_id,
      subtotal,
      coupon_code,
      coupon_id,
      discount,
      total,
      status,
      commission,
      sellers_value,
      bank_name,
      branch,
      bank_account,
      account_holder_name,
      swift,
    } = req.body;

    // Input validation and sanitization
    const listingIdNum = parseInt(listing_id);
    if (isNaN(listingIdNum) || listingIdNum < 1) {
      return res.status(400).json({ error: 'Invalid listing ID' });
    }

    const buyerIdNum = parseInt(buyer_id);
    if (isNaN(buyerIdNum) || buyerIdNum < 1) {
      return res.status(400).json({ error: 'Invalid buyer ID' });
    }

    // Validate monetary values
    const subtotalNum = parseFloat(subtotal);
    if (isNaN(subtotalNum) || subtotalNum < 0) {
      return res.status(400).json({ error: 'Invalid subtotal (must be non-negative number)' });
    }

    const discountNum = parseFloat(discount || 0);
    if (isNaN(discountNum) || discountNum < 0) {
      return res.status(400).json({ error: 'Invalid discount (must be non-negative number)' });
    }

    const totalNum = parseFloat(total);
    if (isNaN(totalNum) || totalNum < 0) {
      return res.status(400).json({ error: 'Invalid total (must be non-negative number)' });
    }

    const commissionNum = parseFloat(commission || 0);
    if (isNaN(commissionNum) || commissionNum < 0) {
      return res.status(400).json({ error: 'Invalid commission (must be non-negative number)' });
    }

    const sellersValueNum = parseFloat(sellers_value || 0);
    if (isNaN(sellersValueNum) || sellersValueNum < 0) {
      return res.status(400).json({ error: 'Invalid sellers_value (must be non-negative number)' });
    }

    // Validate total calculation
    const expectedTotal = subtotalNum - discountNum;
    if (Math.abs(totalNum - expectedTotal) > 0.01) {
      return res.status(400).json({ error: 'Total must equal subtotal minus discount' });
    }

    // Validate status enum
    const validStatuses = ['pending', 'paid', 'confirmed', 'cancelled', 'completed'];
    if (status && !validStatuses.includes(status)) {
      return res.status(400).json({ error: 'Invalid status value' });
    }

    // Check if listing exists
    const listing = await Listing.findByPk(listingIdNum);
    if (!listing) {
      return res.status(404).json({ error: 'Listing not found' });
    }

    // Check if buyer exists
    const buyer = await User.findByPk(buyerIdNum);
    if (!buyer) {
      return res.status(404).json({ error: 'Buyer not found' });
    }

    // Check if coupon exists (if provided)
    let coupon = null;
    if (coupon_id) {
      const couponIdNum = parseInt(coupon_id);
      if (isNaN(couponIdNum) || couponIdNum < 1) {
        return res.status(400).json({ error: 'Invalid coupon ID' });
      }
      coupon = await Coupon.findByPk(couponIdNum);
      if (!coupon) {
        return res.status(404).json({ error: 'Coupon not found' });
      }
    }

    // Sanitize optional string fields
    const sanitizedData = {
      listing_id: listingIdNum,
      buyer_id: buyerIdNum,
      subtotal: subtotalNum,
      coupon_code: typeof coupon_code === 'string' ? coupon_code.trim().substring(0, 255) : null,
      coupon_id: coupon ? coupon.id : null,
      discount: discountNum,
      total: totalNum,
      status: status || 'pending',
      commission: commissionNum,
      sellers_value: sellersValueNum,
      bank_name: typeof bank_name === 'string' ? bank_name.trim().substring(0, 255) : null,
      branch: typeof branch === 'string' ? branch.trim().substring(0, 255) : null,
      bank_account: typeof bank_account === 'string' ? bank_account.trim().substring(0, 255) : null,
      account_holder_name: typeof account_holder_name === 'string' ? account_holder_name.trim().substring(0, 255) : null,
      swift: typeof swift === 'string' ? swift.trim().substring(0, 50) : null,
    };

    const listingBuying = await ListingBuying.create(sanitizedData);

    // Fetch created record with related data
    const createdListingBuying = await ListingBuying.findByPk(listingBuying.id, {
      include: [
        {
          model: User,
          as: 'buyer',
          attributes: ['id', 'name', 'email', 'available_balance', 'pending_balance'],
        },
        {
          model: Listing,
          as: 'listing',
          attributes: ['id', 'title', 'sell_price', 'address'],
        },
        {
          model: Coupon,
          as: 'coupon',
          attributes: ['id', 'code', 'type', 'value'],
        },
      ],
    });

    res.status(201).json({
      message: 'Listing buying created successfully',
      listingBuying: createdListingBuying,
    });
  } catch (error) {
    console.error('Error creating listing buying:', error);

    if (error.name === 'SequelizeValidationError') {
      return res.status(400).json({ error: error.errors[0].message });
    }

    res.status(500).json({ error: 'Internal server error' });
  }
};

// Update listing buying
const updateListingBuying = async (req, res) => {
  try {
    const { id } = req.params;
    const {
      subtotal,
      coupon_code,
      coupon_id,
      discount,
      total,
      status,
      commission,
      sellers_value,
      bank_name,
      branch,
      bank_account,
      account_holder_name,
      swift,
    } = req.body;

    // Input validation
    const listingBuyingId = parseInt(id);
    if (isNaN(listingBuyingId) || listingBuyingId < 1) {
      return res.status(400).json({ error: 'Invalid listing buying ID' });
    }

    const listingBuying = await ListingBuying.findByPk(listingBuyingId);
    if (!listingBuying) {
      return res.status(404).json({ error: 'Listing buying not found' });
    }

    const updateData = {};

    // Validate and sanitize monetary values
    if (subtotal !== undefined) {
      const subtotalNum = parseFloat(subtotal);
      if (isNaN(subtotalNum) || subtotalNum < 0) {
        return res.status(400).json({ error: 'Invalid subtotal (must be non-negative number)' });
      }
      updateData.subtotal = subtotalNum;
    }

    if (discount !== undefined) {
      const discountNum = parseFloat(discount);
      if (isNaN(discountNum) || discountNum < 0) {
        return res.status(400).json({ error: 'Invalid discount (must be non-negative number)' });
      }
      updateData.discount = discountNum;
    }

    if (total !== undefined) {
      const totalNum = parseFloat(total);
      if (isNaN(totalNum) || totalNum < 0) {
        return res.status(400).json({ error: 'Invalid total (must be non-negative number)' });
      }
      updateData.total = totalNum;
    }

    if (commission !== undefined) {
      const commissionNum = parseFloat(commission);
      if (isNaN(commissionNum) || commissionNum < 0) {
        return res.status(400).json({ error: 'Invalid commission (must be non-negative number)' });
      }
      updateData.commission = commissionNum;
    }

    if (sellers_value !== undefined) {
      const sellersValueNum = parseFloat(sellers_value);
      if (isNaN(sellersValueNum) || sellersValueNum < 0) {
        return res.status(400).json({ error: 'Invalid sellers_value (must be non-negative number)' });
      }
      updateData.sellers_value = sellersValueNum;
    }

    // Validate status enum
    const validStatuses = ['pending', 'paid', 'confirmed', 'cancelled', 'completed'];
    if (status !== undefined && !validStatuses.includes(status)) {
      return res.status(400).json({ error: 'Invalid status value' });
    }
    if (status !== undefined) {
      updateData.status = status;
    }

    // Validate total calculation if subtotal, discount, or total are being updated
    if (updateData.subtotal !== undefined || updateData.discount !== undefined || updateData.total !== undefined) {
      const currentSubtotal = updateData.subtotal !== undefined ? updateData.subtotal : listingBuying.subtotal;
      const currentDiscount = updateData.discount !== undefined ? updateData.discount : listingBuying.discount;
      const currentTotal = updateData.total !== undefined ? updateData.total : listingBuying.total;
      const expectedTotal = currentSubtotal - currentDiscount;
      if (Math.abs(currentTotal - expectedTotal) > 0.01) {
        return res.status(400).json({ error: 'Total must equal subtotal minus discount' });
      }
    }

    // Check if coupon exists (if provided)
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
    if (coupon_code !== undefined) {
      updateData.coupon_code = coupon_code === null ? null : coupon_code.toString().trim().substring(0, 255);
    }
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

    await listingBuying.update(updateData);

    // Fetch updated record with related data
    const updatedListingBuying = await ListingBuying.findByPk(listingBuyingId, {
      include: [
        {
          model: User,
          as: 'buyer',
          attributes: ['id', 'name', 'email', 'available_balance', 'pending_balance'],
        },
        {
          model: Listing,
          as: 'listing',
          attributes: ['id', 'title', 'sell_price', 'address'],
        },
        {
          model: Coupon,
          as: 'coupon',
          attributes: ['id', 'code', 'type', 'value'],
        },
      ],
    });

    res.json({
      message: 'Listing buying updated successfully',
      listingBuying: updatedListingBuying,
    });
  } catch (error) {
    console.error('Error updating listing buying:', error);

    if (error.name === 'SequelizeValidationError') {
      return res.status(400).json({ error: error.errors[0].message });
    }

    res.status(500).json({ error: 'Internal server error' });
  }
};

// Delete listing buying
const deleteListingBuying = async (req, res) => {
  try {
    const { id } = req.params;

    // Input validation
    const listingBuyingId = parseInt(id);
    if (isNaN(listingBuyingId) || listingBuyingId < 1) {
      return res.status(400).json({ error: 'Invalid listing buying ID' });
    }

    const listingBuying = await ListingBuying.findByPk(listingBuyingId);
    if (!listingBuying) {
      return res.status(404).json({ error: 'Listing buying not found' });
    }

    await listingBuying.destroy();

    res.json({ message: 'Listing buying deleted successfully' });
  } catch (error) {
    console.error('Error deleting listing buying:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

module.exports = {
  getListingBuyings,
  getListingBuyingById,
  createListingBuying,
  updateListingBuying,
  deleteListingBuying,
};
