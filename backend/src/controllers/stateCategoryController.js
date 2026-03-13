const { StateCategory } = require('../models');
const { Op } = require('sequelize');

// Get all state categories with pagination and filtering
const getStateCategories = async (req, res) => {
  try {
    const {
      page = 1,
      limit = 10,
      search,
      sortBy = 'createdAt',
      sortOrder = 'DESC'
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

    // Search functionality with sanitization
    if (search && typeof search === 'string' && search.trim().length > 0) {
      const sanitizedSearch = search.trim().replace(/[%_]/g, '\\$&'); // Escape SQL wildcards
      whereClause[Op.or] = [
        { name_en: { [Op.like]: `%${sanitizedSearch}%` } },
        { name_so: { [Op.like]: `%${sanitizedSearch}%` } }
      ];
    }

    // Validate sort order
    const validSortOrders = ['ASC', 'DESC'];
    const order = validSortOrders.includes(sortOrder.toUpperCase()) ? sortOrder.toUpperCase() : 'DESC';

    // Validate sort by fields
    const validSortFields = ['id', 'name_en', 'name_so', 'createdAt', 'updatedAt'];
    const sortField = validSortFields.includes(sortBy) ? sortBy : 'createdAt';

    const { count, rows: stateCategories } = await StateCategory.findAndCountAll({
      where: whereClause,
      limit: limitNum,
      offset: offset,
      order: [[sortField, order]],
    });

    const totalPages = Math.ceil(count / limitNum);

    res.json({
      data: stateCategories,
      pagination: {
        currentPage: pageNum,
        totalPages,
        totalItems: count,
        itemsPerPage: limitNum,
        hasNextPage: pageNum < totalPages,
        hasPrevPage: pageNum > 1
      }
    });
  } catch (error) {
    console.error('Error fetching state categories:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// Get single state category
const getStateCategoryById = async (req, res) => {
  try {
    const { id } = req.params;

    // Input validation
    const categoryId = parseInt(id);
    if (isNaN(categoryId) || categoryId < 1) {
      return res.status(400).json({ error: 'Invalid category ID' });
    }

    const stateCategory = await StateCategory.findByPk(categoryId);

    if (!stateCategory) {
      return res.status(404).json({ error: 'State category not found' });
    }

    res.json(stateCategory);
  } catch (error) {
    console.error('Error fetching state category:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// Create new state category
const createStateCategory = async (req, res) => {
  try {
    const { name_en, name_so, thumb_url } = req.body;

    // Input validation and sanitization
    if (!name_en || typeof name_en !== 'string' || name_en.trim().length < 1 || name_en.trim().length > 255) {
      return res.status(400).json({ error: 'name_en must be 1-255 characters' });
    }
    if (!name_so || typeof name_so !== 'string' || name_so.trim().length < 1 || name_so.trim().length > 255) {
      return res.status(400).json({ error: 'name_so must be 1-255 characters' });
    }

    const sanitizedNameEn = name_en.trim();
    const sanitizedNameSo = name_so.trim();

    let sanitizedThumbUrl = null;
    if (thumb_url) {
      if (typeof thumb_url !== 'string' || !/^https?:\/\/.+/.test(thumb_url.trim())) {
        return res.status(400).json({ error: 'Invalid thumb_url format' });
      }
      sanitizedThumbUrl = thumb_url.trim();
    }

    const stateCategory = await StateCategory.create({
      name_en: sanitizedNameEn,
      name_so: sanitizedNameSo,
      thumb_url: sanitizedThumbUrl
    });

    res.status(201).json(stateCategory);
  } catch (error) {
    console.error('Error creating state category:', error);
    if (error.name === 'SequelizeValidationError') {
      return res.status(400).json({ error: 'Validation error', details: error.errors });
    }
    if (error.name === 'SequelizeUniqueConstraintError') {
      return res.status(409).json({ error: 'State category with this name already exists' });
    }
    res.status(500).json({ error: 'Internal server error' });
  }
};

// Update state category
const updateStateCategory = async (req, res) => {
  try {
    const { id } = req.params;

    // Input validation
    const categoryId = parseInt(id);
    if (isNaN(categoryId) || categoryId < 1) {
      return res.status(400).json({ error: 'Invalid category ID' });
    }

    const { name_en, name_so, thumb_url } = req.body;

    const stateCategory = await StateCategory.findByPk(categoryId);

    if (!stateCategory) {
      return res.status(404).json({ error: 'State category not found' });
    }

    // Input validation and sanitization for updates
    const updateData = {};

    if (name_en !== undefined) {
      if (typeof name_en !== 'string' || name_en.trim().length < 1 || name_en.trim().length > 255) {
        return res.status(400).json({ error: 'name_en must be 1-255 characters' });
      }
      updateData.name_en = name_en.trim();
    }

    if (name_so !== undefined) {
      if (typeof name_so !== 'string' || name_so.trim().length < 1 || name_so.trim().length > 255) {
        return res.status(400).json({ error: 'name_so must be 1-255 characters' });
      }
      updateData.name_so = name_so.trim();
    }

    if (thumb_url !== undefined) {
      if (thumb_url === null) {
        updateData.thumb_url = null;
      } else if (typeof thumb_url === 'string') {
        if (!/^https?:\/\/.+/.test(thumb_url.trim())) {
          return res.status(400).json({ error: 'Invalid thumb_url format' });
        }
        updateData.thumb_url = thumb_url.trim();
      } else {
        return res.status(400).json({ error: 'Invalid thumb_url type' });
      }
    }

    await stateCategory.update(updateData);

    res.json(stateCategory);
  } catch (error) {
    console.error('Error updating state category:', error);
    if (error.name === 'SequelizeValidationError') {
      return res.status(400).json({ error: 'Validation error', details: error.errors });
    }
    if (error.name === 'SequelizeUniqueConstraintError') {
      return res.status(409).json({ error: 'State category with this name already exists' });
    }
    res.status(500).json({ error: 'Internal server error' });
  }
};

// Delete state category
const deleteStateCategory = async (req, res) => {
  try {
    const { id } = req.params;

    // Input validation
    const categoryId = parseInt(id);
    if (isNaN(categoryId) || categoryId < 1) {
      return res.status(400).json({ error: 'Invalid category ID' });
    }

    const stateCategory = await StateCategory.findByPk(categoryId);

    if (!stateCategory) {
      return res.status(404).json({ error: 'State category not found' });
    }

    await stateCategory.destroy();
    res.status(204).send();
  } catch (error) {
    console.error('Error deleting state category:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

module.exports = {
  getStateCategories,
  getStateCategoryById,
  createStateCategory,
  updateStateCategory,
  deleteStateCategory,
};
