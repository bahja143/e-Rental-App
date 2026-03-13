const express = require('express');
const { authenticateToken } = require('../middleware/authMiddleware');
const {
  getListingRentals,
  getListingRentalById,
  createListingRental,
  updateListingRental,
  deleteListingRental,
} = require('../controllers/listingRentalController');

const router = express.Router();

// GET /api/listing-rentals - Get all listing rentals (user sees only their rentals as renter or owner)
router.get('/', authenticateToken, getListingRentals);

// GET /api/listing-rentals/:id - Get single listing rental (renter or owner only)
router.get('/:id', authenticateToken, getListingRentalById);

// POST /api/listing-rentals - Create new listing rental (renter_id from auth; availability & price calculated)
router.post('/', authenticateToken, createListingRental);

// PUT /api/listing-rentals/:id - Update listing rental (participant only; owner confirms)
router.put('/:id', authenticateToken, updateListingRental);

// DELETE /api/listing-rentals/:id - Delete listing rental (participant only)
router.delete('/:id', authenticateToken, deleteListingRental);

module.exports = router;
