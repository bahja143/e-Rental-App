const { WithdrawBalance, User } = require('../models');
const { Op } = require('sequelize');

// Get all withdraw balances with pagination, filtering, and user data
const getWithdrawBalances = async (req, res) => {
  try {
    const {
      page = 1,
      limit = 10,
      status,
      user_id,
      start_date,
      end_date,
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

    // Status filter with validation
    const validStatuses = ['requested', 'success', 'failed', 'cancelled'];
    if (status && validStatuses.includes(status)) {
      whereClause.status = status;
    }

    // User ID filter with validation
    if (user_id) {
      const userIdNum = parseInt(user_id);
      if (isNaN(userIdNum) || userIdNum < 1) {
        return res.status(400).json({ error: 'Invalid user ID' });
      }
      whereClause.user_id = userIdNum;
    }

    // Date range filter with validation
    if (start_date || end_date) {
      whereClause.date = {};
      if (start_date) {
        const startDate = new Date(start_date);
        if (isNaN(startDate.getTime())) {
          return res.status(400).json({ error: 'Invalid start_date format' });
        }
        whereClause.date[Op.gte] = startDate;
      }
      if (end_date) {
        const endDate = new Date(end_date);
        if (isNaN(endDate.getTime())) {
          return res.status(400).json({ error: 'Invalid end_date format' });
        }
        whereClause.date[Op.lte] = endDate;
      }
    }

    // Sorting with validation
    const validSortFields = ['id', 'amount', 'status', 'date', 'createdAt', 'updatedAt'];
    const sortField = validSortFields.includes(sortBy) ? sortBy : 'createdAt';
    const sortDirection = sortOrder.toUpperCase() === 'ASC' ? 'ASC' : 'DESC';

    const { count, rows: withdrawBalances } = await WithdrawBalance.findAndCountAll({
      where: whereClause,
      limit: limitNum,
      offset: offset,
      order: [[sortField, sortDirection]],
      include: [
        {
          model: User,
          as: 'user',
          attributes: ['id', 'name', 'email', 'available_balance', 'pending_balance'],
        },
      ],
    });

    const totalPages = Math.ceil(count / limitNum);

    res.json({
      data: withdrawBalances,
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
    console.error('Error fetching withdraw balances:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// Get single withdraw balance
const getWithdrawBalanceById = async (req, res) => {
  try {
    const { id } = req.params;

    // Input validation
    const withdrawId = parseInt(id);
    if (isNaN(withdrawId) || withdrawId < 1) {
      return res.status(400).json({ error: 'Invalid withdraw balance ID' });
    }

    const withdrawBalance = await WithdrawBalance.findByPk(withdrawId, {
      include: [
        {
          model: User,
          as: 'user',
          attributes: ['id', 'name', 'email', 'available_balance', 'pending_balance'],
        },
      ],
    });

    if (!withdrawBalance) {
      return res.status(404).json({ error: 'Withdraw balance not found' });
    }

    res.json(withdrawBalance);
  } catch (error) {
    console.error('Error fetching withdraw balance:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// Create new withdraw balance
const createWithdrawBalance = async (req, res) => {
  try {
    const {
      user_id,
      amount,
      status = 'requested',
      date,
      before_balance,
      after_balance,
      bank_name,
      branch,
      bank_account,
      account_holder_name,
      swift,
    } = req.body;

    // Input validation and sanitization
    const userIdNum = parseInt(user_id);
    if (isNaN(userIdNum) || userIdNum < 1) {
      return res.status(400).json({ error: 'Valid user ID is required' });
    }

    const amountFloat = parseFloat(amount);
    if (isNaN(amountFloat) || amountFloat <= 0) {
      return res.status(400).json({ error: 'Amount must be a positive number' });
    }

    // Validate status enum
    const validStatuses = ['requested', 'success', 'failed', 'cancelled'];
    if (!validStatuses.includes(status)) {
      return res.status(400).json({ error: 'Invalid status value' });
    }

    // Validate date if provided
    let validatedDate = new Date();
    if (date) {
      const dateObj = new Date(date);
      if (isNaN(dateObj.getTime())) {
        return res.status(400).json({ error: 'Invalid date format' });
      }
      validatedDate = dateObj;
    }

    // Validate balance values
    const beforeBal = parseFloat(before_balance);
    const afterBal = parseFloat(after_balance);
    if (isNaN(beforeBal) || beforeBal < 0) {
      return res.status(400).json({ error: 'Invalid before_balance (must be non-negative number)' });
    }
    if (isNaN(afterBal) || afterBal < 0) {
      return res.status(400).json({ error: 'Invalid after_balance (must be non-negative number)' });
    }

    // Check if user exists
    const user = await User.findByPk(userIdNum);
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    // Sanitize optional string fields
    const sanitizedBankName = bank_name ? bank_name.toString().trim().substring(0, 255) : null;
    const sanitizedBranch = branch ? branch.toString().trim().substring(0, 255) : null;
    const sanitizedBankAccount = bank_account ? bank_account.toString().trim().substring(0, 255) : null;
    const sanitizedAccountHolder = account_holder_name ? account_holder_name.toString().trim().substring(0, 255) : null;
    const sanitizedSwift = swift ? swift.toString().trim().substring(0, 50) : null;

    const withdrawData = {
      user_id: userIdNum,
      amount: amountFloat,
      status,
      date: validatedDate,
      before_balance: beforeBal,
      after_balance: afterBal,
      bank_name: sanitizedBankName,
      branch: sanitizedBranch,
      bank_account: sanitizedBankAccount,
      account_holder_name: sanitizedAccountHolder,
      swift: sanitizedSwift,
    };

    const withdrawBalance = await WithdrawBalance.create(withdrawData);

    // Fetch with user data
    const createdWithdraw = await WithdrawBalance.findByPk(withdrawBalance.id, {
      include: [
        {
          model: User,
          as: 'user',
          attributes: ['id', 'name', 'email', 'available_balance', 'pending_balance'],
        },
      ],
    });

    res.status(201).json({
      message: 'Withdraw balance created successfully',
      withdrawBalance: createdWithdraw,
    });
  } catch (error) {
    console.error('Error creating withdraw balance:', error);

    if (error.name === 'SequelizeValidationError') {
      return res.status(400).json({ error: error.errors[0].message });
    }

    res.status(500).json({ error: 'Internal server error' });
  }
};

// Update withdraw balance
const updateWithdrawBalance = async (req, res) => {
  try {
    const { id } = req.params;

    // Input validation
    const withdrawId = parseInt(id);
    if (isNaN(withdrawId) || withdrawId < 1) {
      return res.status(400).json({ error: 'Invalid withdraw balance ID' });
    }

    const {
      status,
      date,
      before_balance,
      after_balance,
      bank_name,
      branch,
      bank_account,
      account_holder_name,
      swift,
    } = req.body;

    const withdrawBalance = await WithdrawBalance.findByPk(withdrawId);
    if (!withdrawBalance) {
      return res.status(404).json({ error: 'Withdraw balance not found' });
    }

    const updateData = {};

    // Validate and sanitize provided fields
    if (status !== undefined) {
      const validStatuses = ['requested', 'success', 'failed', 'cancelled'];
      if (!validStatuses.includes(status)) {
        return res.status(400).json({ error: 'Invalid status value' });
      }
      updateData.status = status;
    }

    if (date !== undefined) {
      const dateObj = new Date(date);
      if (isNaN(dateObj.getTime())) {
        return res.status(400).json({ error: 'Invalid date format' });
      }
      updateData.date = dateObj;
    }

    if (before_balance !== undefined) {
      const bal = parseFloat(before_balance);
      if (isNaN(bal) || bal < 0) {
        return res.status(400).json({ error: 'Invalid before_balance (must be non-negative number)' });
      }
      updateData.before_balance = bal;
    }

    if (after_balance !== undefined) {
      const bal = parseFloat(after_balance);
      if (isNaN(bal) || bal < 0) {
        return res.status(400).json({ error: 'Invalid after_balance (must be non-negative number)' });
      }
      updateData.after_balance = bal;
    }

    // Sanitize optional string fields
    if (bank_name !== undefined) {
      updateData.bank_name = bank_name === null ? null : bank_name.toString().trim().substring(0, 255);
    }
    if (branch !== undefined) {
      updateData.branch = branch === null ? null : branch.toString().trim().substring(0, 255);
    }
    if (bank_account !== undefined) {
      updateData.bank_account = bank_account === null ? null : bank_account.toString().trim().substring(0, 255);
    }
    if (account_holder_name !== undefined) {
      updateData.account_holder_name = account_holder_name === null ? null : account_holder_name.toString().trim().substring(0, 255);
    }
    if (swift !== undefined) {
      updateData.swift = swift === null ? null : swift.toString().trim().substring(0, 50);
    }

    await withdrawBalance.update(updateData);

    // Fetch updated record with user data
    const updatedWithdraw = await WithdrawBalance.findByPk(withdrawId, {
      include: [
        {
          model: User,
          as: 'user',
          attributes: ['id', 'name', 'email', 'available_balance', 'pending_balance'],
        },
      ],
    });

    res.json({
      message: 'Withdraw balance updated successfully',
      withdrawBalance: updatedWithdraw,
    });
  } catch (error) {
    console.error('Error updating withdraw balance:', error);

    if (error.name === 'SequelizeValidationError') {
      return res.status(400).json({ error: error.errors[0].message });
    }

    res.status(500).json({ error: 'Internal server error' });
  }
};

// Delete withdraw balance
const deleteWithdrawBalance = async (req, res) => {
  try {
    const { id } = req.params;

    // Input validation
    const withdrawId = parseInt(id);
    if (isNaN(withdrawId) || withdrawId < 1) {
      return res.status(400).json({ error: 'Invalid withdraw balance ID' });
    }

    const withdrawBalance = await WithdrawBalance.findByPk(withdrawId);
    if (!withdrawBalance) {
      return res.status(404).json({ error: 'Withdraw balance not found' });
    }

    await withdrawBalance.destroy();

    res.json({ message: 'Withdraw balance deleted successfully' });
  } catch (error) {
    console.error('Error deleting withdraw balance:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

module.exports = {
  getWithdrawBalances,
  getWithdrawBalanceById,
  createWithdrawBalance,
  updateWithdrawBalance,
  deleteWithdrawBalance,
};
