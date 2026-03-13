const { PromotionPack } = require('../models');

// Get all promotion packs
const getPromotionPacks = async (req, res) => {
  try {
    const {
      page = 1,
      limit = 10,
      search,
      duration,
      price_min,
      price_max,
      availability,
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
      whereClause[require('sequelize').Op.or] = [
        { name_en: { [require('sequelize').Op.like]: `%${sanitizedSearch}%` } },
        { name_so: { [require('sequelize').Op.like]: `%${sanitizedSearch}%` } },
      ];
    }

    // Duration filter with validation
    if (duration !== undefined) {
      const durationNum = parseInt(duration);
      if (!isNaN(durationNum) && durationNum > 0) {
        whereClause.duration = durationNum;
      }
    }

    // Price range filter with validation
    if (price_min !== undefined || price_max !== undefined) {
      whereClause.price = {};
      if (price_min !== undefined) {
        const minPrice = parseFloat(price_min);
        if (!isNaN(minPrice) && minPrice >= 0) {
          whereClause.price[require('sequelize').Op.gte] = minPrice;
        }
      }
      if (price_max !== undefined) {
        const maxPrice = parseFloat(price_max);
        if (!isNaN(maxPrice) && maxPrice >= 0) {
          whereClause.price[require('sequelize').Op.lte] = maxPrice;
        }
      }
    }

    // Availability filter with validation
    if (availability !== undefined) {
      const availNum = parseInt(availability);
      if (availNum === 0 || availNum === 1) {
        whereClause.availability = availNum;
      }
    }

    // Sorting with validation
    const validSortFields = ['id', 'name_en', 'name_so', 'duration', 'price', 'availability', 'createdAt', 'updatedAt'];
    const sortField = validSortFields.includes(sortBy) ? sortBy : 'createdAt';
    const sortDirection = sortOrder.toUpperCase() === 'ASC' ? 'ASC' : 'DESC';

    const { count, rows: promotionPacks } = await PromotionPack.findAndCountAll({
      where: whereClause,
      limit: limitNum,
      offset: offset,
      order: [[sortField, sortDirection]],
    });

    const totalPages = Math.ceil(count / limitNum);

    res.json({
      data: promotionPacks,
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
    console.error('Error fetching promotion packs:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// Get promotion pack by ID
const getPromotionPackById = async (req, res) => {
  try {
    const { id } = req.params;

    // Input validation
    const packId = parseInt(id);
    if (isNaN(packId) || packId < 1) {
      return res.status(400).json({ error: 'Invalid promotion pack ID' });
    }

    const promotionPack = await PromotionPack.findByPk(packId);

    if (!promotionPack) {
      return res.status(404).json({ error: 'Promotion pack not found' });
    }

    res.json(promotionPack);
  } catch (error) {
    console.error('Error fetching promotion pack:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// Create a new promotion pack
const createPromotionPack = async (req, res) => {
  try {
    const {
      name_en,
      name_so,
      duration,
      price,
      availability = 1,
    } = req.body;

    // Input validation and sanitization
    if (!name_en || typeof name_en !== 'string' || name_en.trim().length === 0 || name_en.trim().length > 255) {
      return res.status(400).json({ error: 'name_en must be 1-255 characters' });
    }
    if (!name_so || typeof name_so !== 'string' || name_so.trim().length === 0 || name_so.trim().length > 255) {
      return res.status(400).json({ error: 'name_so must be 1-255 characters' });
    }

    const durationNum = parseInt(duration);
    if (isNaN(durationNum) || durationNum < 1) {
      return res.status(400).json({ error: 'Duration must be a positive integer' });
    }

    const priceNum = parseFloat(price);
    if (isNaN(priceNum) || priceNum < 0) {
      return res.status(400).json({ error: 'Price must be a non-negative number' });
    }

    const availabilityNum = parseInt(availability);
    if (availabilityNum !== 0 && availabilityNum !== 1) {
      return res.status(400).json({ error: 'Availability must be 0 or 1' });
    }

    const sanitizedNameEn = name_en.trim();
    const sanitizedNameSo = name_so.trim();

    const promotionPack = await PromotionPack.create({
      name_en: sanitizedNameEn,
      name_so: sanitizedNameSo,
      duration: durationNum,
      price: parseFloat(priceNum.toFixed(2)),
      availability: availabilityNum,
    });

    res.status(201).json({
      message: 'Promotion pack created successfully',
      promotionPack: promotionPack.toJSON(),
    });
  } catch (error) {
    console.error('Error creating promotion pack:', error);

    if (error.name === 'SequelizeValidationError') {
      return res.status(400).json({ error: error.errors[0].message });
    }

    res.status(500).json({ error: 'Internal server error' });
  }
};

// Update promotion pack
const updatePromotionPack = async (req, res) => {
  try {
    const { id } = req.params;

    // Input validation
    const packId = parseInt(id);
    if (isNaN(packId) || packId < 1) {
      return res.status(400).json({ error: 'Invalid promotion pack ID' });
    }

    const {
      name_en,
      name_so,
      duration,
      price,
      availability,
    } = req.body;

    const promotionPack = await PromotionPack.findByPk(packId);
    if (!promotionPack) {
      return res.status(404).json({ error: 'Promotion pack not found' });
    }

    const updateData = {};

    // Sanitize and validate provided fields
    if (name_en !== undefined) {
      if (typeof name_en !== 'string' || name_en.trim().length === 0 || name_en.trim().length > 255) {
        return res.status(400).json({ error: 'name_en must be 1-255 characters' });
      }
      updateData.name_en = name_en.trim();
    }

    if (name_so !== undefined) {
      if (typeof name_so !== 'string' || name_so.trim().length === 0 || name_so.trim().length > 255) {
        return res.status(400).json({ error: 'name_so must be 1-255 characters' });
      }
      updateData.name_so = name_so.trim();
    }

    if (duration !== undefined) {
      const durationNum = parseInt(duration);
      if (isNaN(durationNum) || durationNum < 1) {
        return res.status(400).json({ error: 'Duration must be a positive integer' });
      }
      updateData.duration = durationNum;
    }

    if (price !== undefined) {
      const priceNum = parseFloat(price);
      if (isNaN(priceNum) || priceNum < 0) {
        return res.status(400).json({ error: 'Price must be a non-negative number' });
      }
      updateData.price = parseFloat(priceNum.toFixed(2));
    }

    if (availability !== undefined) {
      const availabilityNum = parseInt(availability);
      if (availabilityNum !== 0 && availabilityNum !== 1) {
        return res.status(400).json({ error: 'Availability must be 0 or 1' });
      }
      updateData.availability = availabilityNum;
    }

    await promotionPack.update(updateData);

    res.json({
      message: 'Promotion pack updated successfully',
      promotionPack: promotionPack.toJSON(),
    });
  } catch (error) {
    console.error('Error updating promotion pack:', error);

    if (error.name === 'SequelizeValidationError') {
      return res.status(400).json({ error: error.errors[0].message });
    }

    res.status(500).json({ error: 'Internal server error' });
  }
};

// Delete promotion pack
const deletePromotionPack = async (req, res) => {
  try {
    const { id } = req.params;

    // Input validation
    const packId = parseInt(id);
    if (isNaN(packId) || packId < 1) {
      return res.status(400).json({ error: 'Invalid promotion pack ID' });
    }

    const promotionPack = await PromotionPack.findByPk(packId);
    if (!promotionPack) {
      return res.status(404).json({ error: 'Promotion pack not found' });
    }

    await promotionPack.destroy();

    res.json({ message: 'Promotion pack deleted successfully' });
  } catch (error) {
    console.error('Error deleting promotion pack:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

module.exports = {
  getPromotionPacks,
  getPromotionPackById,
  createPromotionPack,
  updatePromotionPack,
  deletePromotionPack,
};
