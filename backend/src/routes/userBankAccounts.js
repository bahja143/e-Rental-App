const express = require('express');
const router = express.Router();
const { authenticateToken } = require('../middleware/authMiddleware');
const userBankAccountController = require('../controllers/userBankAccountController');

// Routes

// GET /api/user-bank-accounts - Get all user bank accounts with pagination and filtering
router.get('/', authenticateToken, userBankAccountController.getUserBankAccounts);

// GET /api/user-bank-accounts/:id - Get single user bank account by ID
router.get('/:id', authenticateToken, userBankAccountController.getUserBankAccountById);

// POST /api/user-bank-accounts - Create new user bank account
router.post('/', authenticateToken, userBankAccountController.createUserBankAccount);

// PUT /api/user-bank-accounts/:id - Update user bank account
router.put('/:id', authenticateToken, userBankAccountController.updateUserBankAccount);

// DELETE /api/user-bank-accounts/:id - Delete user bank account
router.delete('/:id', authenticateToken, userBankAccountController.deleteUserBankAccount);

module.exports = router;
