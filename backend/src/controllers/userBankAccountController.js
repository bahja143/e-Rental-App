const { UserBankAccount, User } = require('../models');
const { Op } = require('sequelize');

// Get all user bank accounts with pagination, filtering, and sorting
const getUserBankAccounts = async (req, res) => {
  try {
    const {
      page = 1,
      limit = 10,
      user_id,
      bank_name,
      account_holder_name,
      is_default,
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

    // Filter by bank_name with sanitization (escape SQL wildcards)
    if (bank_name) {
      const sanitizedBankName = bank_name.replace(/[%_]/g, '\\$&'); // Escape % and _
      whereClause.bank_name = { [Op.like]: `%${sanitizedBankName}%` };
    }

    // Filter by account_holder_name with sanitization
    if (account_holder_name) {
      const sanitizedHolderName = account_holder_name.replace(/[%_]/g, '\\$&');
      whereClause.account_holder_name = { [Op.like]: `%${sanitizedHolderName}%` };
    }

    // Filter by is_default
    if (is_default !== undefined) {
      const isDefaultBool = is_default === 'true';
      whereClause.is_default = isDefaultBool;
    }

    // Sorting with validation
    const validSortFields = ['id', 'user_id', 'bank_name', 'account_holder_name', 'is_default', 'createdAt', 'updatedAt'];
    const sortField = validSortFields.includes(sortBy) ? sortBy : 'createdAt';
    const sortDirection = sortOrder.toUpperCase() === 'ASC' ? 'ASC' : 'DESC';

    const { count, rows: userBankAccounts } = await UserBankAccount.findAndCountAll({
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
      ],
    });

    const totalPages = Math.ceil(count / limitNum);

    res.json({
      data: userBankAccounts,
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
    console.error('Error fetching user bank accounts:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// Get single user bank account by ID
const getUserBankAccountById = async (req, res) => {
  try {
    const { id } = req.params;

    // Input validation
    const accountId = parseInt(id);
    if (isNaN(accountId) || accountId < 1) {
      return res.status(400).json({ error: 'Invalid user bank account ID' });
    }

    const userBankAccount = await UserBankAccount.findByPk(accountId, {
      include: [
        {
          model: User,
          as: 'user',
          attributes: { exclude: ['password', 'two_factor_code', 'two_factor_expire'] },
        },
      ],
    });

    if (!userBankAccount) {
      return res.status(404).json({ error: 'User bank account not found' });
    }

    res.json(userBankAccount);
  } catch (error) {
    console.error('Error fetching user bank account:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// Create new user bank account
const createUserBankAccount = async (req, res) => {
  try {
    const { user_id, bank_name, branch, account_no, account_holder_name, swift_code, is_default = false } = req.body;

    // Input validation
    const userIdNum = parseInt(user_id);
    if (isNaN(userIdNum) || userIdNum < 1) {
      return res.status(400).json({ error: 'Valid user_id is required' });
    }

    // Validate required fields
    if (!bank_name || typeof bank_name !== 'string' || bank_name.trim().length < 2 || bank_name.length > 100) {
      return res.status(400).json({ error: 'Valid bank_name is required (2-100 characters)' });
    }

    if (!branch || typeof branch !== 'string' || branch.trim().length < 2 || branch.length > 100) {
      return res.status(400).json({ error: 'Valid branch is required (2-100 characters)' });
    }

    if (!account_no || typeof account_no !== 'string' || !/^[0-9\-]+$/.test(account_no) || account_no.length < 8 || account_no.length > 20) {
      return res.status(400).json({ error: 'Valid account_no is required (8-20 characters, numbers and hyphens only)' });
    }

    if (!account_holder_name || typeof account_holder_name !== 'string' || account_holder_name.trim().length < 2 || account_holder_name.length > 100) {
      return res.status(400).json({ error: 'Valid account_holder_name is required (2-100 characters)' });
    }

    // Validate SWIFT code if provided
    if (swift_code && (typeof swift_code !== 'string' || !/^[A-Z]{4}[A-Z]{2}[A-Z0-9]{2}([A-Z0-9]{3})?$/.test(swift_code))) {
      return res.status(400).json({ error: 'Invalid SWIFT code format' });
    }

    // Check if user exists
    const user = await User.findByPk(userIdNum);
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    // Check if account number already exists
    const existingAccount = await UserBankAccount.findOne({
      where: { account_no: account_no.trim() },
    });

    if (existingAccount) {
      return res.status(409).json({ error: 'Account number already exists' });
    }

    // If setting as default, unset other default accounts for this user
    if (is_default) {
      await UserBankAccount.update(
        { is_default: false },
        { where: { user_id: userIdNum, is_default: true } }
      );
    }

    const userBankAccount = await UserBankAccount.create({
      user_id: userIdNum,
      bank_name: bank_name.trim(),
      branch: branch.trim(),
      account_no: account_no.trim(),
      account_holder_name: account_holder_name.trim(),
      swift_code: swift_code ? swift_code.trim() : null,
      is_default: Boolean(is_default),
    });

    // Fetch the created account with user data
    const createdAccount = await UserBankAccount.findByPk(userBankAccount.id, {
      include: [
        {
          model: User,
          as: 'user',
          attributes: { exclude: ['password', 'two_factor_code', 'two_factor_expire'] },
        },
      ],
    });

    res.status(201).json({
      message: 'User bank account created successfully',
      data: createdAccount,
    });
  } catch (error) {
    console.error('Error creating user bank account:', error);

    if (error.name === 'SequelizeUniqueConstraintError') {
      return res.status(409).json({ error: 'Account number already exists' });
    }

    res.status(500).json({ error: 'Internal server error' });
  }
};

// Update user bank account
const updateUserBankAccount = async (req, res) => {
  try {
    const { id } = req.params;
    const { bank_name, branch, account_no, account_holder_name, swift_code, is_default } = req.body;

    // Input validation
    const accountId = parseInt(id);
    if (isNaN(accountId) || accountId < 1) {
      return res.status(400).json({ error: 'Invalid user bank account ID' });
    }

    const userBankAccount = await UserBankAccount.findByPk(accountId);
    if (!userBankAccount) {
      return res.status(404).json({ error: 'User bank account not found' });
    }

    const updateData = {};

    // Validate and update bank_name
    if (bank_name !== undefined) {
      if (typeof bank_name !== 'string' || bank_name.trim().length < 2 || bank_name.length > 100) {
        return res.status(400).json({ error: 'Invalid bank_name (2-100 characters)' });
      }
      updateData.bank_name = bank_name.trim();
    }

    // Validate and update branch
    if (branch !== undefined) {
      if (typeof branch !== 'string' || branch.trim().length < 2 || branch.length > 100) {
        return res.status(400).json({ error: 'Invalid branch (2-100 characters)' });
      }
      updateData.branch = branch.trim();
    }

    // Validate and update account_no
    if (account_no !== undefined) {
      if (typeof account_no !== 'string' || !/^[0-9\-]+$/.test(account_no) || account_no.length < 8 || account_no.length > 20) {
        return res.status(400).json({ error: 'Invalid account_no (8-20 characters, numbers and hyphens only)' });
      }

      // Check if the new account number already exists (excluding current record)
      const existingAccount = await UserBankAccount.findOne({
        where: {
          account_no: account_no.trim(),
          id: { [Op.ne]: accountId },
        },
      });

      if (existingAccount) {
        return res.status(409).json({ error: 'Account number already exists' });
      }

      updateData.account_no = account_no.trim();
    }

    // Validate and update account_holder_name
    if (account_holder_name !== undefined) {
      if (typeof account_holder_name !== 'string' || account_holder_name.trim().length < 2 || account_holder_name.length > 100) {
        return res.status(400).json({ error: 'Invalid account_holder_name (2-100 characters)' });
      }
      updateData.account_holder_name = account_holder_name.trim();
    }

    // Validate and update SWIFT code
    if (swift_code !== undefined) {
      if (swift_code && (typeof swift_code !== 'string' || !/^[A-Z]{4}[A-Z]{2}[A-Z0-9]{2}([A-Z0-9]{3})?$/.test(swift_code))) {
        return res.status(400).json({ error: 'Invalid SWIFT code format' });
      }
      updateData.swift_code = swift_code ? swift_code.trim() : null;
    }

    // Handle is_default update
    if (is_default !== undefined) {
      const isDefaultBool = Boolean(is_default);
      if (isDefaultBool && !userBankAccount.is_default) {
        // If setting as default, unset other default accounts for this user
        await UserBankAccount.update(
          { is_default: false },
          { where: { user_id: userBankAccount.user_id, is_default: true } }
        );
      }
      updateData.is_default = isDefaultBool;
    }

    // Check if there's anything to update
    if (Object.keys(updateData).length === 0) {
      return res.status(400).json({ error: 'No valid fields to update' });
    }

    await userBankAccount.update(updateData);

    // Fetch updated account with user data
    const updatedAccount = await UserBankAccount.findByPk(accountId, {
      include: [
        {
          model: User,
          as: 'user',
          attributes: { exclude: ['password', 'two_factor_code', 'two_factor_expire'] },
        },
      ],
    });

    res.json({
      message: 'User bank account updated successfully',
      data: updatedAccount,
    });
  } catch (error) {
    console.error('Error updating user bank account:', error);

    if (error.name === 'SequelizeUniqueConstraintError') {
      return res.status(409).json({ error: 'Account number already exists' });
    }

    res.status(500).json({ error: 'Internal server error' });
  }
};

// Delete user bank account
const deleteUserBankAccount = async (req, res) => {
  try {
    const { id } = req.params;

    // Input validation
    const accountId = parseInt(id);
    if (isNaN(accountId) || accountId < 1) {
      return res.status(400).json({ error: 'Invalid user bank account ID' });
    }

    const userBankAccount = await UserBankAccount.findByPk(accountId);
    if (!userBankAccount) {
      return res.status(404).json({ error: 'User bank account not found' });
    }

    await userBankAccount.destroy();

    res.json({ message: 'User bank account deleted successfully' });
  } catch (error) {
    console.error('Error deleting user bank account:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

module.exports = {
  getUserBankAccounts,
  getUserBankAccountById,
  createUserBankAccount,
  updateUserBankAccount,
  deleteUserBankAccount,
};
