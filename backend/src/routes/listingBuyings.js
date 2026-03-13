const express = require('express');
const { authenticateToken } = require('../middleware/authMiddleware');
const {
  getListingBuyings,
  getListingBuyingById,
  createListingBuying,
  updateListingBuying,
  deleteListingBuying,
} = require('../controllers/listingBuyingController');

const router = express.Router();

// GET /api/listing-buyings - Get all listing buyings with pagination, filtering, and related data
router.get('/', authenticateToken, getListingBuyings);

// GET /api/listing-buyings/:id - Get single listing buying
router.get('/:id', authenticateToken, getListingBuyingById);

// POST /api/listing-buyings - Create new listing buying
router.post('/', authenticateToken, createListingBuying);

// PUT /api/listing-buyings/:id - Update listing buying
router.put('/:id', authenticateToken, updateListingBuying);

// DELETE /api/listing-buyings/:id - Delete listing buying
router.delete('/:id', authenticateToken, deleteListingBuying);

module.exports = router;
