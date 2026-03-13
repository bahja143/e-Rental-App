const { Promotion, Listing, Coupon, PromotionPack } = require('../models');

// Get all promotions with pagination, filtering, and sorting
const getPromotions = async (req, res) => {
  try {
    const {
      page = 1,
      limit = 10,
      search,
      listing_id,
      coupon_id,
      promotion_package_id,
      status,
      start_date_from,
      start_date_to,
      end_date_from,
      end_date_to,
      date_from,
      date_to,
      subtotal_min,
      subtotal_max,
      discount_min,
      discount_max,
      total_min,
      total_max,
      sortBy = 'createdAt',
      sortOrder = 'DESC',
      include_listing = 'true',
      include_coupon = 'false',
      include_promotion_pack = 'false',
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

    // Search filter with sanitization (search in coupon_code)
    if (search && typeof search === 'string' && search.trim().length > 0) {
      const sanitizedSearch = search.trim().replace(/[%_]/g, '\\$&'); // Escape SQL wildcards
      whereClause.coupon_code = { [require('sequelize').Op.like]: `%${sanitizedSearch}%` };
    }

    // Listing ID filter with validation
    if (listing_id !== undefined) {
      const listingIdNum = parseInt(listing_id);
      if (!isNaN(listingIdNum) && listingIdNum > 0) {
        whereClause.listing_id = listingIdNum;
      }
    }

    // Coupon ID filter with validation
    if (coupon_id !== undefined) {
      const couponIdNum = parseInt(coupon_id);
      if (!isNaN(couponIdNum) && couponIdNum > 0) {
        whereClause.coupon_id = couponIdNum;
      }
    }

    // Promotion Package ID filter with validation
    if (promotion_package_id !== undefined) {
      const promotionPackageIdNum = parseInt(promotion_package_id);
      if (!isNaN(promotionPackageIdNum) && promotionPackageIdNum > 0) {
        whereClause.promotion_package_id = promotionPackageIdNum;
      }
    }

    // Status filter with validation
    if (status !== undefined) {
      const validStatuses = ['active', 'expired'];
      if (validStatuses.includes(status)) {
        whereClause.status = status;
      }
    }

    // Date range filters with validation
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

    if (end_date_from !== undefined || end_date_to !== undefined) {
      whereClause.end_date = {};
      if (end_date_from !== undefined) {
        const endDateFrom = new Date(end_date_from);
        if (!isNaN(endDateFrom.getTime())) {
          whereClause.end_date[require('sequelize').Op.gte] = endDateFrom;
        }
      }
      if (end_date_to !== undefined) {
        const endDateTo = new Date(end_date_to);
        if (!isNaN(endDateTo.getTime())) {
          whereClause.end_date[require('sequelize').Op.lte] = endDateTo;
        }
      }
    }

    if (date_from !== undefined || date_to !== undefined) {
      whereClause.date = {};
      if (date_from !== undefined) {
        const dateFrom = new Date(date_from);
        if (!isNaN(dateFrom.getTime())) {
          whereClause.date[require('sequelize').Op.gte] = dateFrom;
        }
      }
      if (date_to !== undefined) {
        const dateTo = new Date(date_to);
        if (!isNaN(dateTo.getTime())) {
          whereClause.date[require('sequelize').Op.lte] = dateTo;
        }
      }
    }

    // Amount range filters with validation
    if (subtotal_min !== undefined || subtotal_max !== undefined) {
      whereClause.subtotal = {};
      if (subtotal_min !== undefined) {
        const subtotalMin = parseFloat(subtotal_min);
        if (!isNaN(subtotalMin) && subtotalMin >= 0) {
          whereClause.subtotal[require('sequelize').Op.gte] = subtotalMin;
        }
      }
      if (subtotal_max !== undefined) {
        const subtotalMax = parseFloat(subtotal_max);
        if (!isNaN(subtotalMax) && subtotalMax >= 0) {
          whereClause.subtotal[require('sequelize').Op.lte] = subtotalMax;
        }
      }
    }

    if (discount_min !== undefined || discount_max !== undefined) {
      whereClause.discount = {};
      if (discount_min !== undefined) {
        const discountMin = parseFloat(discount_min);
        if (!isNaN(discountMin) && discountMin >= 0) {
          whereClause.discount[require('sequelize').Op.gte] = discountMin;
        }
      }
      if (discount_max !== undefined) {
        const discountMax = parseFloat(discount_max);
        if (!isNaN(discountMax) && discountMax >= 0) {
          whereClause.discount[require('sequelize').Op.lte] = discountMax;
        }
      }
    }

    if (total_min !== undefined || total_max !== undefined) {
      whereClause.total = {};
      if (total_min !== undefined) {
        const totalMin = parseFloat(total_min);
        if (!isNaN(totalMin) && totalMin >= 0) {
          whereClause.total[require('sequelize').Op.gte] = totalMin;
        }
      }
      if (total_max !== undefined) {
        const totalMax = parseFloat(total_max);
        if (!isNaN(totalMax) && totalMax >= 0) {
          whereClause.total[require('sequelize').Op.lte] = totalMax;
        }
      }
    }

    // Sorting with validation
    const validSortFields = ['id', 'listing_id', 'coupon_id', 'promotion_package_id', 'subtotal', 'discount', 'total', 'start_date', 'end_date', 'date', 'status', 'createdAt', 'updatedAt'];
    const sortField = validSortFields.includes(sortBy) ? sortBy : 'createdAt';
    const sortDirection = sortOrder.toUpperCase() === 'ASC' ? 'ASC' : 'DESC';

    // Include options
    const includeOptions = [];
    if (include_listing === 'true') {
      includeOptions.push({
        model: Listing,
        as: 'listing',
        attributes: ['id', 'title', 'sell_price', 'rent_price', 'availability'],
      });
    }
    if (include_coupon === 'true') {
      includeOptions.push({
        model: Coupon,
        as: 'coupon',
        attributes: ['id', 'code', 'type', 'value', 'use_case'],
      });
    }
    if (include_promotion_pack === 'true') {
      includeOptions.push({
        model: PromotionPack,
        as: 'promotionPack',
        attributes: ['id', 'name_en', 'name_so', 'duration', 'price', 'availability'],
      });
    }

    const { count, rows: promotions } = await Promotion.findAndCountAll({
      where: whereClause,
      limit: limitNum,
      offset: offset,
      order: [[sortField, sortDirection]],
      include: includeOptions,
    });

    const totalPages = Math.ceil(count / limitNum);

    res.json({
      data: promotions,
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
    console.error('Error fetching promotions:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// Get promotion by ID
const getPromotionById = async (req, res) => {
  try {
    const { id } = req.params;
    const { include_listing = 'true', include_coupon = 'false', include_promotion_pack = 'false' } = req.query;

    // Input validation
    const promotionId = parseInt(id);
    if (isNaN(promotionId) || promotionId < 1) {
      return res.status(400).json({ error: 'Invalid promotion ID' });
    }

    // Include options
    const includeOptions = [];
    if (include_listing === 'true') {
      includeOptions.push({
        model: Listing,
        as: 'listing',
        attributes: ['id', 'title', 'sell_price', 'rent_price', 'availability'],
      });
    }
    if (include_coupon === 'true') {
      includeOptions.push({
        model: Coupon,
        as: 'coupon',
        attributes: ['id', 'code', 'type', 'value', 'use_case'],
      });
    }
    if (include_promotion_pack === 'true') {
      includeOptions.push({
        model: PromotionPack,
        as: 'promotionPack',
        attributes: ['id', 'name_en', 'name_so', 'duration', 'price', 'availability'],
      });
    }

    const promotion = await Promotion.findByPk(promotionId, {
      include: includeOptions,
    });

    if (!promotion) {
      return res.status(404).json({ error: 'Promotion not found' });
    }

    res.json(promotion);
  } catch (error) {
    console.error('Error fetching promotion:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// Create a new promotion
const createPromotion = async (req, res) => {
  try {
    const {
      listing_id,
      subtotal,
      coupon_code,
      discount = 0,
      total,
      start_date,
      end_date,
      coupon_id,
      promotion_package_id,
      date,
      status = 'active',
      bank_name,
      branch,
      bank_account,
      account_holder_name,
      swift,
    } = req.body;

    // Input validation and sanitization
    const listingIdNum = parseInt(listing_id);
    if (isNaN(listingIdNum) || listingIdNum < 1) {
      return res.status(400).json({ error: 'Valid listing ID is required' });
    }

    const subtotalNum = parseFloat(subtotal);
    if (isNaN(subtotalNum) || subtotalNum < 0) {
      return res.status(400).json({ error: 'Subtotal must be a non-negative number' });
    }

    let couponCodeSanitized = null;
    if (coupon_code !== undefined) {
      if (typeof coupon_code !== 'string' || coupon_code.trim().length > 50) {
        return res.status(400).json({ error: 'Coupon code must be a string with max 50 characters' });
      }
      couponCodeSanitized = coupon_code.trim();
    }

    const discountNum = parseFloat(discount);
    if (isNaN(discountNum) || discountNum < 0) {
      return res.status(400).json({ error: 'Discount must be a non-negative number' });
    }

    const totalNum = parseFloat(total);
    if (isNaN(totalNum) || totalNum < 0) {
      return res.status(400).json({ error: 'Total must be a non-negative number' });
    }

    // Validate total calculation
    const calculatedTotal = subtotalNum - discountNum;
    if (Math.abs(totalNum - calculatedTotal) > 0.01) {
      return res.status(400).json({ error: 'Total must equal subtotal minus discount' });
    }

    const startDateObj = new Date(start_date);
    if (isNaN(startDateObj.getTime())) {
      return res.status(400).json({ error: 'Invalid start date format' });
    }

    const endDateObj = new Date(end_date);
    if (isNaN(endDateObj.getTime())) {
      return res.status(400).json({ error: 'Invalid end date format' });
    }

    // Validate date ranges
    if (startDateObj >= endDateObj) {
      return res.status(400).json({ error: 'Start date must be before end date' });
    }

    let couponIdNum = null;
    if (coupon_id !== undefined) {
      couponIdNum = parseInt(coupon_id);
      if (isNaN(couponIdNum) || couponIdNum < 1) {
        return res.status(400).json({ error: 'Invalid coupon ID' });
      }
    }

    let dateObj = new Date();
    if (date) {
      dateObj = new Date(date);
      if (isNaN(dateObj.getTime())) {
        return res.status(400).json({ error: 'Invalid date format' });
      }
    }

    const validStatuses = ['active', 'expired'];
    if (!validStatuses.includes(status)) {
      return res.status(400).json({ error: 'Status must be either "active" or "expired"' });
    }

    // Validate bank fields if any are provided
    if (bank_name && typeof bank_name !== 'string') {
      return res.status(400).json({ error: 'Bank name must be a string' });
    }
    if (branch && typeof branch !== 'string') {
      return res.status(400).json({ error: 'Branch must be a string' });
    }
    if (bank_account && typeof bank_account !== 'string') {
      return res.status(400).json({ error: 'Bank account must be a string' });
    }
    if (account_holder_name && typeof account_holder_name !== 'string') {
      return res.status(400).json({ error: 'Account holder name must be a string' });
    }
    if (swift && typeof swift !== 'string') {
      return res.status(400).json({ error: 'SWIFT must be a string' });
    }

    // Check if listing exists
    const listing = await Listing.findByPk(listingIdNum);
    if (!listing) {
      return res.status(404).json({ error: 'Listing not found' });
    }

    // Check if coupon exists if provided
    if (couponIdNum) {
      const coupon = await Coupon.findByPk(couponIdNum);
      if (!coupon) {
        return res.status(404).json({ error: 'Coupon not found' });
      }
    }

    let promotionPackageIdNum = null;
    if (promotion_package_id !== undefined) {
      promotionPackageIdNum = parseInt(promotion_package_id);
      if (isNaN(promotionPackageIdNum) || promotionPackageIdNum < 1) {
        return res.status(400).json({ error: 'Invalid promotion package ID' });
      }
      // Check if promotion pack exists
      const promotionPack = await PromotionPack.findByPk(promotionPackageIdNum);
      if (!promotionPack) {
        return res.status(404).json({ error: 'Promotion pack not found' });
      }
    }

    const promotion = await Promotion.create({
      listing_id: listingIdNum,
      subtotal: subtotalNum.toFixed(2),
      coupon_code: couponCodeSanitized,
      discount: discountNum.toFixed(2),
      total: totalNum.toFixed(2),
      start_date: startDateObj,
      end_date: endDateObj,
      coupon_id: couponIdNum,
      promotion_package_id: promotionPackageIdNum,
      date: dateObj,
      status,
      bank_name: bank_name || null,
      branch: branch || null,
      bank_account: bank_account || null,
      account_holder_name: account_holder_name || null,
      swift: swift || null,
    });

    // Fetch with associations for response
    const promotionWithAssociations = await Promotion.findByPk(promotion.id, {
      include: [
        {
          model: Listing,
          as: 'listing',
          attributes: ['id', 'title', 'sell_price', 'rent_price', 'availability'],
        },
        {
          model: Coupon,
          as: 'coupon',
          attributes: ['id', 'code', 'type', 'value', 'use_case'],
        },
        {
          model: PromotionPack,
          as: 'promotionPack',
          attributes: ['id', 'name_en', 'name_so', 'duration', 'price', 'availability'],
        },
      ],
    });

    res.status(201).json({
      message: 'Promotion created successfully',
      promotion: promotionWithAssociations,
    });
  } catch (error) {
    console.error('Error creating promotion:', error);

    if (error.name === 'SequelizeValidationError') {
      return res.status(400).json({ error: error.errors[0].message });
    }

    res.status(500).json({ error: 'Internal server error' });
  }
};

// Update promotion
const updatePromotion = async (req, res) => {
  try {
    const { id } = req.params;

    // Input validation
    const promotionId = parseInt(id);
    if (isNaN(promotionId) || promotionId < 1) {
      return res.status(400).json({ error: 'Invalid promotion ID' });
    }

    const promotion = await Promotion.findByPk(promotionId);
    if (!promotion) {
      return res.status(404).json({ error: 'Promotion not found' });
    }

    const {
      listing_id,
      subtotal,
      coupon_code,
      discount,
      total,
      start_date,
      end_date,
      coupon_id,
      promotion_package_id,
      date,
      status,
      bank_name,
      branch,
      bank_account,
      account_holder_name,
      swift,
    } = req.body;

    const updateData = {};

    // Validate and sanitize provided fields
    if (listing_id !== undefined) {
      const listingIdNum = parseInt(listing_id);
      if (isNaN(listingIdNum) || listingIdNum < 1) {
        return res.status(400).json({ error: 'Valid listing ID is required' });
      }
      // Check if listing exists
      const listing = await Listing.findByPk(listingIdNum);
      if (!listing) {
        return res.status(404).json({ error: 'Listing not found' });
      }
      updateData.listing_id = listingIdNum;
    }

    if (subtotal !== undefined) {
      const subtotalNum = parseFloat(subtotal);
      if (isNaN(subtotalNum) || subtotalNum < 0) {
        return res.status(400).json({ error: 'Subtotal must be a non-negative number' });
      }
      updateData.subtotal = subtotalNum.toFixed(2);
    }

    if (coupon_code !== undefined) {
      if (coupon_code === null) {
        updateData.coupon_code = null;
      } else if (typeof coupon_code === 'string' && coupon_code.trim().length <= 50) {
        updateData.coupon_code = coupon_code.trim();
      } else {
        return res.status(400).json({ error: 'Coupon code must be a string with max 50 characters or null' });
      }
    }

    if (discount !== undefined) {
      const discountNum = parseFloat(discount);
      if (isNaN(discountNum) || discountNum < 0) {
        return res.status(400).json({ error: 'Discount must be a non-negative number' });
      }
      updateData.discount = discountNum.toFixed(2);
    }

    if (total !== undefined) {
      const totalNum = parseFloat(total);
      if (isNaN(totalNum) || totalNum < 0) {
        return res.status(400).json({ error: 'Total must be a non-negative number' });
      }
      updateData.total = totalNum.toFixed(2);
    }

    if (start_date !== undefined) {
      const startDateObj = new Date(start_date);
      if (isNaN(startDateObj.getTime())) {
        return res.status(400).json({ error: 'Invalid start date format' });
      }
      updateData.start_date = startDateObj;
    }

    if (end_date !== undefined) {
      const endDateObj = new Date(end_date);
      if (isNaN(endDateObj.getTime())) {
        return res.status(400).json({ error: 'Invalid end date format' });
      }
      updateData.end_date = endDateObj;
    }

    if (coupon_id !== undefined) {
      if (coupon_id === null) {
        updateData.coupon_id = null;
      } else {
        const couponIdNum = parseInt(coupon_id);
        if (isNaN(couponIdNum) || couponIdNum < 1) {
          return res.status(400).json({ error: 'Invalid coupon ID' });
        }
        // Check if coupon exists
        const coupon = await Coupon.findByPk(couponIdNum);
        if (!coupon) {
          return res.status(404).json({ error: 'Coupon not found' });
        }
        updateData.coupon_id = couponIdNum;
      }
    }

    if (promotion_package_id !== undefined) {
      if (promotion_package_id === null) {
        updateData.promotion_package_id = null;
      } else {
        const promotionPackageIdNum = parseInt(promotion_package_id);
        if (isNaN(promotionPackageIdNum) || promotionPackageIdNum < 1) {
          return res.status(400).json({ error: 'Invalid promotion package ID' });
        }
        // Check if promotion pack exists
        const promotionPack = await PromotionPack.findByPk(promotionPackageIdNum);
        if (!promotionPack) {
          return res.status(404).json({ error: 'Promotion pack not found' });
        }
        updateData.promotion_package_id = promotionPackageIdNum;
      }
    }

    if (date !== undefined) {
      const dateObj = new Date(date);
      if (isNaN(dateObj.getTime())) {
        return res.status(400).json({ error: 'Invalid date format' });
      }
      updateData.date = dateObj;
    }

    if (status !== undefined) {
      const validStatuses = ['active', 'expired'];
      if (!validStatuses.includes(status)) {
        return res.status(400).json({ error: 'Status must be either "active" or "expired"' });
      }
      updateData.status = status;
    }

    // Bank fields
    if (bank_name !== undefined) {
      updateData.bank_name = bank_name === null ? null : (typeof bank_name === 'string' ? bank_name : promotion.bank_name);
    }
    if (branch !== undefined) {
      updateData.branch = branch === null ? null : (typeof branch === 'string' ? branch : promotion.branch);
    }
    if (bank_account !== undefined) {
      updateData.bank_account = bank_account === null ? null : (typeof bank_account === 'string' ? bank_account : promotion.bank_account);
    }
    if (account_holder_name !== undefined) {
      updateData.account_holder_name = account_holder_name === null ? null : (typeof account_holder_name === 'string' ? account_holder_name : promotion.account_holder_name);
    }
    if (swift !== undefined) {
      updateData.swift = swift === null ? null : (typeof swift === 'string' ? swift : promotion.swift);
    }

    // Validate date ranges if both dates are being updated
    const newStartDate = updateData.start_date !== undefined ? updateData.start_date : promotion.start_date;
    const newEndDate = updateData.end_date !== undefined ? updateData.end_date : promotion.end_date;

    if (newStartDate && newEndDate && newStartDate >= newEndDate) {
      return res.status(400).json({ error: 'Start date must be before end date' });
    }

    // Validate total calculation if subtotal or discount changed
    if (updateData.subtotal !== undefined || updateData.discount !== undefined) {
      const newSubtotal = updateData.subtotal !== undefined ? parseFloat(updateData.subtotal) : parseFloat(promotion.subtotal);
      const newDiscount = updateData.discount !== undefined ? parseFloat(updateData.discount) : parseFloat(promotion.discount);
      const newTotal = updateData.total !== undefined ? parseFloat(updateData.total) : parseFloat(promotion.total);

      const calculatedTotal = newSubtotal - newDiscount;
      if (Math.abs(newTotal - calculatedTotal) > 0.01) {
        return res.status(400).json({ error: 'Total must equal subtotal minus discount' });
      }
    }

    await promotion.update(updateData);

    // Fetch updated promotion with associations
    const updatedPromotion = await Promotion.findByPk(promotion.id, {
      include: [
        {
          model: Listing,
          as: 'listing',
          attributes: ['id', 'title', 'sell_price', 'rent_price', 'availability'],
        },
        {
          model: Coupon,
          as: 'coupon',
          attributes: ['id', 'code', 'type', 'value', 'use_case'],
        },
        {
          model: PromotionPack,
          as: 'promotionPack',
          attributes: ['id', 'name_en', 'name_so', 'duration', 'price', 'availability'],
        },
      ],
    });

    res.json({
      message: 'Promotion updated successfully',
      promotion: updatedPromotion,
    });
  } catch (error) {
    console.error('Error updating promotion:', error);

    if (error.name === 'SequelizeValidationError') {
      return res.status(400).json({ error: error.errors[0].message });
    }

    res.status(500).json({ error: 'Internal server error' });
  }
};

// Delete promotion
const deletePromotion = async (req, res) => {
  try {
    const { id } = req.params;

    // Input validation
    const promotionId = parseInt(id);
    if (isNaN(promotionId) || promotionId < 1) {
      return res.status(400).json({ error: 'Invalid promotion ID' });
    }

    const promotion = await Promotion.findByPk(promotionId);
    if (!promotion) {
      return res.status(404).json({ error: 'Promotion not found' });
    }

    await promotion.destroy();

    res.json({ message: 'Promotion deleted successfully' });
  } catch (error) {
    console.error('Error deleting promotion:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

module.exports = {
  getPromotions,
  getPromotionById,
  createPromotion,
  updatePromotion,
  deletePromotion,
};
