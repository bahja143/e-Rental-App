const express = require('express');
const { authenticateToken } = require('../middleware/authMiddleware');
const {
  getListingTypes,
  getListingTypeById,
  createListingType,
  updateListingType,
  deleteListingType,
} = require('../controllers/listingTypeController');

const router = express.Router();

// GET /api/listing-types - Get all listing types with pagination, filtering, sorting
router.get('/', authenticateToken, getListingTypes);

// GET /api/listing-types/:id - Get single listing type
router.get('/:id', authenticateToken, getListingTypeById);

// POST /api/listing-types - Create new listing type
router.post('/', authenticateToken, createListingType);

// PUT /api/listing-types/:id - Update listing type
router.put('/:id', authenticateToken, updateListingType);

// DELETE /api/listing-types/:id - Delete listing type
router.delete('/:id', authenticateToken, deleteListingType);

module.exports = router;
