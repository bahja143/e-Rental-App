const express = require('express');
const router = express.Router();
const userBankAccountController = require('../controllers/userBankAccountController');

// Routes

// GET /api/user-bank-accounts - Get all user bank accounts with pagination and filtering
router.get('/', userBankAccountController.getUserBankAccounts);

// GET /api/user-bank-accounts/:id - Get single user bank account by ID
router.get('/:id', userBankAccountController.getUserBankAccountById);

// POST /api/user-bank-accounts - Create new user bank account
router.post('/', userBankAccountController.createUserBankAccount);

// PUT /api/user-bank-accounts/:id - Update user bank account
router.put('/:id', userBankAccountController.updateUserBankAccount);

// DELETE /api/user-bank-accounts/:id - Delete user bank account
router.delete('/:id', userBankAccountController.deleteUserBankAccount);

module.exports = router;
