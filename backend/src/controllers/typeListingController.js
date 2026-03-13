const { TypeListing, Listing, ListingType } = require('../models');
const { Op } = require('sequelize');

// Get all type listings with pagination, filtering, sorting
const getTypeListings = async (req, res) => {
  try {
    const {
      page = 1,
      limit = 10,
      sortBy = 'createdAt',
      sortOrder = 'DESC',
      listing_id,
      listing_type_id
    } = req.query;

    const offset = (page - 1) * limit;
    const where = {};

    // Apply filters
    if (listing_id) {
      where.listing_id = listing_id;
    }
    if (listing_type_id) {
      where.listing_type_id = listing_type_id;
    }

    const typeListings = await TypeListing.findAndCountAll({
      where,
      limit: parseInt(limit),
      offset: parseInt(offset),
      order: [[sortBy, sortOrder.toUpperCase()]],
      include: [{
        model: Listing,
        as: 'listing',
        attributes: ['id', 'title', 'user_id']
      }, {
        model: ListingType,
        as: 'listingType',
        attributes: ['id', 'name_en', 'name_so']
      }],
    });

    res.json({
      data: typeListings.rows,
      pagination: {
        total: typeListings.count,
        page: parseInt(page),
        limit: parseInt(limit),
        totalPages: Math.ceil(typeListings.count / limit),
      },
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Get type listing by ID
const getTypeListingById = async (req, res) => {
  try {
    const typeListing = await TypeListing.findByPk(req.params.id, {
      include: [{
        model: Listing,
        as: 'listing',
        attributes: ['id', 'title', 'user_id']
      }, {
        model: ListingType,
        as: 'listingType',
        attributes: ['id', 'name_en', 'name_so']
      }],
    });
    if (!typeListing) {
      return res.status(404).json({ error: 'Type listing not found' });
    }
    res.json(typeListing);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Create a new type listing
const createTypeListing = async (req, res) => {
  try {
    const { listing_id, listing_type_id } = req.body;

    // Sanitize inputs
    const sanitizedListingId = parseInt(listing_id);
    const sanitizedListingTypeId = parseInt(listing_type_id);

    // Validate required fields
    if (!sanitizedListingId || !sanitizedListingTypeId) {
      return res.status(400).json({ error: 'listing_id and listing_type_id are required' });
    }

    // Validate that listing exists
    const listing = await Listing.findByPk(sanitizedListingId);
    if (!listing) {
      return res.status(400).json({ error: 'Invalid listing_id - listing does not exist' });
    }

    // Validate that listing type exists
    const listingType = await ListingType.findByPk(sanitizedListingTypeId);
    if (!listingType) {
      return res.status(400).json({ error: 'Invalid listing_type_id - listing type does not exist' });
    }

    const typeListing = await TypeListing.create({
      listing_id: sanitizedListingId,
      listing_type_id: sanitizedListingTypeId,
    });
    res.status(201).json(typeListing);
  } catch (error) {
    if (error.name === 'SequelizeUniqueConstraintError') {
      res.status(400).json({ error: 'This listing already has this type associated' });
    } else {
      res.status(400).json({ error: error.message });
    }
  }
};

// Update type listing
const updateTypeListing = async (req, res) => {
  try {
    const { listing_id, listing_type_id } = req.body;

    // Sanitize inputs
    const sanitizedListingId = listing_id ? parseInt(listing_id) : undefined;
    const sanitizedListingTypeId = listing_type_id ? parseInt(listing_type_id) : undefined;

    // Validate that listing exists if provided
    if (sanitizedListingId) {
      const listing = await Listing.findByPk(sanitizedListingId);
      if (!listing) {
        return res.status(400).json({ error: 'Invalid listing_id - listing does not exist' });
      }
    }

    // Validate that listing type exists if provided
    if (sanitizedListingTypeId) {
      const listingType = await ListingType.findByPk(sanitizedListingTypeId);
      if (!listingType) {
        return res.status(400).json({ error: 'Invalid listing_type_id - listing type does not exist' });
      }
    }

    const updateData = {};
    if (sanitizedListingId !== undefined) updateData.listing_id = sanitizedListingId;
    if (sanitizedListingTypeId !== undefined) updateData.listing_type_id = sanitizedListingTypeId;

    const [updated] = await TypeListing.update(updateData, {
      where: { id: req.params.id }
    });
    if (!updated) {
      return res.status(404).json({ error: 'Type listing not found' });
    }
    const updatedTypeListing = await TypeListing.findByPk(req.params.id, {
      include: [{
        model: Listing,
        as: 'listing',
        attributes: ['id', 'title', 'user_id']
      }, {
        model: ListingType,
        as: 'listingType',
        attributes: ['id', 'name_en', 'name_so']
      }],
    });
    res.json(updatedTypeListing);
  } catch (error) {
    if (error.name === 'SequelizeUniqueConstraintError') {
      res.status(400).json({ error: 'This listing already has this type associated' });
    } else {
      res.status(400).json({ error: error.message });
    }
  }
};

// Delete type listing
const deleteTypeListing = async (req, res) => {
  try {
    const deleted = await TypeListing.destroy({
      where: { id: req.params.id }
    });
    if (!deleted) {
      return res.status(404).json({ error: 'Type listing not found' });
    }
    res.status(204).send();
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

module.exports = {
  getTypeListings,
  getTypeListingById,
  createTypeListing,
  updateTypeListing,
  deleteTypeListing,
};
