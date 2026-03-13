const { Favourite, User, Listing } = require('../models');
const { Op } = require('sequelize');

// Get all favourites with pagination, filtering, and sorting
const getFavourites = async (req, res) => {
  try {
    const {
      page = 1,
      limit = 10,
      user_id,
      listing_id,
      sortBy = 'add_date',
      sortOrder = 'DESC',
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

    // Filter by user_id (non-admin can only see their own favourites)
    const currentUserId = req.user?.userId ?? req.user?.id;
    const isAdmin = req.user?.role === 'admin';
    if (user_id !== undefined) {
      const userIdNum = parseInt(user_id);
      if (isNaN(userIdNum) || userIdNum < 1) {
        return res.status(400).json({ error: 'Invalid user_id' });
      }
      if (!isAdmin && userIdNum !== currentUserId) {
        return res.status(403).json({ error: 'You can only view your own favourites' });
      }
      whereClause.user_id = userIdNum;
    } else if (!isAdmin && currentUserId) {
      whereClause.user_id = currentUserId;
    }

    // Filter by listing_id
    if (listing_id !== undefined) {
      const listingIdNum = parseInt(listing_id);
      if (isNaN(listingIdNum) || listingIdNum < 1) {
        return res.status(400).json({ error: 'Invalid listing_id' });
      }
      whereClause.listing_id = listingIdNum;
    }

    // Sorting with validation
    const validSortFields = ['user_id', 'listing_id', 'add_date', 'createdAt', 'updatedAt'];
    const sortField = validSortFields.includes(sortBy) ? sortBy : 'add_date';
    const sortDirection = sortOrder.toUpperCase() === 'ASC' ? 'ASC' : 'DESC';

    const { count, rows: favourites } = await Favourite.findAndCountAll({
      where: whereClause,
      limit: limitNum,
      offset: offset,
      order: [[sortField, sortDirection]],
      include: [
        {
          model: User,
          as: 'user',
          attributes: ['id', 'name', 'email'],
        },
        {
          model: Listing,
          as: 'listing',
          attributes: ['id', 'title', 'address'],
        },
      ],
    });

    const totalPages = Math.ceil(count / limitNum);

    res.json({
      data: favourites,
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
    console.error('Error fetching favourites:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// Get single favourite
const getFavouriteById = async (req, res) => {
  try {
    const { user_id, listing_id } = req.params;
    const currentUserId = req.user?.userId ?? req.user?.id;
    const isAdmin = req.user?.role === 'admin';

    const userIdNum = parseInt(user_id);
    const listingIdNum = parseInt(listing_id);

    if (isNaN(userIdNum) || userIdNum < 1) {
      return res.status(400).json({ error: 'Invalid user_id' });
    }
    if (isNaN(listingIdNum) || listingIdNum < 1) {
      return res.status(400).json({ error: 'Invalid listing_id' });
    }
    if (!isAdmin && userIdNum !== currentUserId) {
      return res.status(403).json({ error: 'You can only view your own favourites' });
    }

    const favourite = await Favourite.findOne({
      where: { user_id: userIdNum, listing_id: listingIdNum },
      include: [
        {
          model: User,
          as: 'user',
          attributes: ['id', 'name', 'email'],
        },
        {
          model: Listing,
          as: 'listing',
          attributes: ['id', 'title', 'address'],
        },
      ],
    });

    if (!favourite) {
      return res.status(404).json({ error: 'Favourite not found' });
    }

    res.json(favourite);
  } catch (error) {
    console.error('Error fetching favourite:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// Create favourite (user_id from auth; only listing_id required in body)
const createFavourite = async (req, res) => {
  try {
    const userIdNum = req.user?.userId ?? req.user?.id;
    if (!userIdNum) {
      return res.status(401).json({ error: 'Authentication required' });
    }

    const { listing_id, add_date } = req.body;

    const listingIdNum = parseInt(listing_id);
    if (isNaN(listingIdNum) || listingIdNum < 1) {
      return res.status(400).json({ error: 'Valid listing_id is required' });
    }

    // Check if user exists
    const user = await User.findByPk(userIdNum);
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    // Check if listing exists
    const listing = await Listing.findByPk(listingIdNum);
    if (!listing) {
      return res.status(404).json({ error: 'Listing not found' });
    }

    // Check if favourite already exists
    const existingFavourite = await Favourite.findOne({
      where: { user_id: userIdNum, listing_id: listingIdNum },
    });

    if (existingFavourite) {
      return res.status(409).json({ error: 'Favourite already exists' });
    }

    // Validate add_date if provided
    let addDate = new Date();
    if (add_date) {
      const parsedDate = new Date(add_date);
      if (isNaN(parsedDate.getTime())) {
        return res.status(400).json({ error: 'Invalid add_date format' });
      }
      addDate = parsedDate;
    }

    const favourite = await Favourite.create({
      user_id: userIdNum,
      listing_id: listingIdNum,
      add_date: addDate,
    });

    // Fetch with associations
    const createdFavourite = await Favourite.findOne({
      where: { user_id: userIdNum, listing_id: listingIdNum },
      include: [
        {
          model: User,
          as: 'user',
          attributes: ['id', 'name', 'email'],
        },
        {
          model: Listing,
          as: 'listing',
          attributes: ['id', 'title', 'address'],
        },
      ],
    });

    res.status(201).json({
      message: 'Favourite created successfully',
      favourite: createdFavourite,
    });
  } catch (error) {
    console.error('Error creating favourite:', error);

    if (error.name === 'SequelizeValidationError') {
      return res.status(400).json({ error: error.errors[0].message });
    }

    res.status(500).json({ error: 'Internal server error' });
  }
};

// Update favourite (mainly for add_date; must be own favourite)
const updateFavourite = async (req, res) => {
  try {
    const { user_id, listing_id } = req.params;
    const { add_date } = req.body;
    const currentUserId = req.user?.userId ?? req.user?.id;
    const isAdmin = req.user?.role === 'admin';

    const userIdNum = parseInt(user_id);
    const listingIdNum = parseInt(listing_id);

    if (isNaN(userIdNum) || userIdNum < 1) {
      return res.status(400).json({ error: 'Invalid user_id' });
    }
    if (isNaN(listingIdNum) || listingIdNum < 1) {
      return res.status(400).json({ error: 'Invalid listing_id' });
    }
    if (!isAdmin && userIdNum !== currentUserId) {
      return res.status(403).json({ error: 'You can only update your own favourites' });
    }

    const favourite = await Favourite.findOne({
      where: { user_id: userIdNum, listing_id: listingIdNum },
    });

    if (!favourite) {
      return res.status(404).json({ error: 'Favourite not found' });
    }

    const updateData = {};

    // Validate add_date if provided
    if (add_date !== undefined) {
      const parsedDate = new Date(add_date);
      if (isNaN(parsedDate.getTime())) {
        return res.status(400).json({ error: 'Invalid add_date format' });
      }
      updateData.add_date = parsedDate;
    }

    if (Object.keys(updateData).length === 0) {
      return res.status(400).json({ error: 'No valid fields to update' });
    }

    await favourite.update(updateData);

    // Fetch updated favourite with associations
    const updatedFavourite = await Favourite.findOne({
      where: { user_id: userIdNum, listing_id: listingIdNum },
      include: [
        {
          model: User,
          as: 'user',
          attributes: ['id', 'name', 'email'],
        },
        {
          model: Listing,
          as: 'listing',
          attributes: ['id', 'title', 'address'],
        },
      ],
    });

    res.json({
      message: 'Favourite updated successfully',
      favourite: updatedFavourite,
    });
  } catch (error) {
    console.error('Error updating favourite:', error);

    if (error.name === 'SequelizeValidationError') {
      return res.status(400).json({ error: error.errors[0].message });
    }

    res.status(500).json({ error: 'Internal server error' });
  }
};

// Delete favourite (must be own favourite)
const deleteFavourite = async (req, res) => {
  try {
    const { user_id, listing_id } = req.params;
    const currentUserId = req.user?.userId ?? req.user?.id;
    const isAdmin = req.user?.role === 'admin';

    const userIdNum = parseInt(user_id);
    const listingIdNum = parseInt(listing_id);

    if (isNaN(userIdNum) || userIdNum < 1) {
      return res.status(400).json({ error: 'Invalid user_id' });
    }
    if (isNaN(listingIdNum) || listingIdNum < 1) {
      return res.status(400).json({ error: 'Invalid listing_id' });
    }
    if (!isAdmin && userIdNum !== currentUserId) {
      return res.status(403).json({ error: 'You can only delete your own favourites' });
    }

    const favourite = await Favourite.findOne({
      where: { user_id: userIdNum, listing_id: listingIdNum },
    });

    if (!favourite) {
      return res.status(404).json({ error: 'Favourite not found' });
    }

    await favourite.destroy();

    res.json({ message: 'Favourite deleted successfully' });
  } catch (error) {
    console.error('Error deleting favourite:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

module.exports = {
  getFavourites,
  getFavouriteById,
  createFavourite,
  updateFavourite,
  deleteFavourite,
};
