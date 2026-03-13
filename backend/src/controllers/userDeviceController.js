const { UserDevice, User } = require('../models');
const { Op } = require('sequelize');

const resolveRequester = (req) => {
  const userId = req.user?.userId ?? req.user?.id;
  const isAdmin = req.user?.role === 'admin';
  return { userId, isAdmin };
};

// Get all user devices with pagination, filtering, and sorting
const getUserDevices = async (req, res) => {
  try {
    const { userId: requesterId, isAdmin } = resolveRequester(req);
    const {
      page = 1,
      limit = 10,
      search,
      sortBy = 'createdAt',
      sortOrder = 'DESC',
      user_id,
      device_type,
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

    // Filter by user_id (non-admin users can only see their own devices)
    if (user_id) {
      const userIdNum = parseInt(user_id);
      if (isNaN(userIdNum) || userIdNum < 1) {
        return res.status(400).json({ error: 'Invalid user_id' });
      }
      if (!isAdmin && requesterId && userIdNum !== requesterId) {
        return res.status(403).json({ error: 'You can only access your own devices' });
      }
      whereClause.user_id = userIdNum;
    } else if (!isAdmin && requesterId) {
      whereClause.user_id = requesterId;
    }

    // Filter by device_type
    if (device_type && typeof device_type === 'string' && device_type.trim().length > 0) {
      whereClause.device_type = device_type.trim();
    }

    // Search filter with sanitization
    if (search && typeof search === 'string' && search.trim().length > 0) {
      const sanitizedSearch = search.trim().replace(/[%_]/g, '\\$&'); // Escape SQL wildcards
      whereClause[Op.or] = [
        { device_type: { [Op.like]: `%${sanitizedSearch}%` } },
        { fcm_token: { [Op.like]: `%${sanitizedSearch}%` } },
      ];
    }

    // Sorting with validation
    const validSortFields = ['id', 'user_id', 'device_type', 'fcm_token', 'createdAt', 'updatedAt'];
    const sortField = validSortFields.includes(sortBy) ? sortBy : 'createdAt';
    const sortDirection = sortOrder.toUpperCase() === 'ASC' ? 'ASC' : 'DESC';

    const { count, rows: userDevices } = await UserDevice.findAndCountAll({
      where: whereClause,
      limit: limitNum,
      offset: offset,
      order: [[sortField, sortDirection]],
      include: [
        {
          model: User,
          as: 'user',
          attributes: ['id', 'name', 'email'],
        },
      ],
    });

    const totalPages = Math.ceil(count / limitNum);

    res.json({
      data: userDevices,
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
    console.error('Error fetching user devices:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// Get single user device
const getUserDeviceById = async (req, res) => {
  try {
    const { userId: requesterId, isAdmin } = resolveRequester(req);
    const { id } = req.params;

    // Input validation
    const deviceId = parseInt(id);
    if (isNaN(deviceId) || deviceId < 1) {
      return res.status(400).json({ error: 'Invalid device ID' });
    }

    const userDevice = await UserDevice.findByPk(deviceId, {
      include: [
        {
          model: User,
          as: 'user',
          attributes: ['id', 'name', 'email'],
        },
      ],
    });

    if (!userDevice) {
      return res.status(404).json({ error: 'User device not found' });
    }

    if (!isAdmin && requesterId && parseInt(userDevice.user_id) !== parseInt(requesterId)) {
      return res.status(403).json({ error: 'You do not have permission to view this device' });
    }

    res.json(userDevice);
  } catch (error) {
    console.error('Error fetching user device:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// Create new user device
const createUserDevice = async (req, res) => {
  try {
    const { userId: requesterId, isAdmin } = resolveRequester(req);
    const { user_id, device_type, fcm_token } = req.body;

    // Input validation
    if (!device_type || !fcm_token) {
      return res.status(400).json({ error: 'device_type and fcm_token are required' });
    }

    const candidateUserId = user_id ?? requesterId;
    const userIdNum = parseInt(candidateUserId);
    if (isNaN(userIdNum) || userIdNum < 1) {
      return res.status(400).json({ error: 'Invalid user_id' });
    }
    if (!isAdmin && requesterId && userIdNum !== requesterId) {
      return res.status(403).json({ error: 'You can only register your own device token' });
    }

    if (typeof device_type !== 'string' || device_type.trim().length === 0 || device_type.length > 20) {
      return res.status(400).json({ error: 'device_type must be a string between 1-20 characters' });
    }

    if (typeof fcm_token !== 'string') {
      return res.status(400).json({ error: 'fcm_token must be a string' });
    }

    const trimmedFcmToken = fcm_token.trim();
    if (trimmedFcmToken.length === 0) {
      return res.status(400).json({ error: 'fcm_token must be a non-empty string' });
    }

    // Check if user exists
    const user = await User.findByPk(userIdNum);
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    // Upsert behavior:
    // - if this exact token exists for user, refresh device_type
    // - if same user+device_type exists, rotate token
    // - if token exists on other user, reassign it to current user (single token owner)
    const existingByToken = await UserDevice.findOne({ where: { fcm_token: trimmedFcmToken } });
    const existingByUserAndType = await UserDevice.findOne({
      where: {
        user_id: userIdNum,
        device_type: device_type.trim(),
      },
    });

    let userDevice;
    if (existingByToken) {
      await existingByToken.update({
        user_id: userIdNum,
        device_type: device_type.trim(),
      });
      userDevice = existingByToken;
    } else if (existingByUserAndType) {
      await existingByUserAndType.update({
        fcm_token: trimmedFcmToken,
      });
      userDevice = existingByUserAndType;
    } else {
      userDevice = await UserDevice.create({
        user_id: userIdNum,
        device_type: device_type.trim(),
        fcm_token: trimmedFcmToken,
      });
    }

    // Fetch with user data
    const createdDevice = await UserDevice.findByPk(userDevice.id, {
      include: [
        {
          model: User,
          as: 'user',
          attributes: ['id', 'name', 'email'],
        },
      ],
    });

    res.status(201).json({
      message: 'User device created successfully',
      userDevice: createdDevice,
    });
  } catch (error) {
    console.error('Error creating user device:', error);

    if (error.name === 'SequelizeValidationError') {
      return res.status(400).json({ error: error.errors[0].message });
    }

    if (error.name === 'SequelizeUniqueConstraintError') {
      return res.status(409).json({ error: 'User device already exists' });
    }

    res.status(500).json({ error: 'Internal server error' });
  }
};

// Update user device
const updateUserDevice = async (req, res) => {
  try {
    const { userId: requesterId, isAdmin } = resolveRequester(req);
    const { id } = req.params;
    const { device_type, fcm_token } = req.body;

    // Input validation
    const deviceId = parseInt(id);
    if (isNaN(deviceId) || deviceId < 1) {
      return res.status(400).json({ error: 'Invalid device ID' });
    }

    const userDevice = await UserDevice.findByPk(deviceId);
    if (!userDevice) {
      return res.status(404).json({ error: 'User device not found' });
    }
    if (!isAdmin && requesterId && parseInt(userDevice.user_id) !== parseInt(requesterId)) {
      return res.status(403).json({ error: 'You do not have permission to update this device' });
    }

    const updateData = {};

    if (device_type !== undefined) {
      if (typeof device_type !== 'string' || device_type.trim().length === 0 || device_type.length > 20) {
        return res.status(400).json({ error: 'device_type must be a string between 1-20 characters' });
      }
      updateData.device_type = device_type.trim();
    }

    if (fcm_token !== undefined) {
      if (typeof fcm_token !== 'string' || fcm_token.trim().length === 0) {
        return res.status(400).json({ error: 'fcm_token must be a non-empty string' });
      }
      updateData.fcm_token = fcm_token.trim();
    }

    if (Object.keys(updateData).length === 0) {
      return res.status(400).json({ error: 'No valid fields to update' });
    }

    await userDevice.update(updateData);

    // Fetch updated device with user data
    const updatedDevice = await UserDevice.findByPk(deviceId, {
      include: [
        {
          model: User,
          as: 'user',
          attributes: ['id', 'name', 'email'],
        },
      ],
    });

    res.json({
      message: 'User device updated successfully',
      userDevice: updatedDevice,
    });
  } catch (error) {
    console.error('Error updating user device:', error);

    if (error.name === 'SequelizeValidationError') {
      return res.status(400).json({ error: error.errors[0].message });
    }

    if (error.name === 'SequelizeUniqueConstraintError') {
      return res.status(409).json({ error: 'User device already exists' });
    }

    res.status(500).json({ error: 'Internal server error' });
  }
};

// Delete user device
const deleteUserDevice = async (req, res) => {
  try {
    const { userId: requesterId, isAdmin } = resolveRequester(req);
    const { id } = req.params;

    // Input validation
    const deviceId = parseInt(id);
    if (isNaN(deviceId) || deviceId < 1) {
      return res.status(400).json({ error: 'Invalid device ID' });
    }

    const userDevice = await UserDevice.findByPk(deviceId);
    if (!userDevice) {
      return res.status(404).json({ error: 'User device not found' });
    }
    if (!isAdmin && requesterId && parseInt(userDevice.user_id) !== parseInt(requesterId)) {
      return res.status(403).json({ error: 'You do not have permission to delete this device' });
    }

    await userDevice.destroy();

    res.json({ message: 'User device deleted successfully' });
  } catch (error) {
    console.error('Error deleting user device:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

module.exports = {
  getUserDevices,
  getUserDeviceById,
  createUserDevice,
  updateUserDevice,
  deleteUserDevice,
};
