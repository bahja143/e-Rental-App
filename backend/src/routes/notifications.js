const express = require('express');
const { authenticateToken } = require('../middleware/authMiddleware');
const {
  getNotifications,
  getNotificationById,
  createNotification,
  updateNotification,
  deleteNotification,
} = require('../controllers/notificationController');

const router = express.Router();

// GET /api/notifications - Get all notifications with pagination, filtering, and sorting
router.get('/', authenticateToken, getNotifications);

// GET /api/notifications/:id - Get single notification
router.get('/:id', authenticateToken, getNotificationById);

// POST /api/notifications - Create new notification
router.post('/', authenticateToken, createNotification);

// PUT /api/notifications/:id - Update notification
router.put('/:id', authenticateToken, updateNotification);

// DELETE /api/notifications/:id - Delete notification
router.delete('/:id', authenticateToken, deleteNotification);

module.exports = router;
