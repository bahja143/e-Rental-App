const { Language } = require('../models');
const { Op } = require('sequelize');

// Get all languages with pagination and filtering
const getLanguages = async (req, res) => {
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

    // Search filter with sanitization
    if (search && typeof search === 'string' && search.trim().length > 0) {
      const sanitizedSearch = search.trim().replace(/[%_]/g, '\\$&'); // Escape SQL wildcards
      whereClause[Op.or] = [
        { key: { [Op.like]: `%${sanitizedSearch}%` } },
        { en: { [Op.like]: `%${sanitizedSearch}%` } },
        { so: { [Op.like]: `%${sanitizedSearch}%` } }
      ];
    }

    // Sorting with validation
    const validSortFields = ['id', 'key', 'en', 'so', 'createdAt', 'updatedAt'];
    const sortField = validSortFields.includes(sortBy) ? sortBy : 'createdAt';
    const validSortOrders = ['ASC', 'DESC'];
    const order = validSortOrders.includes(sortOrder.toUpperCase()) ? sortOrder.toUpperCase() : 'DESC';

    const { count, rows: languages } = await Language.findAndCountAll({
      where: whereClause,
      limit: limitNum,
      offset: offset,
      order: [[sortField, order]],
    });

    const totalPages = Math.ceil(count / limitNum);

    res.json({
      data: languages,
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
    console.error('Error fetching languages:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// Get language by ID
const getLanguageById = async (req, res) => {
  try {
    const { id } = req.params;

    // Input validation
    const languageId = parseInt(id);
    if (isNaN(languageId) || languageId < 1) {
      return res.status(400).json({ error: 'Invalid language ID' });
    }

    const language = await Language.findByPk(languageId);
    if (!language) {
      return res.status(404).json({ error: 'Language not found' });
    }

    res.json(language);
  } catch (error) {
    console.error('Error fetching language:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// Create a new language
const createLanguage = async (req, res) => {
  try {
    const { key, en, so } = req.body;

    // Input validation and sanitization
    if (!key || typeof key !== 'string' || key.trim().length < 1 || key.trim().length > 255) {
      return res.status(400).json({ error: 'key must be 1-255 characters' });
    }
    if (!en || typeof en !== 'string' || en.trim().length < 1) {
      return res.status(400).json({ error: 'en must be a non-empty string' });
    }
    if (!so || typeof so !== 'string' || so.trim().length < 1) {
      return res.status(400).json({ error: 'so must be a non-empty string' });
    }

    const language = await Language.create({
      key: key.trim(),
      en: en.trim(),
      so: so.trim(),
    });

    res.status(201).json({
      message: 'Language created successfully',
      data: language,
    });
  } catch (error) {
    console.error('Error creating language:', error);

    if (error.name === 'SequelizeUniqueConstraintError') {
      return res.status(409).json({ error: 'Language key already exists' });
    }

    if (error.name === 'SequelizeValidationError') {
      return res.status(400).json({ error: error.errors[0].message });
    }

    res.status(500).json({ error: 'Internal server error' });
  }
};

// Update language
const updateLanguage = async (req, res) => {
  try {
    const { id } = req.params;
    const { key, en, so } = req.body;

    // Input validation
    const languageId = parseInt(id);
    if (isNaN(languageId) || languageId < 1) {
      return res.status(400).json({ error: 'Invalid language ID' });
    }

    const language = await Language.findByPk(languageId);
    if (!language) {
      return res.status(404).json({ error: 'Language not found' });
    }

    const updateData = {};

    // Validate and sanitize key
    if (key !== undefined) {
      if (typeof key !== 'string' || key.trim().length < 1 || key.trim().length > 255) {
        return res.status(400).json({ error: 'key must be 1-255 characters' });
      }
      updateData.key = key.trim();
    }

    // Validate and sanitize en
    if (en !== undefined) {
      if (typeof en !== 'string' || en.trim().length < 1) {
        return res.status(400).json({ error: 'en must be a non-empty string' });
      }
      updateData.en = en.trim();
    }

    // Validate and sanitize so
    if (so !== undefined) {
      if (typeof so !== 'string' || so.trim().length < 1) {
        return res.status(400).json({ error: 'so must be a non-empty string' });
      }
      updateData.so = so.trim();
    }

    await language.update(updateData);

    res.json({
      message: 'Language updated successfully',
      data: language,
    });
  } catch (error) {
    console.error('Error updating language:', error);

    if (error.name === 'SequelizeUniqueConstraintError') {
      return res.status(409).json({ error: 'Language key already exists' });
    }

    if (error.name === 'SequelizeValidationError') {
      return res.status(400).json({ error: error.errors[0].message });
    }

    res.status(500).json({ error: 'Internal server error' });
  }
};

// Delete language
const deleteLanguage = async (req, res) => {
  try {
    const { id } = req.params;

    // Input validation
    const languageId = parseInt(id);
    if (isNaN(languageId) || languageId < 1) {
      return res.status(400).json({ error: 'Invalid language ID' });
    }

    const language = await Language.findByPk(languageId);
    if (!language) {
      return res.status(404).json({ error: 'Language not found' });
    }

    await language.destroy();

    res.json({ message: 'Language deleted successfully' });
  } catch (error) {
    console.error('Error deleting language:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

module.exports = {
  getLanguages,
  getLanguageById,
  createLanguage,
  updateLanguage,
  deleteLanguage,
};
