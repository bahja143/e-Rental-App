const express = require('express');
const { authenticateToken } = require('../middleware/authMiddleware');
const {
  getTypeListings,
  getTypeListingById,
  createTypeListing,
  updateTypeListing,
  deleteTypeListing,
} = require('../controllers/typeListingController');

const router = express.Router();

// GET /api/type-listings - Get all type listings with pagination, filtering, sorting
router.get('/', authenticateToken, getTypeListings);

// GET /api/type-listings/:id - Get single type listing
router.get('/:id', authenticateToken, getTypeListingById);

// POST /api/type-listings - Create new type listing
router.post('/', authenticateToken, createTypeListing);

// PUT /api/type-listings/:id - Update type listing
router.put('/:id', authenticateToken, updateTypeListing);

// DELETE /api/type-listings/:id - Delete type listing
router.delete('/:id', authenticateToken, deleteTypeListing);

module.exports = router;
