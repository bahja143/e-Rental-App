const { UserStateCategory, User, StateCategory } = require('../models');
const { Op } = require('sequelize');

// Get all user state categories with pagination, filtering, and sorting
const getUserStateCategories = async (req, res) => {
  try {
    const {
      page = 1,
      limit = 10,
      user_id,
      state_categories_id,
      sortBy = 'createdAt',
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

    // Filter by user_id with validation
    if (user_id) {
      const userIdNum = parseInt(user_id);
      if (isNaN(userIdNum) || userIdNum < 1) {
        return res.status(400).json({ error: 'Invalid user_id' });
      }
      whereClause.user_id = userIdNum;
    }

    // Filter by state_categories_id with validation
    if (state_categories_id) {
      const stateCategoryIdNum = parseInt(state_categories_id);
      if (isNaN(stateCategoryIdNum) || stateCategoryIdNum < 1) {
        return res.status(400).json({ error: 'Invalid state_categories_id' });
      }
      whereClause.state_categories_id = stateCategoryIdNum;
    }

    // Sorting with validation
    const validSortFields = ['id', 'user_id', 'state_categories_id', 'createdAt', 'updatedAt'];
    const sortField = validSortFields.includes(sortBy) ? sortBy : 'createdAt';
    const sortDirection = sortOrder.toUpperCase() === 'ASC' ? 'ASC' : 'DESC';

    const { count, rows: userStateCategories } = await UserStateCategory.findAndCountAll({
      where: whereClause,
      limit: limitNum,
      offset: offset,
      order: [[sortField, sortDirection]],
      include: [
        {
          model: User,
          as: 'user',
          attributes: { exclude: ['password', 'two_factor_code', 'two_factor_expire'] },
        },
        {
          model: StateCategory,
          as: 'stateCategory',
        },
      ],
    });

    const totalPages = Math.ceil(count / limitNum);

    res.json({
      data: userStateCategories,
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
    console.error('Error fetching user state categories:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// Get single user state category by ID
const getUserStateCategoryById = async (req, res) => {
  try {
    const { id } = req.params;

    // Input validation
    const categoryId = parseInt(id);
    if (isNaN(categoryId) || categoryId < 1) {
      return res.status(400).json({ error: 'Invalid user state category ID' });
    }

    const userStateCategory = await UserStateCategory.findByPk(categoryId, {
      include: [
        {
          model: User,
          as: 'user',
          attributes: { exclude: ['password', 'two_factor_code', 'two_factor_expire'] },
        },
        {
          model: StateCategory,
          as: 'stateCategory',
        },
      ],
    });

    if (!userStateCategory) {
      return res.status(404).json({ error: 'User state category not found' });
    }

    res.json(userStateCategory);
  } catch (error) {
    console.error('Error fetching user state category:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// Create new user state category
const createUserStateCategory = async (req, res) => {
  try {
    const { user_id, state_categories_id } = req.body;

    // Input validation
    const userIdNum = parseInt(user_id);
    const stateCategoryIdNum = parseInt(state_categories_id);

    if (isNaN(userIdNum) || userIdNum < 1) {
      return res.status(400).json({ error: 'Valid user_id is required' });
    }
    if (isNaN(stateCategoryIdNum) || stateCategoryIdNum < 1) {
      return res.status(400).json({ error: 'Valid state_categories_id is required' });
    }

    // Check if user exists
    const user = await User.findByPk(userIdNum);
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    // Check if state category exists
    const stateCategory = await StateCategory.findByPk(stateCategoryIdNum);
    if (!stateCategory) {
      return res.status(404).json({ error: 'State category not found' });
    }

    // Check if association already exists
    const existingAssociation = await UserStateCategory.findOne({
      where: {
        user_id: userIdNum,
        state_categories_id: stateCategoryIdNum,
      },
    });

    if (existingAssociation) {
      return res.status(409).json({ error: 'User is already associated with this state category' });
    }

    const userStateCategory = await UserStateCategory.create({
      user_id: userIdNum,
      state_categories_id: stateCategoryIdNum,
    });

    // Fetch the created association with includes
    const createdAssociation = await UserStateCategory.findByPk(userStateCategory.id, {
      include: [
        {
          model: User,
          as: 'user',
          attributes: { exclude: ['password', 'two_factor_code', 'two_factor_expire'] },
        },
        {
          model: StateCategory,
          as: 'stateCategory',
        },
      ],
    });

    res.status(201).json({
      message: 'User state category association created successfully',
      data: createdAssociation,
    });
  } catch (error) {
    console.error('Error creating user state category:', error);

    if (error.name === 'SequelizeUniqueConstraintError') {
      return res.status(409).json({ error: 'User is already associated with this state category' });
    }

    res.status(500).json({ error: 'Internal server error' });
  }
};

// Update user state category (only allows changing the association)
const updateUserStateCategory = async (req, res) => {
  try {
    const { id } = req.params;
    const { user_id, state_categories_id } = req.body;

    // Input validation
    const categoryId = parseInt(id);
    if (isNaN(categoryId) || categoryId < 1) {
      return res.status(400).json({ error: 'Invalid user state category ID' });
    }

    const userStateCategory = await UserStateCategory.findByPk(categoryId);
    if (!userStateCategory) {
      return res.status(404).json({ error: 'User state category association not found' });
    }

    const updateData = {};

    // Validate and update user_id if provided
    if (user_id !== undefined) {
      const userIdNum = parseInt(user_id);
      if (isNaN(userIdNum) || userIdNum < 1) {
        return res.status(400).json({ error: 'Invalid user_id' });
      }

      // Check if user exists
      const user = await User.findByPk(userIdNum);
      if (!user) {
        return res.status(404).json({ error: 'User not found' });
      }

      updateData.user_id = userIdNum;
    }

    // Validate and update state_categories_id if provided
    if (state_categories_id !== undefined) {
      const stateCategoryIdNum = parseInt(state_categories_id);
      if (isNaN(stateCategoryIdNum) || stateCategoryIdNum < 1) {
        return res.status(400).json({ error: 'Invalid state_categories_id' });
      }

      // Check if state category exists
      const stateCategory = await StateCategory.findByPk(stateCategoryIdNum);
      if (!stateCategory) {
        return res.status(404).json({ error: 'State category not found' });
      }

      updateData.state_categories_id = stateCategoryIdNum;
    }

    // Check if the new association would create a duplicate
    if (updateData.user_id || updateData.state_categories_id) {
      const checkUserId = updateData.user_id || userStateCategory.user_id;
      const checkStateCategoryId = updateData.state_categories_id || userStateCategory.state_categories_id;

      const existingAssociation = await UserStateCategory.findOne({
        where: {
          user_id: checkUserId,
          state_categories_id: checkStateCategoryId,
          id: { [Op.ne]: categoryId }, // Exclude current record
        },
      });

      if (existingAssociation) {
        return res.status(409).json({ error: 'This association already exists' });
      }
    }

    await userStateCategory.update(updateData);

    // Fetch updated association with includes
    const updatedAssociation = await UserStateCategory.findByPk(categoryId, {
      include: [
        {
          model: User,
          as: 'user',
          attributes: { exclude: ['password', 'two_factor_code', 'two_factor_expire'] },
        },
        {
          model: StateCategory,
          as: 'stateCategory',
        },
      ],
    });

    res.json({
      message: 'User state category association updated successfully',
      data: updatedAssociation,
    });
  } catch (error) {
    console.error('Error updating user state category:', error);

    if (error.name === 'SequelizeUniqueConstraintError') {
      return res.status(409).json({ error: 'This association already exists' });
    }

    res.status(500).json({ error: 'Internal server error' });
  }
};

// Delete user state category
const deleteUserStateCategory = async (req, res) => {
  try {
    const { id } = req.params;

    // Input validation
    const categoryId = parseInt(id);
    if (isNaN(categoryId) || categoryId < 1) {
      return res.status(400).json({ error: 'Invalid user state category ID' });
    }

    const userStateCategory = await UserStateCategory.findByPk(categoryId);
    if (!userStateCategory) {
      return res.status(404).json({ error: 'User state category association not found' });
    }

    await userStateCategory.destroy();

    res.json({ message: 'User state category association deleted successfully' });
  } catch (error) {
    console.error('Error deleting user state category:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

module.exports = {
  getUserStateCategories,
  getUserStateCategoryById,
  createUserStateCategory,
  updateUserStateCategory,
  deleteUserStateCategory,
};
