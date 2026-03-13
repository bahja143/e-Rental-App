const express = require('express');
const { optionalAuth } = require('../middleware/authMiddleware');
const {
  getPublicListings,
  getPublicListingById,
  getListingAvailability,
  getRentalQuote,
} = require('../controllers/publicListingController');

const router = express.Router();

// Public listing browse (no auth required)
router.get('/', getPublicListings);

// Public listing detail
router.get('/:id(\\d+)', getPublicListingById);

// Check availability for date range (useful for date picker)
router.get('/:id(\\d+)/availability', getListingAvailability);

// Get rental price quote (subtotal, discount, total)
router.get('/:id(\\d+)/rental-quote', getRentalQuote);

module.exports = router;
