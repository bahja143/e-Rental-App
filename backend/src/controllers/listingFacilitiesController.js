const { ListingFacility, Listing, Facility } = require('../models');
const { Op } = require('sequelize');

// Get all listing facilities with pagination, filtering, sorting
const getListingFacilities = async (req, res) => {
  try {
    const {
      page = 1,
      limit = 10,
      sortBy = 'createdAt',
      sortOrder = 'DESC',
      listing_id,
      facility_id,
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
      if (facility_id) {
        where.facility_id = facility_id;
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
      model: Facility,
      as: 'facility',
      attributes: ['id', 'name_en', 'name_so']
    }];

    const listingFacilities = await ListingFacility.findAndCountAll({
      where,
      limit: parseInt(limit),
      offset: parseInt(offset),
      order: [[sortBy, sortOrder.toUpperCase()]],
      include,
    });

    res.json({
      data: listingFacilities.rows,
      pagination: {
        total: listingFacilities.count,
        page: parseInt(page),
        limit: parseInt(limit),
        totalPages: Math.ceil(listingFacilities.count / limit),
      },
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Get listing facility by ID
const getListingFacilityById = async (req, res) => {
  try {
    const listingFacility = await ListingFacility.findByPk(req.params.id, {
      include: [{
        model: Listing,
        as: 'listing',
        attributes: ['id', 'title', 'address']
      }, {
        model: Facility,
        as: 'facility',
        attributes: ['id', 'name_en', 'name_so']
      }],
    });
    if (!listingFacility) {
      return res.status(404).json({ error: 'Listing facility not found' });
    }
    res.json(listingFacility);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Create a new listing facility
const createListingFacility = async (req, res) => {
  try {
    const { listing_id, facility_id, value } = req.body;

    // Sanitize inputs
    const sanitizedValue = value?.trim();

    // Validate required fields
    if (!listing_id || !facility_id || !sanitizedValue) {
      return res.status(400).json({ error: 'listing_id, facility_id, and value are required' });
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

    // Check if facility exists
    const facility = await Facility.findByPk(facility_id);
    if (!facility) {
      return res.status(400).json({ error: 'Invalid facility_id - facility does not exist' });
    }

    const listingFacility = await ListingFacility.create({
      listing_id,
      facility_id,
      value: sanitizedValue,
    });

    // Fetch with associations
    const createdFacility = await ListingFacility.findByPk(listingFacility.id, {
      include: [{
        model: Listing,
        as: 'listing',
        attributes: ['id', 'title', 'address']
      }, {
        model: Facility,
        as: 'facility',
        attributes: ['id', 'name_en', 'name_so']
      }],
    });

    res.status(201).json(createdFacility);
  } catch (error) {
    if (error.name === 'SequelizeUniqueConstraintError') {
      res.status(400).json({ error: 'This facility is already assigned to this listing' });
    } else {
      res.status(400).json({ error: error.message });
    }
  }
};

// Update listing facility
const updateListingFacility = async (req, res) => {
  try {
    const listingFacility = await ListingFacility.findByPk(req.params.id);
    if (!listingFacility) {
      return res.status(404).json({ error: 'Listing facility not found' });
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

    await listingFacility.update({
      value: sanitizedValue,
    });

    // Fetch updated with associations
    const updatedFacility = await ListingFacility.findByPk(req.params.id, {
      include: [{
        model: Listing,
        as: 'listing',
        attributes: ['id', 'title', 'address']
      }, {
        model: Facility,
        as: 'facility',
        attributes: ['id', 'name_en', 'name_so']
      }],
    });

    res.json(updatedFacility);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

// Delete listing facility
const deleteListingFacility = async (req, res) => {
  try {
    const deleted = await ListingFacility.destroy({
      where: { id: req.params.id }
    });
    if (!deleted) {
      return res.status(404).json({ error: 'Listing facility not found' });
    }
    res.status(204).send();
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

module.exports = {
  getListingFacilities,
  getListingFacilityById,
  createListingFacility,
  updateListingFacility,
  deleteListingFacility,
};
