const { UserListingPackTransaction, User, ListingPack, Coupon } = require('../models');
const { Op } = require('sequelize');

// Get all user listing pack transactions with pagination, filtering, and sorting
const getUserListingPackTransactions = async (req, res) => {
  try {
    const {
      page = 1,
      limit = 10,
      search,
      user_id,
      listing_pack_id,
      coupon_id,
      type,
      payment_method,
      status,
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

    // Filter by listing_pack_id with validation
    if (listing_pack_id) {
      const packIdNum = parseInt(listing_pack_id);
      if (isNaN(packIdNum) || packIdNum < 1) {
        return res.status(400).json({ error: 'Invalid listing_pack_id' });
      }
      whereClause.listing_pack_id = packIdNum;
    }

    // Filter by coupon_id with validation
    if (coupon_id) {
      const couponIdNum = parseInt(coupon_id);
      if (isNaN(couponIdNum) || couponIdNum < 1) {
        return res.status(400).json({ error: 'Invalid coupon_id' });
      }
      whereClause.coupon_id = couponIdNum;
    }

    // Filter by type
    if (type && ['buy', 'upgrade', 'downgrade', 'renew', 'refund', 'adjustment'].includes(type)) {
      whereClause.type = type;
    }

    // Filter by payment_method
    if (payment_method && ['bank', 'card', 'wallet', 'admin'].includes(payment_method)) {
      whereClause.payment_method = payment_method;
    }

    // Filter by status
    if (status && ['pending', 'success', 'failed'].includes(status)) {
      whereClause.status = status;
    }

    // Sorting with validation
    const validSortFields = ['id', 'user_id', 'listing_pack_id', 'type', 'subtotal', 'total', 'status', 'createdAt', 'updatedAt'];
    const sortField = validSortFields.includes(sortBy) ? sortBy : 'createdAt';
    const sortDirection = sortOrder.toUpperCase() === 'ASC' ? 'ASC' : 'DESC';

    const include = [
      {
        model: User,
        as: 'user',
        attributes: ['id', 'name', 'email'],
      },
      {
        model: ListingPack,
        as: 'listingPack',
        attributes: [['name_en', 'name'], 'name_so', 'price', ['duration', 'duration_days']],
      },
      {
        model: Coupon,
        as: 'coupon',
        attributes: ['id', 'code', 'type', 'value'],
      },
      {
        model: ListingPack,
        as: 'previousPack',
        attributes: [['name_en', 'name'], 'name_so', 'price'],
      },
    ];

    const { count, rows: transactions } = await UserListingPackTransaction.findAndCountAll({
      where: whereClause,
      limit: limitNum,
      offset: offset,
      order: [[sortField, sortDirection]],
      include,
    });

    const totalPages = Math.ceil(count / limitNum);

    res.json({
      data: transactions,
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
    console.error('Error fetching user listing pack transactions:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// Get single user listing pack transaction by ID
const getUserListingPackTransactionById = async (req, res) => {
  try {
    const { id } = req.params;

    // Input validation
    const transactionId = parseInt(id);
    if (isNaN(transactionId) || transactionId < 1) {
      return res.status(400).json({ error: 'Invalid transaction ID' });
    }

    const transaction = await UserListingPackTransaction.findByPk(transactionId, {
      include: [
        {
          model: User,
          as: 'user',
          attributes: ['id', 'name', 'email'],
        },
      {
        model: ListingPack,
        as: 'listingPack',
        attributes: [['name_en', 'name'], 'name_so', 'price', ['duration', 'duration_days']],
      },
        {
          model: Coupon,
          as: 'coupon',
          attributes: ['id', 'code', 'type', 'value'],
        },
        {
          model: ListingPack,
          as: 'previousPack',
          attributes: [['name_en', 'name'], 'name_so', 'price'],
        },
      ],
    });

    if (!transaction) {
      return res.status(404).json({ error: 'Transaction not found' });
    }

    res.json(transaction);
  } catch (error) {
    console.error('Error fetching user listing pack transaction:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// Create new user listing pack transaction
const createUserListingPackTransaction = async (req, res) => {
  try {
    const {
      user_id,
      listing_pack_id,
      type,
      subtotal,
      coupon_id,
      discount,
      total,
      coupon_code,
      previous_pack_id,
      adjusted_amount,
      payment_method,
      transaction_ref,
      status = 'pending',
      note,
      bank_name,
      branch,
      bank_account,
      account_holder_name,
      swift,
    } = req.body;

    // Input validation and sanitization
    const userIdNum = parseInt(user_id);
    const packIdNum = parseInt(listing_pack_id);

    if (isNaN(userIdNum) || userIdNum < 1) {
      return res.status(400).json({ error: 'Valid user_id is required' });
    }
    if (isNaN(packIdNum) || packIdNum < 1) {
      return res.status(400).json({ error: 'Valid listing_pack_id is required' });
    }

    // Validate required fields
    if (!type || !['buy', 'upgrade', 'downgrade', 'renew', 'refund', 'adjustment'].includes(type)) {
      return res.status(400).json({ error: 'Valid type is required' });
    }
    if (!payment_method || !['bank', 'card', 'wallet', 'admin'].includes(payment_method)) {
      return res.status(400).json({ error: 'Valid payment_method is required' });
    }
    if (!transaction_ref || typeof transaction_ref !== 'string' || transaction_ref.trim().length === 0) {
      return res.status(400).json({ error: 'Valid transaction_ref is required' });
    }

    // Validate amounts
    const subtotalNum = parseFloat(subtotal);
    if (isNaN(subtotalNum) || subtotalNum < 0) {
      return res.status(400).json({ error: 'Valid subtotal is required' });
    }

    // Check if user exists
    const user = await User.findByPk(userIdNum);
    if (!user) {
      return res.status(400).json({ error: 'User not found' });
    }

    // Check if listing pack exists
    const listingPack = await ListingPack.findByPk(packIdNum);
    if (!listingPack) {
      return res.status(400).json({ error: 'Listing pack not found' });
    }

    // Check if coupon exists (if provided)
    if (coupon_id) {
      const couponIdNum = parseInt(coupon_id);
      if (isNaN(couponIdNum) || couponIdNum < 1) {
        return res.status(400).json({ error: 'Invalid coupon_id' });
      }
      const coupon = await Coupon.findByPk(couponIdNum);
      if (!coupon) {
        return res.status(400).json({ error: 'Coupon not found' });
      }
    }

    // Check if previous pack exists (if provided)
    if (previous_pack_id) {
      const prevPackIdNum = parseInt(previous_pack_id);
      if (isNaN(prevPackIdNum) || prevPackIdNum < 1) {
        return res.status(400).json({ error: 'Invalid previous_pack_id' });
      }
      const previousPack = await ListingPack.findByPk(prevPackIdNum);
      if (!previousPack) {
        return res.status(400).json({ error: 'Previous pack not found' });
      }
    }

    const transactionData = {
      user_id: userIdNum,
      listing_pack_id: packIdNum,
      type,
      subtotal: subtotalNum,
      coupon_id: coupon_id ? parseInt(coupon_id) : null,
      discount: discount ? parseFloat(discount) : null,
      total: total ? parseFloat(total) : null,
      coupon_code: coupon_code ? coupon_code.trim() : null,
      previous_pack_id: previous_pack_id ? parseInt(previous_pack_id) : null,
      adjusted_amount: adjusted_amount ? parseFloat(adjusted_amount) : null,
      payment_method,
      transaction_ref: transaction_ref.trim(),
      status: status && ['pending', 'success', 'failed'].includes(status) ? status : 'pending',
      note: note ? note.trim() : null,
      bank_name: bank_name ? bank_name.trim() : null,
      branch: branch ? branch.trim() : null,
      bank_account: bank_account ? bank_account.trim() : null,
      account_holder_name: account_holder_name ? account_holder_name.trim() : null,
      swift: swift ? swift.trim() : null,
    };

    const transaction = await UserListingPackTransaction.create(transactionData);

    // Fetch the created record with associations
    const createdTransaction = await UserListingPackTransaction.findByPk(transaction.id, {
      include: [
        {
          model: User,
          as: 'user',
          attributes: ['id', 'name', 'email'],
        },
      {
        model: ListingPack,
        as: 'listingPack',
        attributes: [['name_en', 'name'], 'name_so', 'price', ['duration', 'duration_days']],
      },
        {
          model: Coupon,
          as: 'coupon',
          attributes: ['id', 'code', 'type', 'value'],
        },
        {
          model: ListingPack,
          as: 'previousPack',
          attributes: [['name_en', 'name'], 'name_so', 'price'],
        },
      ],
    });

    res.status(201).json({
      message: 'Transaction created successfully',
      transaction: createdTransaction,
    });
  } catch (error) {
    console.error('Error creating user listing pack transaction:', error);

    if (error.name === 'SequelizeUniqueConstraintError') {
      return res.status(409).json({ error: 'Transaction reference already exists' });
    }

    res.status(500).json({ error: 'Internal server error' });
  }
};

// Update user listing pack transaction
const updateUserListingPackTransaction = async (req, res) => {
  try {
    const { id } = req.params;
    const {
      type,
      subtotal,
      coupon_id,
      discount,
      total,
      coupon_code,
      previous_pack_id,
      adjusted_amount,
      payment_method,
      transaction_ref,
      status,
      note,
      bank_name,
      branch,
      bank_account,
      account_holder_name,
      swift,
    } = req.body;

    // Input validation
    const transactionId = parseInt(id);
    if (isNaN(transactionId) || transactionId < 1) {
      return res.status(400).json({ error: 'Invalid transaction ID' });
    }

    const transaction = await UserListingPackTransaction.findByPk(transactionId);
    if (!transaction) {
      return res.status(404).json({ error: 'Transaction not found' });
    }

    const updateData = {};

    // Validate and sanitize provided fields
    if (type !== undefined && ['buy', 'upgrade', 'downgrade', 'renew', 'refund', 'adjustment'].includes(type)) {
      updateData.type = type;
    }

    if (subtotal !== undefined) {
      const subtotalNum = parseFloat(subtotal);
      if (isNaN(subtotalNum) || subtotalNum < 0) {
        return res.status(400).json({ error: 'Invalid subtotal' });
      }
      updateData.subtotal = subtotalNum;
    }

    if (coupon_id !== undefined) {
      if (coupon_id === null) {
        updateData.coupon_id = null;
      } else {
        const couponIdNum = parseInt(coupon_id);
        if (isNaN(couponIdNum) || couponIdNum < 1) {
          return res.status(400).json({ error: 'Invalid coupon_id' });
        }
        const coupon = await Coupon.findByPk(couponIdNum);
        if (!coupon) {
          return res.status(400).json({ error: 'Coupon not found' });
        }
        updateData.coupon_id = couponIdNum;
      }
    }

    if (discount !== undefined) {
      if (discount === null) {
        updateData.discount = null;
      } else {
        const discountNum = parseFloat(discount);
        if (isNaN(discountNum) || discountNum < 0) {
          return res.status(400).json({ error: 'Invalid discount' });
        }
        updateData.discount = discountNum;
      }
    }

    if (total !== undefined) {
      if (total === null) {
        updateData.total = null;
      } else {
        const totalNum = parseFloat(total);
        if (isNaN(totalNum) || totalNum < 0) {
          return res.status(400).json({ error: 'Invalid total' });
        }
        updateData.total = totalNum;
      }
    }

    if (coupon_code !== undefined) {
      updateData.coupon_code = coupon_code ? coupon_code.trim() : null;
    }

    if (previous_pack_id !== undefined) {
      if (previous_pack_id === null) {
        updateData.previous_pack_id = null;
      } else {
        const prevPackIdNum = parseInt(previous_pack_id);
        if (isNaN(prevPackIdNum) || prevPackIdNum < 1) {
          return res.status(400).json({ error: 'Invalid previous_pack_id' });
        }
        const previousPack = await ListingPack.findByPk(prevPackIdNum);
        if (!previousPack) {
          return res.status(400).json({ error: 'Previous pack not found' });
        }
        updateData.previous_pack_id = prevPackIdNum;
      }
    }

    if (adjusted_amount !== undefined) {
      if (adjusted_amount === null) {
        updateData.adjusted_amount = null;
      } else {
        const adjustedNum = parseFloat(adjusted_amount);
        if (isNaN(adjustedNum)) {
          return res.status(400).json({ error: 'Invalid adjusted_amount' });
        }
        updateData.adjusted_amount = adjustedNum;
      }
    }

    if (payment_method !== undefined && ['bank', 'card', 'wallet', 'admin'].includes(payment_method)) {
      updateData.payment_method = payment_method;
    }

    if (transaction_ref !== undefined) {
      if (typeof transaction_ref !== 'string' || transaction_ref.trim().length === 0) {
        return res.status(400).json({ error: 'Invalid transaction_ref' });
      }
      updateData.transaction_ref = transaction_ref.trim();
    }

    if (status !== undefined && ['pending', 'success', 'failed'].includes(status)) {
      updateData.status = status;
    }

    if (note !== undefined) {
      updateData.note = note ? note.trim() : null;
    }

    // Bank details
    if (bank_name !== undefined) {
      updateData.bank_name = bank_name ? bank_name.trim() : null;
    }
    if (branch !== undefined) {
      updateData.branch = branch ? branch.trim() : null;
    }
    if (bank_account !== undefined) {
      updateData.bank_account = bank_account ? bank_account.trim() : null;
    }
    if (account_holder_name !== undefined) {
      updateData.account_holder_name = account_holder_name ? account_holder_name.trim() : null;
    }
    if (swift !== undefined) {
      updateData.swift = swift ? swift.trim() : null;
    }

    await transaction.update(updateData);

    // Fetch updated record with associations
    const updatedTransaction = await UserListingPackTransaction.findByPk(transactionId, {
      include: [
        {
          model: User,
          as: 'user',
          attributes: ['id', 'name', 'email'],
        },
      {
        model: ListingPack,
        as: 'listingPack',
        attributes: [['name_en', 'name'], 'name_so', 'price', ['duration', 'duration_days']],
      },
        {
          model: Coupon,
          as: 'coupon',
          attributes: ['id', 'code', 'type', 'value'],
        },
        {
          model: ListingPack,
          as: 'previousPack',
          attributes: [['name_en', 'name'], 'name_so', 'price'],
        },
      ],
    });

    res.json({
      message: 'Transaction updated successfully',
      transaction: updatedTransaction,
    });
  } catch (error) {
    console.error('Error updating user listing pack transaction:', error);

    if (error.name === 'SequelizeUniqueConstraintError') {
      return res.status(409).json({ error: 'Transaction reference already exists' });
    }

    res.status(500).json({ error: 'Internal server error' });
  }
};

// Delete user listing pack transaction
const deleteUserListingPackTransaction = async (req, res) => {
  try {
    const { id } = req.params;

    // Input validation
    const transactionId = parseInt(id);
    if (isNaN(transactionId) || transactionId < 1) {
      return res.status(400).json({ error: 'Invalid transaction ID' });
    }

    const transaction = await UserListingPackTransaction.findByPk(transactionId);
    if (!transaction) {
      return res.status(404).json({ error: 'Transaction not found' });
    }

    await transaction.destroy();

    res.json({ message: 'Transaction deleted successfully' });
  } catch (error) {
    console.error('Error deleting user listing pack transaction:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

module.exports = {
  getUserListingPackTransactions,
  getUserListingPackTransactionById,
  createUserListingPackTransaction,
  updateUserListingPackTransaction,
  deleteUserListingPackTransaction,
};
