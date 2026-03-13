const { Notification, User } = require('../models');
const { Op } = require('sequelize');
const notificationService = require('../services/notificationService');

// Get all notifications with pagination, filtering, and sorting
const getNotifications = async (req, res) => {
  try {
    const {
      page = 1,
      limit = 10,
      search,
      type,
      is_read,
      user_id,
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

    // User filter (for admin access)
    if (user_id) {
      const userIdNum = parseInt(user_id);
      if (isNaN(userIdNum) || userIdNum < 1) {
        return res.status(400).json({ error: 'Invalid user_id' });
      }
      whereClause.user_id = userIdNum;
    }

    // Type filter with sanitization
    if (type && typeof type === 'string' && type.trim().length > 0) {
      const sanitizedType = type.trim().replace(/[%_]/g, '\\$&'); // Escape SQL wildcards
      whereClause.type = { [Op.like]: `%${sanitizedType}%` };
    }

    // Read status filter
    if (is_read !== undefined) {
      if (is_read === 'true') {
        whereClause.is_read = true;
      } else if (is_read === 'false') {
        whereClause.is_read = false;
      }
    }

    // Search filter with sanitization
    if (search && typeof search === 'string' && search.trim().length > 0) {
      const sanitizedSearch = search.trim().replace(/[%_]/g, '\\$&'); // Escape SQL wildcards
      whereClause[Op.or] = [
        { title: { [Op.like]: `%${sanitizedSearch}%` } },
        { message: { [Op.like]: `%${sanitizedSearch}%` } },
      ];
    }

    // Sorting with validation
    const validSortFields = ['id', 'type', 'title', 'is_read', 'createdAt', 'updatedAt'];
    const sortField = validSortFields.includes(sortBy) ? sortBy : 'createdAt';
    const sortDirection = sortOrder.toUpperCase() === 'ASC' ? 'ASC' : 'DESC';

    const { count, rows: notifications } = await Notification.findAndCountAll({
      where: whereClause,
      limit: limitNum,
      offset: offset,
      order: [[sortField, sortDirection]],
      include: [{
        model: User,
        as: 'user',
        attributes: ['id', 'name', 'email'],
      }],
    });

    const totalPages = Math.ceil(count / limitNum);

    res.json({
      data: notifications,
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
    console.error('Error fetching notifications:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// Get single notification
const getNotificationById = async (req, res) => {
  try {
    const { id } = req.params;

    // Input validation
    const notificationId = parseInt(id);
    if (isNaN(notificationId) || notificationId < 1) {
      return res.status(400).json({ error: 'Invalid notification ID' });
    }

    const notification = await Notification.findByPk(notificationId, {
      include: [{
        model: User,
        as: 'user',
        attributes: ['id', 'name', 'email'],
      }],
    });

    if (!notification) {
      return res.status(404).json({ error: 'Notification not found' });
    }

    res.json(notification);
  } catch (error) {
    console.error('Error fetching notification:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// Create notification
const createNotification = async (req, res) => {
  try {
    const { user_id, type, title, message, data } = req.body;

    // Input validation and sanitization
    const userIdNum = parseInt(user_id);
    if (isNaN(userIdNum) || userIdNum < 1) {
      return res.status(400).json({ error: 'Invalid user_id' });
    }

    if (!type || typeof type !== 'string' || type.trim().length === 0 || type.length > 255) {
      return res.status(400).json({ error: 'Type is required and must be 1-255 characters' });
    }

    if (!title || typeof title !== 'string' || title.trim().length === 0 || title.length > 255) {
      return res.status(400).json({ error: 'Title is required and must be 1-255 characters' });
    }

    if (!message || typeof message !== 'string' || message.trim().length === 0) {
      return res.status(400).json({ error: 'Message is required' });
    }

    // Check if user exists
    const user = await User.findByPk(userIdNum);
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    const notification = await notificationService.notifyUser(
      userIdNum,
      type.trim(),
      title.trim(),
      message.trim(),
      data || {}
    );

    // Fetch with user data
    const createdNotification = await Notification.findByPk(notification.id, {
      include: [{
        model: User,
        as: 'user',
        attributes: ['id', 'name', 'email'],
      }],
    });

    res.status(201).json({
      message: 'Notification created successfully',
      notification: createdNotification,
    });
  } catch (error) {
    console.error('Error creating notification:', error);

    if (error.name === 'SequelizeValidationError') {
      return res.status(400).json({ error: error.errors[0].message });
    }

    res.status(500).json({ error: 'Internal server error' });
  }
};

// Update notification
const updateNotification = async (req, res) => {
  try {
    const { id } = req.params;
    const { type, title, message, data, is_read } = req.body;

    // Input validation
    const notificationId = parseInt(id);
    if (isNaN(notificationId) || notificationId < 1) {
      return res.status(400).json({ error: 'Invalid notification ID' });
    }

    const notification = await Notification.findByPk(notificationId);
    if (!notification) {
      return res.status(404).json({ error: 'Notification not found' });
    }

    const updateData = {};

    // Validate and sanitize type
    if (type !== undefined) {
      if (typeof type !== 'string' || type.trim().length === 0 || type.length > 255) {
        return res.status(400).json({ error: 'Type must be 1-255 characters' });
      }
      updateData.type = type.trim();
    }

    // Validate and sanitize title
    if (title !== undefined) {
      if (typeof title !== 'string' || title.trim().length === 0 || title.length > 255) {
        return res.status(400).json({ error: 'Title must be 1-255 characters' });
      }
      updateData.title = title.trim();
    }

    // Validate and sanitize message
    if (message !== undefined) {
      if (typeof message !== 'string' || message.trim().length === 0) {
        return res.status(400).json({ error: 'Message cannot be empty' });
      }
      updateData.message = message.trim();
    }

    // Validate data
    if (data !== undefined) {
      updateData.data = data;
    }

    // Validate is_read
    if (is_read !== undefined) {
      if (typeof is_read !== 'boolean') {
        return res.status(400).json({ error: 'is_read must be a boolean' });
      }
      updateData.is_read = is_read;
    }

    // Check if there's anything to update
    if (Object.keys(updateData).length === 0) {
      return res.status(400).json({ error: 'No valid fields to update' });
    }

    await notification.update(updateData);

    // Fetch updated notification with user data
    const updatedNotification = await Notification.findByPk(notificationId, {
      include: [{
        model: User,
        as: 'user',
        attributes: ['id', 'name', 'email'],
      }],
    });

    res.json({
      message: 'Notification updated successfully',
      notification: updatedNotification,
    });
  } catch (error) {
    console.error('Error updating notification:', error);

    if (error.name === 'SequelizeValidationError') {
      return res.status(400).json({ error: error.errors[0].message });
    }

    res.status(500).json({ error: 'Internal server error' });
  }
};

// Delete notification
const deleteNotification = async (req, res) => {
  try {
    const { id } = req.params;

    // Input validation
    const notificationId = parseInt(id);
    if (isNaN(notificationId) || notificationId < 1) {
      return res.status(400).json({ error: 'Invalid notification ID' });
    }

    const notification = await Notification.findByPk(notificationId);
    if (!notification) {
      return res.status(404).json({ error: 'Notification not found' });
    }

    await notification.destroy();

    res.json({ message: 'Notification deleted successfully' });
  } catch (error) {
    console.error('Error deleting notification:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

module.exports = {
  getNotifications,
  getNotificationById,
  createNotification,
  updateNotification,
  deleteNotification,
};
