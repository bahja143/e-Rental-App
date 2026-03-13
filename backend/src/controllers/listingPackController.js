const { ListingPack } = require('../models');
const { Op } = require('sequelize');

// Get all listing packs
const getListingPacks = async (req, res) => {
  try {
    const {
      page = 1,
      limit = 10,
      search,
      duration,
      price_min,
      price_max,
      listing_amount,
      display,
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
      whereClause[Op.or] = [
        { name_en: { [Op.like]: `%${sanitizedSearch}%` } },
        { name_so: { [Op.like]: `%${sanitizedSearch}%` } },
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
        const minPrice = parseInt(price_min);
        if (!isNaN(minPrice) && minPrice >= 0) {
          whereClause.price[Op.gte] = minPrice;
        }
      }
      if (price_max !== undefined) {
        const maxPrice = parseInt(price_max);
        if (!isNaN(maxPrice) && maxPrice >= 0) {
          whereClause.price[Op.lte] = maxPrice;
        }
      }
    }

    // Listing amount filter with validation
    if (listing_amount !== undefined) {
      const amountNum = parseInt(listing_amount);
      if (!isNaN(amountNum) && amountNum >= 0) {
        whereClause.listing_amount = amountNum;
      }
    }

    // Display filter with validation
    if (display !== undefined) {
      const displayNum = parseInt(display);
      if (displayNum === 0 || displayNum === 1) {
        whereClause.display = displayNum;
      }
    }

    // Sorting with validation
    const validSortFields = ['id', 'name_en', 'name_so', 'duration', 'price', 'listing_amount', 'display', 'createdAt', 'updatedAt'];
    const sortField = validSortFields.includes(sortBy) ? sortBy : 'createdAt';
    const sortDirection = sortOrder.toUpperCase() === 'ASC' ? 'ASC' : 'DESC';

    const { count, rows: listingPacks } = await ListingPack.findAndCountAll({
      where: whereClause,
      limit: limitNum,
      offset: offset,
      order: [[sortField, sortDirection]],
    });

    const totalPages = Math.ceil(count / limitNum);

    res.json({
      data: listingPacks,
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
    console.error('Error fetching listing packs:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// Get listing pack by ID
const getListingPackById = async (req, res) => {
  try {
    const { id } = req.params;

    // Input validation
    const packId = parseInt(id);
    if (isNaN(packId) || packId < 1) {
      return res.status(400).json({ error: 'Invalid listing pack ID' });
    }

    const listingPack = await ListingPack.findByPk(packId);

    if (!listingPack) {
      return res.status(404).json({ error: 'Listing pack not found' });
    }

    res.json(listingPack);
  } catch (error) {
    console.error('Error fetching listing pack:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// Create a new listing pack
const createListingPack = async (req, res) => {
  try {
    const {
      name_en,
      name_so,
      price,
      duration,
      features = {},
      listing_amount,
      display = 1,
    } = req.body;

    // Input validation and sanitization
    if (!name_en || typeof name_en !== 'string' || name_en.trim().length === 0 || name_en.trim().length > 255) {
      return res.status(400).json({ error: 'name_en must be 1-255 characters' });
    }
    if (!name_so || typeof name_so !== 'string' || name_so.trim().length === 0 || name_so.trim().length > 255) {
      return res.status(400).json({ error: 'name_so must be 1-255 characters' });
    }

    const priceNum = parseInt(price);
    if (isNaN(priceNum) || priceNum < 0) {
      return res.status(400).json({ error: 'Price must be a non-negative integer' });
    }

    const durationNum = parseInt(duration);
    if (isNaN(durationNum) || durationNum < 1) {
      return res.status(400).json({ error: 'Duration must be a positive integer' });
    }

    const listingAmountNum = parseInt(listing_amount);
    if (isNaN(listingAmountNum) || listingAmountNum < 0) {
      return res.status(400).json({ error: 'Listing amount must be a non-negative integer' });
    }

    const displayNum = parseInt(display);
    if (displayNum !== 0 && displayNum !== 1) {
      return res.status(400).json({ error: 'Display must be 0 or 1' });
    }

    // Validate features is an object
    if (features && typeof features !== 'object') {
      return res.status(400).json({ error: 'Features must be a valid JSON object' });
    }

    const sanitizedNameEn = name_en.trim();
    const sanitizedNameSo = name_so.trim();

    const listingPack = await ListingPack.create({
      name_en: sanitizedNameEn,
      name_so: sanitizedNameSo,
      price: priceNum,
      duration: durationNum,
      features: features,
      listing_amount: listingAmountNum,
      display: displayNum,
    });

    res.status(201).json({
      message: 'Listing pack created successfully',
      listingPack: listingPack.toJSON(),
    });
  } catch (error) {
    console.error('Error creating listing pack:', error);

    if (error.name === 'SequelizeValidationError') {
      return res.status(400).json({ error: error.errors[0].message });
    }

    res.status(500).json({ error: 'Internal server error' });
  }
};

// Update listing pack
const updateListingPack = async (req, res) => {
  try {
    const { id } = req.params;

    // Input validation
    const packId = parseInt(id);
    if (isNaN(packId) || packId < 1) {
      return res.status(400).json({ error: 'Invalid listing pack ID' });
    }

    const {
      name_en,
      name_so,
      price,
      duration,
      features,
      listing_amount,
      display,
    } = req.body;

    const listingPack = await ListingPack.findByPk(packId);
    if (!listingPack) {
      return res.status(404).json({ error: 'Listing pack not found' });
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

    if (price !== undefined) {
      const priceNum = parseInt(price);
      if (isNaN(priceNum) || priceNum < 0) {
        return res.status(400).json({ error: 'Price must be a non-negative integer' });
      }
      updateData.price = priceNum;
    }

    if (duration !== undefined) {
      const durationNum = parseInt(duration);
      if (isNaN(durationNum) || durationNum < 1) {
        return res.status(400).json({ error: 'Duration must be a positive integer' });
      }
      updateData.duration = durationNum;
    }

    if (features !== undefined) {
      if (features && typeof features !== 'object') {
        return res.status(400).json({ error: 'Features must be a valid JSON object' });
      }
      updateData.features = features;
    }

    if (listing_amount !== undefined) {
      const listingAmountNum = parseInt(listing_amount);
      if (isNaN(listingAmountNum) || listingAmountNum < 0) {
        return res.status(400).json({ error: 'Listing amount must be a non-negative integer' });
      }
      updateData.listing_amount = listingAmountNum;
    }

    if (display !== undefined) {
      const displayNum = parseInt(display);
      if (displayNum !== 0 && displayNum !== 1) {
        return res.status(400).json({ error: 'Display must be 0 or 1' });
      }
      updateData.display = displayNum;
    }

    await listingPack.update(updateData);

    res.json({
      message: 'Listing pack updated successfully',
      listingPack: listingPack.toJSON(),
    });
  } catch (error) {
    console.error('Error updating listing pack:', error);

    if (error.name === 'SequelizeValidationError') {
      return res.status(400).json({ error: error.errors[0].message });
    }

    res.status(500).json({ error: 'Internal server error' });
  }
};

// Delete listing pack
const deleteListingPack = async (req, res) => {
  try {
    const { id } = req.params;

    // Input validation
    const packId = parseInt(id);
    if (isNaN(packId) || packId < 1) {
      return res.status(400).json({ error: 'Invalid listing pack ID' });
    }

    const listingPack = await ListingPack.findByPk(packId);
    if (!listingPack) {
      return res.status(404).json({ error: 'Listing pack not found' });
    }

    await listingPack.destroy();

    res.json({ message: 'Listing pack deleted successfully' });
  } catch (error) {
    console.error('Error deleting listing pack:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

module.exports = {
  getListingPacks,
  getListingPackById,
  createListingPack,
  updateListingPack,
  deleteListingPack,
};
