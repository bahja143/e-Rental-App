const { ListingNotificationsMap, Listing, User } = require('../models');
const { Op } = require('sequelize');

// Get all listing notifications maps with pagination, filtering, and sorting
const getListingNotificationsMaps = async (req, res) => {
  try {
    const {
      page = 1,
      limit = 10,
      sortBy = 'createdAt',
      sortOrder = 'DESC',
      listing_id,
      user_id,
      sent_at_from,
      sent_at_to,
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

    // Filter by listing_id
    if (listing_id) {
      const listingIdNum = parseInt(listing_id);
      if (isNaN(listingIdNum) || listingIdNum < 1) {
        return res.status(400).json({ error: 'Invalid listing_id' });
      }
      whereClause.listing_id = listingIdNum;
    }

    // Filter by user_id
    if (user_id) {
      const userIdNum = parseInt(user_id);
      if (isNaN(userIdNum) || userIdNum < 1) {
        return res.status(400).json({ error: 'Invalid user_id' });
      }
      whereClause.user_id = userIdNum;
    }

    // Filter by sent_at date range
    if (sent_at_from || sent_at_to) {
      whereClause.sent_at = {};
      if (sent_at_from) {
        const fromDate = new Date(sent_at_from);
        if (isNaN(fromDate.getTime())) {
          return res.status(400).json({ error: 'Invalid sent_at_from date' });
        }
        whereClause.sent_at[Op.gte] = fromDate;
      }
      if (sent_at_to) {
        const toDate = new Date(sent_at_to);
        if (isNaN(toDate.getTime())) {
          return res.status(400).json({ error: 'Invalid sent_at_to date' });
        }
        whereClause.sent_at[Op.lte] = toDate;
      }
    }

    // Sorting with validation
    const validSortFields = ['id', 'listing_id', 'user_id', 'sent_at', 'createdAt', 'updatedAt'];
    const sortField = validSortFields.includes(sortBy) ? sortBy : 'createdAt';
    const sortDirection = sortOrder.toUpperCase() === 'ASC' ? 'ASC' : 'DESC';

    const { count, rows: listingNotificationsMaps } = await ListingNotificationsMap.findAndCountAll({
      where: whereClause,
      limit: limitNum,
      offset: offset,
      order: [[sortField, sortDirection]],
      include: [
        {
          model: Listing,
          as: 'listing',
          attributes: ['id', 'title', 'address'],
        },
        {
          model: User,
          as: 'user',
          attributes: ['id', 'name', 'email'],
        },
      ],
    });

    const totalPages = Math.ceil(count / limitNum);

    res.json({
      data: listingNotificationsMaps,
      pagination: {
        currentPage: pageNum,
        totalPages,
        totalItems: count,
        itemsPerPage: limitNum,
        hasNextPage: pageNum < totalPages,
        hasPrevPage: pageNum > 1,
      },
    });
  } catch (error) {
    console.error('Error fetching listing notifications maps:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// Get single listing notifications map
const getListingNotificationsMapById = async (req, res) => {
  try {
    const { id } = req.params;

    // Input validation
    const mapId = parseInt(id);
    if (isNaN(mapId) || mapId < 1) {
      return res.status(400).json({ error: 'Invalid map ID' });
    }

    const listingNotificationsMap = await ListingNotificationsMap.findByPk(mapId, {
      include: [
        {
          model: Listing,
          as: 'listing',
          attributes: ['id', 'title', 'address'],
        },
        {
          model: User,
          as: 'user',
          attributes: ['id', 'name', 'email'],
        },
      ],
    });

    if (!listingNotificationsMap) {
      return res.status(404).json({ error: 'Listing notifications map not found' });
    }

    res.json(listingNotificationsMap);
  } catch (error) {
    console.error('Error fetching listing notifications map:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// Create new listing notifications map
const createListingNotificationsMap = async (req, res) => {
  try {
    const { listing_id, user_id, sent_at } = req.body;

    // Input validation
    if (!listing_id || !user_id) {
      return res.status(400).json({ error: 'listing_id and user_id are required' });
    }

    const listingIdNum = parseInt(listing_id);
    if (isNaN(listingIdNum) || listingIdNum < 1) {
      return res.status(400).json({ error: 'Invalid listing_id' });
    }

    const userIdNum = parseInt(user_id);
    if (isNaN(userIdNum) || userIdNum < 1) {
      return res.status(400).json({ error: 'Invalid user_id' });
    }

    let sentAtDate = new Date();
    if (sent_at) {
      sentAtDate = new Date(sent_at);
      if (isNaN(sentAtDate.getTime())) {
        return res.status(400).json({ error: 'Invalid sent_at date' });
      }
    }

    // Check if listing exists
    const listing = await Listing.findByPk(listingIdNum);
    if (!listing) {
      return res.status(404).json({ error: 'Listing not found' });
    }

    // Check if user exists
    const user = await User.findByPk(userIdNum);
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    const listingNotificationsMap = await ListingNotificationsMap.create({
      listing_id: listingIdNum,
      user_id: userIdNum,
      sent_at: sentAtDate,
    });

    // Fetch with related data
    const createdMap = await ListingNotificationsMap.findByPk(listingNotificationsMap.id, {
      include: [
        {
          model: Listing,
          as: 'listing',
          attributes: ['id', 'title', 'address'],
        },
        {
          model: User,
          as: 'user',
          attributes: ['id', 'name', 'email'],
        },
      ],
    });

    res.status(201).json({
      message: 'Listing notifications map created successfully',
      listingNotificationsMap: createdMap,
    });
  } catch (error) {
    console.error('Error creating listing notifications map:', error);

    if (error.name === 'SequelizeValidationError') {
      return res.status(400).json({ error: error.errors[0].message });
    }

    if (error.name === 'SequelizeUniqueConstraintError') {
      return res.status(409).json({ error: 'Notification mapping already exists for this listing and user' });
    }

    res.status(500).json({ error: 'Internal server error' });
  }
};

// Update listing notifications map
const updateListingNotificationsMap = async (req, res) => {
  try {
    const { id } = req.params;
    const { sent_at } = req.body;

    // Input validation
    const mapId = parseInt(id);
    if (isNaN(mapId) || mapId < 1) {
      return res.status(400).json({ error: 'Invalid map ID' });
    }

    const listingNotificationsMap = await ListingNotificationsMap.findByPk(mapId);
    if (!listingNotificationsMap) {
      return res.status(404).json({ error: 'Listing notifications map not found' });
    }

    const updateData = {};

    if (sent_at !== undefined) {
      const sentAtDate = new Date(sent_at);
      if (isNaN(sentAtDate.getTime())) {
        return res.status(400).json({ error: 'Invalid sent_at date' });
      }
      updateData.sent_at = sentAtDate;
    }

    if (Object.keys(updateData).length === 0) {
      return res.status(400).json({ error: 'No valid fields to update' });
    }

    await listingNotificationsMap.update(updateData);

    // Fetch updated map with related data
    const updatedMap = await ListingNotificationsMap.findByPk(mapId, {
      include: [
        {
          model: Listing,
          as: 'listing',
          attributes: ['id', 'title', 'address'],
        },
        {
          model: User,
          as: 'user',
          attributes: ['id', 'name', 'email'],
        },
      ],
    });

    res.json({
      message: 'Listing notifications map updated successfully',
      listingNotificationsMap: updatedMap,
    });
  } catch (error) {
    console.error('Error updating listing notifications map:', error);

    if (error.name === 'SequelizeValidationError') {
      return res.status(400).json({ error: error.errors[0].message });
    }

    res.status(500).json({ error: 'Internal server error' });
  }
};

// Delete listing notifications map
const deleteListingNotificationsMap = async (req, res) => {
  try {
    const { id } = req.params;

    // Input validation
    const mapId = parseInt(id);
    if (isNaN(mapId) || mapId < 1) {
      return res.status(400).json({ error: 'Invalid map ID' });
    }

    const listingNotificationsMap = await ListingNotificationsMap.findByPk(mapId);
    if (!listingNotificationsMap) {
      return res.status(404).json({ error: 'Listing notifications map not found' });
    }

    await listingNotificationsMap.destroy();

    res.json({ message: 'Listing notifications map deleted successfully' });
  } catch (error) {
    console.error('Error deleting listing notifications map:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

module.exports = {
  getListingNotificationsMaps,
  getListingNotificationsMapById,
  createListingNotificationsMap,
  updateListingNotificationsMap,
  deleteListingNotificationsMap,
};
