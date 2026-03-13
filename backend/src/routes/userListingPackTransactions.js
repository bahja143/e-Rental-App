const express = require('express');
const { authenticateToken } = require('../middleware/authMiddleware');
const {
  getUserListingPackTransactions,
  getUserListingPackTransactionById,
  createUserListingPackTransaction,
  updateUserListingPackTransaction,
  deleteUserListingPackTransaction,
} = require('../controllers/userListingPackTransactionController');

const router = express.Router();

// GET /api/user-listing-pack-transactions - Get all transactions with pagination, filtering, and sorting
router.get('/', authenticateToken, getUserListingPackTransactions);

// GET /api/user-listing-pack-transactions/:id - Get single transaction
router.get('/:id(\\d+)', authenticateToken, getUserListingPackTransactionById);

// POST /api/user-listing-pack-transactions - Create new transaction
router.post('/', authenticateToken, createUserListingPackTransaction);

// PUT /api/user-listing-pack-transactions/:id - Update transaction
router.put('/:id(\\d+)', authenticateToken, updateUserListingPackTransaction);

// DELETE /api/user-listing-pack-transactions/:id - Delete transaction
router.delete('/:id(\\d+)', authenticateToken, deleteUserListingPackTransaction);

module.exports = router;
