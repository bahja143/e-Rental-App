const express = require('express');
const { authenticateToken } = require('../middleware/authMiddleware');
const {
  getWithdrawBalances,
  getWithdrawBalanceById,
  createWithdrawBalance,
  updateWithdrawBalance,
  deleteWithdrawBalance,
} = require('../controllers/withdrawBalanceController');

const router = express.Router();

// GET /api/withdraw-balances - Get all withdraw balances with pagination, filtering, and user data
router.get('/', authenticateToken, getWithdrawBalances);

// GET /api/withdraw-balances/:id - Get single withdraw balance
router.get('/:id', authenticateToken, getWithdrawBalanceById);

// POST /api/withdraw-balances - Create new withdraw balance
router.post('/', authenticateToken, createWithdrawBalance);

// PUT /api/withdraw-balances/:id - Update withdraw balance
router.put('/:id', authenticateToken, updateWithdrawBalance);

// DELETE /api/withdraw-balances/:id - Delete withdraw balance
router.delete('/:id', authenticateToken, deleteWithdrawBalance);

module.exports = router;
