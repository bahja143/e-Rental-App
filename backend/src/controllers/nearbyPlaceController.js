const { NearbyPlace } = require('../models');
const { Op } = require('sequelize');

// Get all nearby places with pagination, filtering, sorting
const getNearbyPlaces = async (req, res) => {
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

    const nearbyPlaces = await NearbyPlace.findAndCountAll({
      where,
      limit: parseInt(limit),
      offset: parseInt(offset),
      order: [[sortBy, sortOrder.toUpperCase()]],
    });

    res.json({
      data: nearbyPlaces.rows,
      pagination: {
        total: nearbyPlaces.count,
        page: parseInt(page),
        limit: parseInt(limit),
        totalPages: Math.ceil(nearbyPlaces.count / limit),
      },
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Get nearby place by ID
const getNearbyPlaceById = async (req, res) => {
  try {
    const nearbyPlace = await NearbyPlace.findByPk(req.params.id);
    if (!nearbyPlace) {
      return res.status(404).json({ error: 'Nearby place not found' });
    }
    res.json(nearbyPlace);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Create a new nearby place
const createNearbyPlace = async (req, res) => {
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

    const nearbyPlace = await NearbyPlace.create({
      name_en: sanitizedNameEn,
      name_so: sanitizedNameSo,
    });
    res.status(201).json(nearbyPlace);
  } catch (error) {
    if (error.name === 'SequelizeUniqueConstraintError') {
      res.status(400).json({ error: 'Nearby place with this name_en already exists' });
    } else {
      res.status(400).json({ error: error.message });
    }
  }
};

// Update nearby place
const updateNearbyPlace = async (req, res) => {
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

    const [updated] = await NearbyPlace.update({
      name_en: sanitizedNameEn,
      name_so: sanitizedNameSo,
    }, {
      where: { id: req.params.id }
    });
    if (!updated) {
      return res.status(404).json({ error: 'Nearby place not found' });
    }
    const updatedNearbyPlace = await NearbyPlace.findByPk(req.params.id);
    res.json(updatedNearbyPlace);
  } catch (error) {
    if (error.name === 'SequelizeUniqueConstraintError') {
      res.status(400).json({ error: 'Nearby place with this name_en already exists' });
    } else {
      res.status(400).json({ error: error.message });
    }
  }
};

// Delete nearby place
const deleteNearbyPlace = async (req, res) => {
  try {
    const deleted = await NearbyPlace.destroy({
      where: { id: req.params.id }
    });
    if (!deleted) {
      return res.status(404).json({ error: 'Nearby place not found' });
    }
    res.status(204).send();
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

module.exports = {
  getNearbyPlaces,
  getNearbyPlaceById,
  createNearbyPlace,
  updateNearbyPlace,
  deleteNearbyPlace,
};
