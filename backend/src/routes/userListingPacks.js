const express = require('express');
const { authenticateToken } = require('../middleware/authMiddleware');
const {
  getUserListingPacks,
  getUserListingPackById,
  createUserListingPack,
  updateUserListingPack,
  deleteUserListingPack,
} = require('../controllers/userListingPackController');

const router = express.Router();

// GET /api/user-listing-packs - Get all user listing packs
router.get('/', authenticateToken, getUserListingPacks);

// GET /api/user-listing-packs/:id - Get single user listing pack
router.get('/:id(\d+)', authenticateToken, getUserListingPackById);

// POST /api/user-listing-packs - Create new user listing pack
router.post('/', authenticateToken, createUserListingPack);

// PUT /api/user-listing-packs/:id - Update user listing pack
router.put('/:id(\d+)', authenticateToken, updateUserListingPack);

// DELETE /api/user-listing-packs/:id - Delete user listing pack
router.delete('/:id(\d+)', authenticateToken, deleteUserListingPack);

module.exports = router;
