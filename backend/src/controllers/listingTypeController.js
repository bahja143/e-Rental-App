const { ListingType } = require('../models');

// Get all listing types with pagination, filtering, sorting
const getListingTypes = async (req, res) => {
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
      where[require('sequelize').Op.or] = [
        { name_en: { [require('sequelize').Op.like]: `%${searchTerm}%` } },
        { name_so: { [require('sequelize').Op.like]: `%${searchTerm}%` } }
      ];
    } else {
      // Only apply individual filters if no general search is provided
      if (name_en) {
        where.name_en = { [require('sequelize').Op.like]: `%${name_en}%` };
      }
      if (name_so) {
        where.name_so = { [require('sequelize').Op.like]: `%${name_so}%` };
      }
    }

    const listingTypes = await ListingType.findAndCountAll({
      where,
      limit: parseInt(limit),
      offset: parseInt(offset),
      order: [[sortBy, sortOrder.toUpperCase()]],
    });

    res.json({
      data: listingTypes.rows,
      pagination: {
        total: listingTypes.count,
        page: parseInt(page),
        limit: parseInt(limit),
        totalPages: Math.ceil(listingTypes.count / limit),
      },
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Get listing type by ID
const getListingTypeById = async (req, res) => {
  try {
    const listingType = await ListingType.findByPk(req.params.id);
    if (!listingType) {
      return res.status(404).json({ error: 'Listing type not found' });
    }
    res.json(listingType);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Create a new listing type
const createListingType = async (req, res) => {
  try {
    const { name_en, name_so } = req.body;

    // Validate required fields
    if (!name_en || !name_so) {
      return res.status(400).json({ error: 'name_en and name_so are required' });
    }

    const listingType = await ListingType.create(req.body);
    res.status(201).json(listingType);
  } catch (error) {
    if (error.name === 'SequelizeUniqueConstraintError') {
      res.status(400).json({ error: 'Listing type with this name_en already exists' });
    } else {
      res.status(400).json({ error: error.message });
    }
  }
};

// Update listing type
const updateListingType = async (req, res) => {
  try {
    const { name_en, name_so } = req.body;

    // Validate required fields
    if (!name_en || !name_so) {
      return res.status(400).json({ error: 'name_en and name_so are required' });
    }

    const [updated] = await ListingType.update(req.body, {
      where: { id: req.params.id }
    });
    if (!updated) {
      return res.status(404).json({ error: 'Listing type not found' });
    }
    const updatedListingType = await ListingType.findByPk(req.params.id);
    res.json(updatedListingType);
  } catch (error) {
    if (error.name === 'SequelizeUniqueConstraintError') {
      res.status(400).json({ error: 'Listing type with this name_en already exists' });
    } else {
      res.status(400).json({ error: error.message });
    }
  }
};

// Delete listing type
const deleteListingType = async (req, res) => {
  try {
    const deleted = await ListingType.destroy({
      where: { id: req.params.id }
    });
    if (!deleted) {
      return res.status(404).json({ error: 'Listing type not found' });
    }
    res.status(204).send();
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

module.exports = {
  getListingTypes,
  getListingTypeById,
  createListingType,
  updateListingType,
  deleteListingType,
};
