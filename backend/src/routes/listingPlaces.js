const express = require('express');
const { authenticateToken } = require('../middleware/authMiddleware');
const {
  getListingPlaces,
  getListingPlaceById,
  createListingPlace,
  updateListingPlace,
  deleteListingPlace,
} = require('../controllers/listingPlacesController');

const router = express.Router();

// GET /api/listing-places - Get all listing places with pagination, filtering, sorting
router.get('/', authenticateToken, getListingPlaces);

// GET /api/listing-places/:id - Get single listing place
router.get('/:id(\\d+)', authenticateToken, getListingPlaceById);

// POST /api/listing-places - Create new listing place
router.post('/', authenticateToken, createListingPlace);

// PUT /api/listing-places/:id - Update listing place
router.put('/:id(\\d+)', authenticateToken, updateListingPlace);

// DELETE /api/listing-places/:id - Delete listing place
router.delete('/:id(\\d+)', authenticateToken, deleteListingPlace);

module.exports = router;
