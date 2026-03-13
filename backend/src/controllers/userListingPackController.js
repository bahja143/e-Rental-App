const { UserListingPack, User, ListingPack } = require('../models');
const { Op } = require('sequelize');

// Get all user listing packs with pagination, filtering, sorting
const getUserListingPacks = async (req, res) => {
  try {
    const {
      page = 1,
      limit = 10,
      sortBy = 'createdAt',
      sortOrder = 'DESC',
      user_id,
      listing_pack_id,
      status,
    } = req.query;

    const offset = (page - 1) * limit;
    const where = {};

    if (user_id) {
      where.user_id = user_id;
    }
    if (listing_pack_id) {
      where.listing_pack_id = listing_pack_id;
    }
    if (status) {
      where.status = status;
    }

    const include = [
      {
        model: User,
        as: 'user',
        attributes: ['id', 'name', 'email'],
      },
      {
        model: ListingPack,
        as: 'listingPack',
      },
      {
        model: ListingPack,
        as: 'upgradedFrom',
      },
      {
        model: ListingPack,
        as: 'downgradedTo',
      },
    ];

    const userListingPacks = await UserListingPack.findAndCountAll({
      where,
      limit: parseInt(limit),
      offset: parseInt(offset),
      order: [[sortBy, sortOrder.toUpperCase()]],
      include,
    });

    res.json({
      data: userListingPacks.rows,
      pagination: {
        total: userListingPacks.count,
        page: parseInt(page),
        limit: parseInt(limit),
        totalPages: Math.ceil(userListingPacks.count / limit),
      },
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Get user listing pack by ID
const getUserListingPackById = async (req, res) => {
  try {
    const include = [
        {
          model: User,
          as: 'user',
          attributes: ['id', 'name', 'email'],
        },
        {
          model: ListingPack,
          as: 'listingPack',
        },
        {
            model: ListingPack,
            as: 'upgradedFrom',
        },
        {
            model: ListingPack,
            as: 'downgradedTo',
        },
      ];

    const userListingPack = await UserListingPack.findByPk(req.params.id, {
      include,
    });
    if (!userListingPack) {
      return res.status(404).json({ error: 'User listing pack not found' });
    }
    res.json(userListingPack);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Create a new user listing pack
const createUserListingPack = async (req, res) => {
  try {
    const {
      user_id,
      listing_pack_id,
      start,
      end,
      status,
      total_paid,
      remain_balance,
      upgrade_from_pack_id,
      downgrade_to_pack_id,
      date,
    } = req.body;

    // Basic validation
    if (!user_id || !listing_pack_id || !start || !end || !status || !total_paid) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    const userListingPack = await UserListingPack.create({
      user_id,
      listing_pack_id,
      start,
      end,
      status,
      total_paid,
      remain_balance,
      upgrade_from_pack_id,
      downgrade_to_pack_id,
      date,
    });
    res.status(201).json(userListingPack);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

// Update user listing pack
const updateUserListingPack = async (req, res) => {
  try {
    const [updated] = await UserListingPack.update(req.body, {
      where: { id: req.params.id },
    });
    if (!updated) {
      return res.status(404).json({ error: 'User listing pack not found' });
    }
    const updatedUserListingPack = await UserListingPack.findByPk(req.params.id);
    res.json(updatedUserListingPack);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

// Delete user listing pack
const deleteUserListingPack = async (req, res) => {
  try {
    const deleted = await UserListingPack.destroy({
      where: { id: req.params.id },
    });
    if (!deleted) {
      return res.status(404).json({ error: 'User listing pack not found' });
    }
    res.status(204).send();
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

module.exports = {
  getUserListingPacks,
  getUserListingPackById,
  createUserListingPack,
  updateUserListingPack,
  deleteUserListingPack,
};
