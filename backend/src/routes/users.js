const express = require('express');
const { authenticateToken } = require('../middleware/authMiddleware');
const {
  getUsers,
  getUserById,
  createUser,
  updateUser,
  deleteUser,
} = require('../controllers/userController');

const router = express.Router();

// GET /api/users - Get all users with pagination, filtering, and sorting
router.get('/', authenticateToken, getUsers);

// GET /api/users/:id - Get single user
router.get('/:id', authenticateToken, getUserById);

// POST /api/users - Create new user
router.post('/', createUser);

// PUT /api/users/:id - Update user
router.put('/:id', authenticateToken, updateUser);

// DELETE /api/users/:id - Delete user
router.delete('/:id', authenticateToken, deleteUser);

module.exports = router;
