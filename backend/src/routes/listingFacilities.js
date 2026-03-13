const express = require('express');
const { authenticateToken } = require('../middleware/authMiddleware');
const {
  getListingFacilities,
  getListingFacilityById,
  createListingFacility,
  updateListingFacility,
  deleteListingFacility,
} = require('../controllers/listingFacilitiesController');

const router = express.Router();

// GET /api/listing-facilities - Get all listing facilities with pagination, filtering, sorting
router.get('/', authenticateToken, getListingFacilities);

// GET /api/listing-facilities/:id - Get single listing facility
router.get('/:id(\\d+)', authenticateToken, getListingFacilityById);

// POST /api/listing-facilities - Create new listing facility
router.post('/', authenticateToken, createListingFacility);

// PUT /api/listing-facilities/:id - Update listing facility
router.put('/:id(\\d+)', authenticateToken, updateListingFacility);

// DELETE /api/listing-facilities/:id - Delete listing facility
router.delete('/:id(\\d+)', authenticateToken, deleteListingFacility);

module.exports = router;
