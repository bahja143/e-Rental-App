const express = require('express');
const { authenticateToken } = require('../middleware/authMiddleware');
const {
  getUserStateCategories,
  getUserStateCategoryById,
  createUserStateCategory,
  updateUserStateCategory,
  deleteUserStateCategory,
} = require('../controllers/userStateCategoryController');

const router = express.Router();

// GET /api/user-state-categories - Get all user state categories with pagination, filtering, and sorting
router.get('/', authenticateToken, getUserStateCategories);

// GET /api/user-state-categories/:id - Get single user state category
router.get('/:id', authenticateToken, getUserStateCategoryById);

// POST /api/user-state-categories - Create new user state category association
router.post('/', authenticateToken, createUserStateCategory);

// PUT /api/user-state-categories/:id - Update user state category association
router.put('/:id', authenticateToken, updateUserStateCategory);

// DELETE /api/user-state-categories/:id - Delete user state category association
router.delete('/:id', authenticateToken, deleteUserStateCategory);

module.exports = router;
