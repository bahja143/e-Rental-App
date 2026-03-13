const express = require('express');
const { authenticateToken } = require('../middleware/authMiddleware');
const {
  getListingReviews,
  getListingReviewById,
  createListingReview,
  updateListingReview,
  deleteListingReview,
} = require('../controllers/listingReviewsController');

const router = express.Router();

// GET /api/listing-reviews - Get all listing reviews with pagination, filtering, sorting
router.get('/', authenticateToken, getListingReviews);

// GET /api/listing-reviews/:id - Get single listing review
router.get('/:id(\\d+)', authenticateToken, getListingReviewById);

// POST /api/listing-reviews - Create new listing review
router.post('/', authenticateToken, createListingReview);

// PUT /api/listing-reviews/:id - Update listing review
router.put('/:id(\\d+)', authenticateToken, updateListingReview);

// DELETE /api/listing-reviews/:id - Delete listing review
router.delete('/:id(\\d+)', authenticateToken, deleteListingReview);

module.exports = router;
