const { ListingFeature, Listing, PropertyFeatures } = require('../models');
const { Op } = require('sequelize');

// Get all listing features with pagination, filtering, sorting
const getListingFeatures = async (req, res) => {
  try {
    const {
      page = 1,
      limit = 10,
      sortBy = 'createdAt',
      sortOrder = 'DESC',
      listing_id,
      property_feature_id,
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
      if (property_feature_id) {
        where.property_feature_id = property_feature_id;
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
      model: PropertyFeatures,
      as: 'propertyFeature',
      attributes: ['id', 'name_en', 'name_so', 'type']
    }];

    const listingFeatures = await ListingFeature.findAndCountAll({
      where,
      limit: parseInt(limit),
      offset: parseInt(offset),
      order: [[sortBy, sortOrder.toUpperCase()]],
      include,
    });

    res.json({
      data: listingFeatures.rows,
      pagination: {
        total: listingFeatures.count,
        page: parseInt(page),
        limit: parseInt(limit),
        totalPages: Math.ceil(listingFeatures.count / limit),
      },
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Get listing feature by ID
const getListingFeatureById = async (req, res) => {
  try {
    const listingFeature = await ListingFeature.findByPk(req.params.id, {
      include: [{
        model: Listing,
        as: 'listing',
        attributes: ['id', 'title', 'address']
      }, {
        model: PropertyFeatures,
        as: 'propertyFeature',
        attributes: ['id', 'name_en', 'name_so', 'type']
      }],
    });
    if (!listingFeature) {
      return res.status(404).json({ error: 'Listing feature not found' });
    }
    res.json(listingFeature);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Create a new listing feature
const createListingFeature = async (req, res) => {
  try {
    const { listing_id, property_feature_id, value } = req.body;

    // Sanitize inputs
    const sanitizedValue = value?.trim();

    // Validate required fields
    if (!listing_id || !property_feature_id || !sanitizedValue) {
      return res.status(400).json({ error: 'listing_id, property_feature_id, and value are required' });
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

    // Check if property feature exists and validate value type
    const propertyFeature = await PropertyFeatures.findByPk(property_feature_id);
    if (!propertyFeature) {
      return res.status(400).json({ error: 'Invalid property_feature_id - property feature does not exist' });
    }

    // Validate value based on property feature type
    if (propertyFeature.type === 'number') {
      const numValue = parseFloat(sanitizedValue);
      if (isNaN(numValue)) {
        return res.status(400).json({ error: 'Value must be a valid number for this property feature' });
      }
    }

    const listingFeature = await ListingFeature.create({
      listing_id,
      property_feature_id,
      value: sanitizedValue,
    });

    // Fetch with associations
    const createdFeature = await ListingFeature.findByPk(listingFeature.id, {
      include: [{
        model: Listing,
        as: 'listing',
        attributes: ['id', 'title', 'address']
      }, {
        model: PropertyFeatures,
        as: 'propertyFeature',
        attributes: ['id', 'name_en', 'name_so', 'type']
      }],
    });

    res.status(201).json(createdFeature);
  } catch (error) {
    if (error.name === 'SequelizeUniqueConstraintError') {
      res.status(400).json({ error: 'This property feature is already assigned to this listing' });
    } else {
      res.status(400).json({ error: error.message });
    }
  }
};

// Update listing feature
const updateListingFeature = async (req, res) => {
  try {
    const listingFeature = await ListingFeature.findByPk(req.params.id);
    if (!listingFeature) {
      return res.status(404).json({ error: 'Listing feature not found' });
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

    // Get property feature to validate value type
    const propertyFeature = await PropertyFeatures.findByPk(listingFeature.property_feature_id);
    if (propertyFeature.type === 'number') {
      const numValue = parseFloat(sanitizedValue);
      if (isNaN(numValue)) {
        return res.status(400).json({ error: 'Value must be a valid number for this property feature' });
      }
    }

    await listingFeature.update({
      value: sanitizedValue,
    });

    // Fetch updated with associations
    const updatedFeature = await ListingFeature.findByPk(req.params.id, {
      include: [{
        model: Listing,
        as: 'listing',
        attributes: ['id', 'title', 'address']
      }, {
        model: PropertyFeatures,
        as: 'propertyFeature',
        attributes: ['id', 'name_en', 'name_so', 'type']
      }],
    });

    res.json(updatedFeature);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

// Delete listing feature
const deleteListingFeature = async (req, res) => {
  try {
    const deleted = await ListingFeature.destroy({
      where: { id: req.params.id }
    });
    if (!deleted) {
      return res.status(404).json({ error: 'Listing feature not found' });
    }
    res.status(204).send();
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

module.exports = {
  getListingFeatures,
  getListingFeatureById,
  createListingFeature,
  updateListingFeature,
  deleteListingFeature,
};
