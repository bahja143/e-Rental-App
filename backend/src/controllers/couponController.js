const { Coupon } = require('../models');

// Get all coupons with pagination, filtering, and sorting
const getCoupons = async (req, res) => {
  try {
    const {
      page = 1,
      limit = 10,
      search,
      type,
      use_case,
      is_active,
      min_purchase_min,
      min_purchase_max,
      start_date_from,
      start_date_to,
      expire_date_from,
      expire_date_to,
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

    // Search filter with sanitization
    if (search && typeof search === 'string' && search.trim().length > 0) {
      const sanitizedSearch = search.trim().replace(/[%_]/g, '\\$&'); // Escape SQL wildcards
      whereClause.code = { [require('sequelize').Op.like]: `%${sanitizedSearch}%` };
    }

    // Type filter with validation
    if (type !== undefined) {
      const validTypes = ['percentage', 'fixed'];
      if (validTypes.includes(type)) {
        whereClause.type = type;
      }
    }

    // Use case filter with validation
    if (use_case !== undefined) {
      const validUseCases = ['listing_package', 'promotion_package', 'listing_buy', 'listing_rent'];
      if (validUseCases.includes(use_case)) {
        whereClause.use_case = use_case;
      }
    }

    // Active status filter with validation
    if (is_active !== undefined) {
      const activeBool = is_active === 'true';
      whereClause.is_active = activeBool;
    }

    // Min purchase range filter with validation
    if (min_purchase_min !== undefined || min_purchase_max !== undefined) {
      whereClause.min_purchase = {};
      if (min_purchase_min !== undefined) {
        const minPurchaseMin = parseInt(min_purchase_min);
        if (!isNaN(minPurchaseMin) && minPurchaseMin >= 0) {
          whereClause.min_purchase[require('sequelize').Op.gte] = minPurchaseMin;
        }
      }
      if (min_purchase_max !== undefined) {
        const minPurchaseMax = parseInt(min_purchase_max);
        if (!isNaN(minPurchaseMax) && minPurchaseMax >= 0) {
          whereClause.min_purchase[require('sequelize').Op.lte] = minPurchaseMax;
        }
      }
    }

    // Start date range filter with validation
    if (start_date_from !== undefined || start_date_to !== undefined) {
      whereClause.start_date = {};
      if (start_date_from !== undefined) {
        const startDateFrom = new Date(start_date_from);
        if (!isNaN(startDateFrom.getTime())) {
          whereClause.start_date[require('sequelize').Op.gte] = startDateFrom;
        }
      }
      if (start_date_to !== undefined) {
        const startDateTo = new Date(start_date_to);
        if (!isNaN(startDateTo.getTime())) {
          whereClause.start_date[require('sequelize').Op.lte] = startDateTo;
        }
      }
    }

    // Expire date range filter with validation
    if (expire_date_from !== undefined || expire_date_to !== undefined) {
      whereClause.expire_date = {};
      if (expire_date_from !== undefined) {
        const expireDateFrom = new Date(expire_date_from);
        if (!isNaN(expireDateFrom.getTime())) {
          whereClause.expire_date[require('sequelize').Op.gte] = expireDateFrom;
        }
      }
      if (expire_date_to !== undefined) {
        const expireDateTo = new Date(expire_date_to);
        if (!isNaN(expireDateTo.getTime())) {
          whereClause.expire_date[require('sequelize').Op.lte] = expireDateTo;
        }
      }
    }

    // Sorting with validation
    const validSortFields = ['id', 'code', 'type', 'value', 'use_case', 'min_purchase', 'start_date', 'expire_date', 'usage_limit', 'per_user_limit', 'is_active', 'used', 'createdAt', 'updatedAt'];
    const sortField = validSortFields.includes(sortBy) ? sortBy : 'createdAt';
    const sortDirection = sortOrder.toUpperCase() === 'ASC' ? 'ASC' : 'DESC';

    const { count, rows: coupons } = await Coupon.findAndCountAll({
      where: whereClause,
      limit: limitNum,
      offset: offset,
      order: [[sortField, sortDirection]],
    });

    const totalPages = Math.ceil(count / limitNum);

    res.json({
      data: coupons,
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
    console.error('Error fetching coupons:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// Get coupon by ID
const getCouponById = async (req, res) => {
  try {
    const { id } = req.params;

    // Input validation
    const couponId = parseInt(id);
    if (isNaN(couponId) || couponId < 1) {
      return res.status(400).json({ error: 'Invalid coupon ID' });
    }

    const coupon = await Coupon.findByPk(couponId);

    if (!coupon) {
      return res.status(404).json({ error: 'Coupon not found' });
    }

    res.json(coupon);
  } catch (error) {
    console.error('Error fetching coupon:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// Create a new coupon
const createCoupon = async (req, res) => {
  try {
    const {
      code,
      type,
      value,
      use_case,
      min_purchase,
      start_date,
      expire_date,
      usage_limit,
      per_user_limit,
      is_active = true,
    } = req.body;

    // Input validation and sanitization
    if (!code || typeof code !== 'string' || code.trim().length === 0 || code.trim().length > 50) {
      return res.status(400).json({ error: 'Code must be 1-50 characters' });
    }

    const validTypes = ['percentage', 'fixed'];
    if (!type || !validTypes.includes(type)) {
      return res.status(400).json({ error: 'Type must be either "percentage" or "fixed"' });
    }

    const valueNum = parseFloat(value);
    if (isNaN(valueNum) || valueNum <= 0 || valueNum > 999999.99) {
      return res.status(400).json({ error: 'Value must be a positive number up to 999999.99' });
    }

    // Additional validation for percentage type
    if (type === 'percentage' && valueNum > 100) {
      return res.status(400).json({ error: 'Percentage value cannot exceed 100%' });
    }

    const validUseCases = ['listing_package', 'promotion_package', 'listing_buy', 'listing_rent'];
    if (!use_case || !validUseCases.includes(use_case)) {
      return res.status(400).json({ error: 'Use case must be one of: listing_package, promotion_package, listing_buy, listing_rent' });
    }

    let minPurchaseNum = null;
    if (min_purchase !== undefined) {
      minPurchaseNum = parseInt(min_purchase);
      if (isNaN(minPurchaseNum) || minPurchaseNum < 0) {
        return res.status(400).json({ error: 'Min purchase must be a non-negative integer' });
      }
    }

    let startDateObj = null;
    if (start_date) {
      startDateObj = new Date(start_date);
      if (isNaN(startDateObj.getTime())) {
        return res.status(400).json({ error: 'Invalid start date format' });
      }
    }

    let expireDateObj = null;
    if (expire_date) {
      expireDateObj = new Date(expire_date);
      if (isNaN(expireDateObj.getTime())) {
        return res.status(400).json({ error: 'Invalid expire date format' });
      }
    }

    // Validate date ranges
    if (startDateObj && expireDateObj && startDateObj >= expireDateObj) {
      return res.status(400).json({ error: 'Start date must be before expire date' });
    }

    let usageLimitNum = null;
    if (usage_limit !== undefined) {
      usageLimitNum = parseInt(usage_limit);
      if (isNaN(usageLimitNum) || usageLimitNum < 1) {
        return res.status(400).json({ error: 'Usage limit must be a positive integer' });
      }
    }

    let perUserLimitNum = null;
    if (per_user_limit !== undefined) {
      perUserLimitNum = parseInt(per_user_limit);
      if (isNaN(perUserLimitNum) || perUserLimitNum < 1) {
        return res.status(400).json({ error: 'Per user limit must be a positive integer' });
      }
    }

    const activeBool = is_active === true || is_active === 'true';

    const sanitizedCode = code.trim().toUpperCase();

    const coupon = await Coupon.create({
      code: sanitizedCode,
      type,
      value: valueNum,
      use_case,
      min_purchase: minPurchaseNum,
      start_date: startDateObj,
      expire_date: expireDateObj,
      usage_limit: usageLimitNum,
      per_user_limit: perUserLimitNum,
      is_active: activeBool,
    });

    res.status(201).json({
      message: 'Coupon created successfully',
      coupon: coupon.toJSON(),
    });
  } catch (error) {
    console.error('Error creating coupon:', error);

    if (error.name === 'SequelizeUniqueConstraintError') {
      return res.status(400).json({ error: 'Coupon code already exists' });
    }

    if (error.name === 'SequelizeValidationError') {
      return res.status(400).json({ error: error.errors[0].message });
    }

    res.status(500).json({ error: 'Internal server error' });
  }
};

// Update coupon
const updateCoupon = async (req, res) => {
  try {
    const { id } = req.params;

    // Input validation
    const couponId = parseInt(id);
    if (isNaN(couponId) || couponId < 1) {
      return res.status(400).json({ error: 'Invalid coupon ID' });
    }

    const coupon = await Coupon.findByPk(couponId);
    if (!coupon) {
      return res.status(404).json({ error: 'Coupon not found' });
    }

    const {
      code,
      type,
      value,
      use_case,
      min_purchase,
      start_date,
      expire_date,
      usage_limit,
      per_user_limit,
      is_active,
    } = req.body;

    const updateData = {};

    // Sanitize and validate provided fields
    if (code !== undefined) {
      if (typeof code !== 'string' || code.trim().length === 0 || code.trim().length > 50) {
        return res.status(400).json({ error: 'Code must be 1-50 characters' });
      }
      updateData.code = code.trim().toUpperCase();
    }

    if (type !== undefined) {
      const validTypes = ['percentage', 'fixed'];
      if (!validTypes.includes(type)) {
        return res.status(400).json({ error: 'Type must be either "percentage" or "fixed"' });
      }
      updateData.type = type;
    }

    if (value !== undefined) {
      const valueNum = parseFloat(value);
      if (isNaN(valueNum) || valueNum <= 0 || valueNum > 999999.99) {
        return res.status(400).json({ error: 'Value must be a positive number up to 999999.99' });
      }
      // Additional validation for percentage type
      if ((type || coupon.type) === 'percentage' && valueNum > 100) {
        return res.status(400).json({ error: 'Percentage value cannot exceed 100%' });
      }
      updateData.value = valueNum;
    }

    if (use_case !== undefined) {
      const validUseCases = ['listing_package', 'promotion_package', 'listing_buy', 'listing_rent'];
      if (!validUseCases.includes(use_case)) {
        return res.status(400).json({ error: 'Use case must be one of: listing_package, promotion_package, listing_buy, listing_rent' });
      }
      updateData.use_case = use_case;
    }

    if (min_purchase !== undefined) {
      if (min_purchase === null) {
        updateData.min_purchase = null;
      } else {
        const minPurchaseNum = parseInt(min_purchase);
        if (isNaN(minPurchaseNum) || minPurchaseNum < 0) {
          return res.status(400).json({ error: 'Min purchase must be a non-negative integer or null' });
        }
        updateData.min_purchase = minPurchaseNum;
      }
    }

    if (start_date !== undefined) {
      if (start_date === null) {
        updateData.start_date = null;
      } else {
        const startDateObj = new Date(start_date);
        if (isNaN(startDateObj.getTime())) {
          return res.status(400).json({ error: 'Invalid start date format' });
        }
        updateData.start_date = startDateObj;
      }
    }

    if (expire_date !== undefined) {
      if (expire_date === null) {
        updateData.expire_date = null;
      } else {
        const expireDateObj = new Date(expire_date);
        if (isNaN(expireDateObj.getTime())) {
          return res.status(400).json({ error: 'Invalid expire date format' });
        }
        updateData.expire_date = expireDateObj;
      }
    }

    if (usage_limit !== undefined) {
      if (usage_limit === null) {
        updateData.usage_limit = null;
      } else {
        const usageLimitNum = parseInt(usage_limit);
        if (isNaN(usageLimitNum) || usageLimitNum < 1) {
          return res.status(400).json({ error: 'Usage limit must be a positive integer or null' });
        }
        updateData.usage_limit = usageLimitNum;
      }
    }

    if (per_user_limit !== undefined) {
      if (per_user_limit === null) {
        updateData.per_user_limit = null;
      } else {
        const perUserLimitNum = parseInt(per_user_limit);
        if (isNaN(perUserLimitNum) || perUserLimitNum < 1) {
          return res.status(400).json({ error: 'Per user limit must be a positive integer or null' });
        }
        updateData.per_user_limit = perUserLimitNum;
      }
    }

    if (is_active !== undefined) {
      updateData.is_active = is_active === true || is_active === 'true';
    }

    // Validate date ranges if both dates are being updated
    const newStartDate = updateData.start_date !== undefined ? updateData.start_date : coupon.start_date;
    const newExpireDate = updateData.expire_date !== undefined ? updateData.expire_date : coupon.expire_date;

    if (newStartDate && newExpireDate && newStartDate >= newExpireDate) {
      return res.status(400).json({ error: 'Start date must be before expire date' });
    }

    await coupon.update(updateData);

    res.json({
      message: 'Coupon updated successfully',
      coupon: coupon.toJSON(),
    });
  } catch (error) {
    console.error('Error updating coupon:', error);

    if (error.name === 'SequelizeUniqueConstraintError') {
      return res.status(400).json({ error: 'Coupon code already exists' });
    }

    if (error.name === 'SequelizeValidationError') {
      return res.status(400).json({ error: error.errors[0].message });
    }

    res.status(500).json({ error: 'Internal server error' });
  }
};

// Delete coupon
const deleteCoupon = async (req, res) => {
  try {
    const { id } = req.params;

    // Input validation
    const couponId = parseInt(id);
    if (isNaN(couponId) || couponId < 1) {
      return res.status(400).json({ error: 'Invalid coupon ID' });
    }

    const coupon = await Coupon.findByPk(couponId);
    if (!coupon) {
      return res.status(404).json({ error: 'Coupon not found' });
    }

    await coupon.destroy();

    res.json({ message: 'Coupon deleted successfully' });
  } catch (error) {
    console.error('Error deleting coupon:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

module.exports = {
  getCoupons,
  getCouponById,
  createCoupon,
  updateCoupon,
  deleteCoupon,
};
