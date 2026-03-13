const express = require('express');
const { authenticateToken } = require('../middleware/authMiddleware');
const {
  getListingFeatures,
  getListingFeatureById,
  createListingFeature,
  updateListingFeature,
  deleteListingFeature,
} = require('../controllers/listingFeaturesController');

const router = express.Router();

// GET /api/listing-features - Get all listing features with pagination, filtering, sorting
router.get('/', authenticateToken, getListingFeatures);

// GET /api/listing-features/:id - Get single listing feature
router.get('/:id(\\d+)', authenticateToken, getListingFeatureById);

// POST /api/listing-features - Create new listing feature
router.post('/', authenticateToken, createListingFeature);

// PUT /api/listing-features/:id - Update listing feature
router.put('/:id(\\d+)', authenticateToken, updateListingFeature);

// DELETE /api/listing-features/:id - Delete listing feature
router.delete('/:id(\\d+)', authenticateToken, deleteListingFeature);

module.exports = router;
