const { RecentSearch, User, PropertyCategory } = require('../models');
const { Op } = require('sequelize');

// Validation helper
const validateRecentSearch = (data, isUpdate = false) => {
  const errors = [];

  if (!isUpdate || data.search_text !== undefined) {
    if (!data.search_text || typeof data.search_text !== 'string' || data.search_text.trim().length === 0 || data.search_text.length > 255) {
      errors.push('search_text must be a non-empty string with max 255 characters');
    }
  }

  if (!isUpdate || data.latitude !== undefined) {
    if (typeof data.latitude !== 'number' || data.latitude < -90 || data.latitude > 90) {
      errors.push('latitude must be a number between -90 and 90');
    }
  }

  if (!isUpdate || data.longitude !== undefined) {
    if (typeof data.longitude !== 'number' || data.longitude < -180 || data.longitude > 180) {
      errors.push('longitude must be a number between -180 and 180');
    }
  }

  if (data.radius !== undefined && (typeof data.radius !== 'number' || data.radius < 0)) {
    errors.push('radius must be a non-negative number');
  }

  if (data.user_id !== undefined && data.user_id !== null && (!Number.isInteger(data.user_id) || data.user_id <= 0)) {
    errors.push('user_id must be a positive integer or null');
  }

  if (data.category_id !== undefined && data.category_id !== null && (!Number.isInteger(data.category_id) || data.category_id <= 0)) {
    errors.push('category_id must be a positive integer or null');
  }

  if (data.device_id !== undefined && data.device_id !== null && typeof data.device_id !== 'string') {
    errors.push('device_id must be a string or null');
  }

  return errors;
};

// Create a new recent search
const createRecentSearch = async (req, res) => {
  try {
    const { user_id, device_id, search_text, category_id, latitude, longitude, radius = 0 } = req.body;

    const dataToValidate = { user_id, device_id, search_text, category_id, latitude, longitude, radius };
    const validationErrors = validateRecentSearch(dataToValidate);
    if (validationErrors.length > 0) {
      return res.status(400).json({ errors: validationErrors });
    }

    // Sanitize input
    const sanitizedData = {
      user_id: user_id || null,
      device_id: device_id || null,
      search_text: search_text.trim(),
      category_id: category_id || null,
      latitude,
      longitude,
      radius,
    };

    if (sanitizedData.device_id === '') {
      sanitizedData.device_id = null;
    }

    const recentSearch = await RecentSearch.create(sanitizedData);
    res.status(201).json(recentSearch);
  } catch (error) {
    console.error('Error creating recent search:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// Get recent searches with filters and pagination
const getRecentSearches = async (req, res) => {
  try {
    const {
      user_id,
      device_id,
      category_id,
      search_text,
      page = 1,
      limit = 10,
      sortBy = 'created_at',
      sortOrder = 'DESC',
    } = req.query;

    // Build where clause
    const where = {};
    if (user_id) where.user_id = user_id;
    if (device_id) where.device_id = device_id;
    if (category_id) where.category_id = category_id;
    if (search_text) {
      if (process.env.NODE_ENV === 'test') {
        where.search_text = { [Op.like]: `%${search_text}%` };
      } else {
        where.search_text = { [Op.iLike]: `%${search_text}%` };
      }
    }

    // Pagination
    const offset = (page - 1) * limit;
    const order = [[sortBy, sortOrder.toUpperCase()]];

    const { count, rows } = await RecentSearch.findAndCountAll({
      where,
      include: [
        {
          model: User,
          as: 'user',
          attributes: ['id', 'name', 'email'],
        },
        {
          model: PropertyCategory,
          as: 'category',
          attributes: ['id', 'name_en'],
        },
      ],
      limit: parseInt(limit),
      offset: parseInt(offset),
      order,
    });

    res.json({
      data: rows,
      pagination: {
        total: count,
        page: parseInt(page),
        limit: parseInt(limit),
        pages: Math.ceil(count / limit),
      },
    });
  } catch (error) {
    console.error('Error fetching recent searches:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// Get a single recent search by ID
const getRecentSearchById = async (req, res) => {
  try {
    const { id } = req.params;
    const recentSearch = await RecentSearch.findByPk(id, {
      include: [
        {
          model: User,
          as: 'user',
          attributes: ['id', 'name', 'email'],
        },
        {
          model: PropertyCategory,
          as: 'category',
          attributes: ['id', 'name_en'],
        },
      ],
    });

    if (!recentSearch) {
      return res.status(404).json({ error: 'Recent search not found' });
    }

    res.json(recentSearch);
  } catch (error) {
    console.error('Error fetching recent search:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// Update a recent search
const updateRecentSearch = async (req, res) => {
  try {
    const { id } = req.params;
    const { user_id, device_id, search_text, category_id, latitude, longitude, radius } = req.body;

    const recentSearch = await RecentSearch.findByPk(id);
    if (!recentSearch) {
      return res.status(404).json({ error: 'Recent search not found' });
    }

    // Validate input if provided
    const updateData = {};
    if (user_id !== undefined) updateData.user_id = user_id;
    if (device_id !== undefined) updateData.device_id = device_id;
    if (search_text !== undefined) updateData.search_text = search_text;
    if (category_id !== undefined) updateData.category_id = category_id;
    if (latitude !== undefined) updateData.latitude = latitude;
    if (longitude !== undefined) updateData.longitude = longitude;
    if (radius !== undefined) updateData.radius = radius;

    const validationErrors = validateRecentSearch(updateData, true);
    if (validationErrors.length > 0) {
      return res.status(400).json({ errors: validationErrors });
    }

    // Sanitize input
    if (updateData.search_text) updateData.search_text = updateData.search_text.trim();
    if (updateData.user_id === null || updateData.user_id === '') updateData.user_id = null;
    if (updateData.device_id === null || updateData.device_id === '') updateData.device_id = null;
    if (updateData.category_id === null || updateData.category_id === '') updateData.category_id = null;

    await recentSearch.update(updateData);
    res.json(recentSearch);
  } catch (error) {
    console.error('Error updating recent search:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// Delete a recent search
const deleteRecentSearch = async (req, res) => {
  try {
    const { id } = req.params;
    const recentSearch = await RecentSearch.findByPk(id);

    if (!recentSearch) {
      return res.status(404).json({ error: 'Recent search not found' });
    }

    await recentSearch.destroy();
    res.status(204).send();
  } catch (error) {
    console.error('Error deleting recent search:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

module.exports = {
  createRecentSearch,
  getRecentSearches,
  getRecentSearchById,
  updateRecentSearch,
  deleteRecentSearch,
};
