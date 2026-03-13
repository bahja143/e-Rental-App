const { PropertyFeatures } = require('../models');
const { Op } = require('sequelize');

// Get all property features with pagination, filtering, sorting
const getPropertyFeatures = async (req, res) => {
  try {
    const {
      page = 1,
      limit = 10,
      sortBy = 'createdAt',
      sortOrder = 'DESC',
      name_en,
      name_so,
      type
    } = req.query;

    const offset = (page - 1) * limit;
    const where = {};

    // Handle general search parameter
    if (req.query.search) {
      const searchTerm = req.query.search;
      where[Op.or] = [
        { name_en: { [Op.like]: `%${searchTerm}%` } },
        { name_so: { [Op.like]: `%${searchTerm}%` } }
      ];
    } else {
      // Only apply individual filters if no general search is provided
      if (name_en) {
        where.name_en = { [Op.like]: `%${name_en}%` };
      }
      if (name_so) {
        where.name_so = { [Op.like]: `%${name_so}%` };
      }
      if (type) {
        where.type = type;
      }
    }

    const propertyFeatures = await PropertyFeatures.findAndCountAll({
      where,
      limit: parseInt(limit),
      offset: parseInt(offset),
      order: [[sortBy, sortOrder.toUpperCase()]],
    });

    res.json({
      data: propertyFeatures.rows,
      pagination: {
        total: propertyFeatures.count,
        page: parseInt(page),
        limit: parseInt(limit),
        totalPages: Math.ceil(propertyFeatures.count / limit),
      },
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Get property feature by ID
const getPropertyFeatureById = async (req, res) => {
  try {
    const propertyFeature = await PropertyFeatures.findByPk(req.params.id);
    if (!propertyFeature) {
      return res.status(404).json({ error: 'Property feature not found' });
    }
    res.json(propertyFeature);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Create a new property feature
const createPropertyFeature = async (req, res) => {
  try {
    const { name_en, name_so, type } = req.body;

    // Sanitize inputs
    const sanitizedNameEn = name_en?.trim();
    const sanitizedNameSo = name_so?.trim();
    const sanitizedType = type?.trim();

    // Validate required fields
    if (!sanitizedNameEn || !sanitizedNameSo) {
      return res.status(400).json({ error: 'name_en and name_so are required' });
    }

    // Validate type
    if (sanitizedType && !['number', 'string'].includes(sanitizedType)) {
      return res.status(400).json({ error: 'type must be either "number" or "string"' });
    }

    // Validate length
    if (sanitizedNameEn.length > 255 || sanitizedNameSo.length > 255) {
      return res.status(400).json({ error: 'Name fields must be 255 characters or less' });
    }

    const propertyFeature = await PropertyFeatures.create({
      name_en: sanitizedNameEn,
      name_so: sanitizedNameSo,
      type: sanitizedType || 'string',
    });
    res.status(201).json(propertyFeature);
  } catch (error) {
    if (error.name === 'SequelizeUniqueConstraintError') {
      res.status(400).json({ error: 'Property feature with this name_en already exists' });
    } else {
      res.status(400).json({ error: error.message });
    }
  }
};

// Update property feature
const updatePropertyFeature = async (req, res) => {
  try {
    const propertyFeature = await PropertyFeatures.findByPk(req.params.id);
    if (!propertyFeature) {
      return res.status(404).json({ error: 'Property feature not found' });
    }

    const { name_en, name_so, type } = req.body;

    // Sanitize inputs
    const sanitizedNameEn = name_en?.trim();
    const sanitizedNameSo = name_so?.trim();
    const sanitizedType = type?.trim();

    // Validate required fields
    if (!sanitizedNameEn || !sanitizedNameSo) {
      return res.status(400).json({ error: 'name_en and name_so are required' });
    }

    // Validate type
    if (sanitizedType && !['number', 'string'].includes(sanitizedType)) {
      return res.status(400).json({ error: 'type must be either "number" or "string"' });
    }

    // Validate length
    if (sanitizedNameEn.length > 255 || sanitizedNameSo.length > 255) {
      return res.status(400).json({ error: 'Name fields must be 255 characters or less' });
    }

    await propertyFeature.update({
      name_en: sanitizedNameEn,
      name_so: sanitizedNameSo,
      type: sanitizedType || 'string',
    });

    res.json(propertyFeature);
  } catch (error) {
    if (error.name === 'SequelizeUniqueConstraintError') {
      res.status(400).json({ error: 'Property feature with this name_en already exists' });
    } else {
      res.status(400).json({ error: error.message });
    }
  }
};

// Delete property feature
const deletePropertyFeature = async (req, res) => {
  try {
    const deleted = await PropertyFeatures.destroy({
      where: { id: req.params.id }
    });
    if (!deleted) {
      return res.status(404).json({ error: 'Property feature not found' });
    }
    res.status(204).send();
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

module.exports = {
  getPropertyFeatures,
  getPropertyFeatureById,
  createPropertyFeature,
  updatePropertyFeature,
  deletePropertyFeature,
};
