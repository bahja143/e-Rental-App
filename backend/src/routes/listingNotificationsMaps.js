const express = require('express');
const { authenticateToken } = require('../middleware/authMiddleware');
const {
  getListingNotificationsMaps,
  getListingNotificationsMapById,
  createListingNotificationsMap,
  updateListingNotificationsMap,
  deleteListingNotificationsMap,
} = require('../controllers/listingNotificationsMapController');

const router = express.Router();

// GET /api/listing-notifications-maps - Get all listing notifications maps with pagination, filtering, and sorting
router.get('/', authenticateToken, getListingNotificationsMaps);

// GET /api/listing-notifications-maps/:id - Get single listing notifications map
router.get('/:id', authenticateToken, getListingNotificationsMapById);

// POST /api/listing-notifications-maps - Create new listing notifications map
router.post('/', authenticateToken, createListingNotificationsMap);

// PUT /api/listing-notifications-maps/:id - Update listing notifications map
router.put('/:id', authenticateToken, updateListingNotificationsMap);

// DELETE /api/listing-notifications-maps/:id - Delete listing notifications map
router.delete('/:id', authenticateToken, deleteListingNotificationsMap);

module.exports = router;
