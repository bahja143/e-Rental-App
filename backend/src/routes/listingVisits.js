const express = require('express');
const { authenticateToken } = require('../middleware/authMiddleware');
const {
  getListingVisits,
  getListingVisitById,
  createListingVisit,
  updateListingVisit,
  deleteListingVisit,
} = require('../controllers/listingVisitsController');

const router = express.Router();

// GET /api/listing-visits - Get all listing visits with pagination, filtering, sorting
router.get('/', authenticateToken, getListingVisits);

// GET /api/listing-visits/:id - Get single listing visit
router.get('/:id(\\d+)', authenticateToken, getListingVisitById);

// POST /api/listing-visits - Create new listing visit
router.post('/', authenticateToken, createListingVisit);

// PUT /api/listing-visits/:id - Update listing visit
router.put('/:id(\\d+)', authenticateToken, updateListingVisit);

// DELETE /api/listing-visits/:id - Delete listing visit
router.delete('/:id(\\d+)', authenticateToken, deleteListingVisit);

module.exports = router;
