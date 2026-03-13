const express = require('express');
const { authenticateToken } = require('../middleware/authMiddleware');
const {
  getListingPacks,
  getListingPackById,
  createListingPack,
  updateListingPack,
  deleteListingPack,
} = require('../controllers/listingPackController');

const router = express.Router();

// GET /api/listing-packs - Get all listing packs with pagination, filtering, and sorting
router.get('/', getListingPacks);

// GET /api/listing-packs/:id - Get single listing pack
router.get('/:id', getListingPackById);

// POST /api/listing-packs - Create new listing pack
router.post('/', authenticateToken, createListingPack);

// PUT /api/listing-packs/:id - Update listing pack
router.put('/:id', authenticateToken, updateListingPack);

// DELETE /api/listing-packs/:id - Delete listing pack
router.delete('/:id', authenticateToken, deleteListingPack);

module.exports = router;
