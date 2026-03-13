const express = require('express');
const { authenticateToken } = require('../middleware/authMiddleware');
const { requireListingOwner } = require('../middleware/authorizationMiddleware');
const {
  getListings,
  getListingById,
  createListing,
  updateListing,
  deleteListing,
} = require('../controllers/listingController');

const router = express.Router();

// GET /api/listings - Get all listings with pagination, filtering, sorting
router.get('/', authenticateToken, getListings);

// GET /api/listings/:id - Get single listing
router.get('/:id(\\d+)', authenticateToken, getListingById);

// POST /api/listings - Create new listing (user_id from auth)
router.post('/', authenticateToken, createListing);

// PUT /api/listings/:id - Update listing (owner only)
router.put('/:id(\\d+)', authenticateToken, requireListingOwner, updateListing);

// DELETE /api/listings/:id - Delete listing (owner only)
router.delete('/:id(\\d+)', authenticateToken, requireListingOwner, deleteListing);

module.exports = router;
