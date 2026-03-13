const express = require('express');
const { authenticateToken } = require('../middleware/authMiddleware');
const {
  getUserDevices,
  getUserDeviceById,
  createUserDevice,
  updateUserDevice,
  deleteUserDevice,
} = require('../controllers/userDeviceController');

const router = express.Router();

// GET /api/user-devices - Get all user devices with pagination, filtering, and sorting
router.get('/', authenticateToken, getUserDevices);

// GET /api/user-devices/:id - Get single user device
router.get('/:id', authenticateToken, getUserDeviceById);

// POST /api/user-devices - Create new user device
router.post('/', authenticateToken, createUserDevice);

// PUT /api/user-devices/:id - Update user device
router.put('/:id', authenticateToken, updateUserDevice);

// DELETE /api/user-devices/:id - Delete user device
router.delete('/:id', authenticateToken, deleteUserDevice);

module.exports = router;
