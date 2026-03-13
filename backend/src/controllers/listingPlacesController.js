const { ListingPlace, Listing, NearbyPlace } = require('../models');
const { Op } = require('sequelize');

// Get all listing places with pagination, filtering, sorting
const getListingPlaces = async (req, res) => {
  try {
    const {
      page = 1,
      limit = 10,
      sortBy = 'createdAt',
      sortOrder = 'DESC',
      listing_id,
      nearby_place_id,
      value
    } = req.query;

    const offset = (page - 1) * limit;
    const where = {};

    // Handle general search parameter
    if (req.query.search) {
      const searchTerm = req.query.search;
      where[Op.or] = [
        { value: { [Op.like]: `%${searchTerm}%` } }
      ];
    } else {
      // Apply individual filters
      if (listing_id) {
        where.listing_id = listing_id;
      }
      if (nearby_place_id) {
        where.nearby_place_id = nearby_place_id;
      }
      if (value) {
        where.value = { [Op.like]: `%${value}%` };
      }
    }

    const include = [{
      model: Listing,
      as: 'listing',
      attributes: ['id', 'title', 'address']
    }, {
      model: NearbyPlace,
      as: 'nearbyPlace',
      attributes: ['id', 'name_en', 'name_so']
    }];

    const listingPlaces = await ListingPlace.findAndCountAll({
      where,
      limit: parseInt(limit),
      offset: parseInt(offset),
      order: [[sortBy, sortOrder.toUpperCase()]],
      include,
    });

    res.json({
      data: listingPlaces.rows,
      pagination: {
        total: listingPlaces.count,
        page: parseInt(page),
        limit: parseInt(limit),
        totalPages: Math.ceil(listingPlaces.count / limit),
      },
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Get listing place by ID
const getListingPlaceById = async (req, res) => {
  try {
    const listingPlace = await ListingPlace.findByPk(req.params.id, {
      include: [{
        model: Listing,
        as: 'listing',
        attributes: ['id', 'title', 'address']
      }, {
        model: NearbyPlace,
        as: 'nearbyPlace',
        attributes: ['id', 'name_en', 'name_so']
      }],
    });
    if (!listingPlace) {
      return res.status(404).json({ error: 'Listing place not found' });
    }
    res.json(listingPlace);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Create a new listing place
const createListingPlace = async (req, res) => {
  try {
    const { listing_id, nearby_place_id, value } = req.body;

    // Sanitize inputs
    const sanitizedValue = value?.trim();

    // Validate required fields
    if (!listing_id || !nearby_place_id || !sanitizedValue) {
      return res.status(400).json({ error: 'listing_id, nearby_place_id, and value are required' });
    }

    // Validate length
    if (sanitizedValue.length > 1000) {
      return res.status(400).json({ error: 'Value must be 1000 characters or less' });
    }

    // Check if listing exists
    const listing = await Listing.findByPk(listing_id);
    if (!listing) {
      return res.status(400).json({ error: 'Invalid listing_id - listing does not exist' });
    }

    // Check if nearby place exists
    const nearbyPlace = await NearbyPlace.findByPk(nearby_place_id);
    if (!nearbyPlace) {
      return res.status(400).json({ error: 'Invalid nearby_place_id - nearby place does not exist' });
    }

    const listingPlace = await ListingPlace.create({
      listing_id,
      nearby_place_id,
      value: sanitizedValue,
    });

    // Fetch with associations
    const createdPlace = await ListingPlace.findByPk(listingPlace.id, {
      include: [{
        model: Listing,
        as: 'listing',
        attributes: ['id', 'title', 'address']
      }, {
        model: NearbyPlace,
        as: 'nearbyPlace',
        attributes: ['id', 'name_en', 'name_so']
      }],
    });

    res.status(201).json(createdPlace);
  } catch (error) {
    if (error.name === 'SequelizeUniqueConstraintError') {
      res.status(400).json({ error: 'This nearby place is already assigned to this listing' });
    } else {
      res.status(400).json({ error: error.message });
    }
  }
};

// Update listing place
const updateListingPlace = async (req, res) => {
  try {
    const listingPlace = await ListingPlace.findByPk(req.params.id);
    if (!listingPlace) {
      return res.status(404).json({ error: 'Listing place not found' });
    }

    const { value } = req.body;

    // Sanitize inputs
    const sanitizedValue = value?.trim();

    // Validate required fields
    if (!sanitizedValue) {
      return res.status(400).json({ error: 'value is required' });
    }

    // Validate length
    if (sanitizedValue.length > 1000) {
      return res.status(400).json({ error: 'Value must be 1000 characters or less' });
    }

    await listingPlace.update({
      value: sanitizedValue,
    });

    // Fetch updated with associations
    const updatedPlace = await ListingPlace.findByPk(req.params.id, {
      include: [{
        model: Listing,
        as: 'listing',
        attributes: ['id', 'title', 'address']
      }, {
        model: NearbyPlace,
        as: 'nearbyPlace',
        attributes: ['id', 'name_en', 'name_so']
      }],
    });

    res.json(updatedPlace);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

// Delete listing place
const deleteListingPlace = async (req, res) => {
  try {
    const deleted = await ListingPlace.destroy({
      where: { id: req.params.id }
    });
    if (!deleted) {
      return res.status(404).json({ error: 'Listing place not found' });
    }
    res.status(204).send();
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

module.exports = {
  getListingPlaces,
  getListingPlaceById,
  createListingPlace,
  updateListingPlace,
  deleteListingPlace,
};
