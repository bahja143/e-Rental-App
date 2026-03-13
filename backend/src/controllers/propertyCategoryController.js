const { PropertyCategory } = require('../models');
const { Op } = require('sequelize');

// Get all property categories with pagination, filtering, sorting
const getPropertyCategories = async (req, res) => {
  try {
    const {
      page = 1,
      limit = 10,
      sortBy = 'createdAt',
      sortOrder = 'DESC',
      name_en,
      name_so
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
    }

    const propertyCategories = await PropertyCategory.findAndCountAll({
      where,
      limit: parseInt(limit),
      offset: parseInt(offset),
      order: [[sortBy, sortOrder.toUpperCase()]],
    });

    res.json({
      data: propertyCategories.rows,
      pagination: {
        total: propertyCategories.count,
        page: parseInt(page),
        limit: parseInt(limit),
        totalPages: Math.ceil(propertyCategories.count / limit),
      },
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Get property category by ID
const getPropertyCategoryById = async (req, res) => {
  try {
    const propertyCategory = await PropertyCategory.findByPk(req.params.id);
    if (!propertyCategory) {
      return res.status(404).json({ error: 'Property category not found' });
    }
    res.json(propertyCategory);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Create a new property category
const createPropertyCategory = async (req, res) => {
  try {
    const { name_en, name_so } = req.body;

    // Sanitize inputs
    const sanitizedNameEn = name_en?.trim();
    const sanitizedNameSo = name_so?.trim();

    // Validate required fields
    if (!sanitizedNameEn || !sanitizedNameSo) {
      return res.status(400).json({ error: 'name_en and name_so are required' });
    }

    // Validate length
    if (sanitizedNameEn.length > 255 || sanitizedNameSo.length > 255) {
      return res.status(400).json({ error: 'Name fields must be 255 characters or less' });
    }

    const propertyCategory = await PropertyCategory.create({
      name_en: sanitizedNameEn,
      name_so: sanitizedNameSo,
    });
    res.status(201).json(propertyCategory);
  } catch (error) {
    if (error.name === 'SequelizeUniqueConstraintError') {
      res.status(400).json({ error: 'Property category with this name_en already exists' });
    } else {
      res.status(400).json({ error: error.message });
    }
  }
};

// Update property category
const updatePropertyCategory = async (req, res) => {
  try {
    const { name_en, name_so } = req.body;

    // Sanitize inputs
    const sanitizedNameEn = name_en?.trim();
    const sanitizedNameSo = name_so?.trim();

    // Validate required fields
    if (!sanitizedNameEn || !sanitizedNameSo) {
      return res.status(400).json({ error: 'name_en and name_so are required' });
    }

    // Validate length
    if (sanitizedNameEn.length > 255 || sanitizedNameSo.length > 255) {
      return res.status(400).json({ error: 'Name fields must be 255 characters or less' });
    }

    const [updated] = await PropertyCategory.update({
      name_en: sanitizedNameEn,
      name_so: sanitizedNameSo,
    }, {
      where: { id: req.params.id }
    });
    if (!updated) {
      return res.status(404).json({ error: 'Property category not found' });
    }
    const updatedPropertyCategory = await PropertyCategory.findByPk(req.params.id);
    res.json(updatedPropertyCategory);
  } catch (error) {
    if (error.name === 'SequelizeUniqueConstraintError') {
      res.status(400).json({ error: 'Property category with this name_en already exists' });
    } else {
      res.status(400).json({ error: error.message });
    }
  }
};

// Delete property category
const deletePropertyCategory = async (req, res) => {
  try {
    const deleted = await PropertyCategory.destroy({
      where: { id: req.params.id }
    });
    if (!deleted) {
      return res.status(404).json({ error: 'Property category not found' });
    }
    res.status(204).send();
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

module.exports = {
  getPropertyCategories,
  getPropertyCategoryById,
  createPropertyCategory,
  updatePropertyCategory,
  deletePropertyCategory,
};
