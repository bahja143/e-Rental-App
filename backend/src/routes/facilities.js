const express = require('express');
const { authenticateToken } = require('../middleware/authMiddleware');
const {
  getFacilities,
  getFacilityById,
  createFacility,
  updateFacility,
  deleteFacility,
} = require('../controllers/facilityController');

const router = express.Router();

// GET /api/facilities - Get all facilities with pagination, filtering, sorting
router.get('/', authenticateToken, getFacilities);

// GET /api/facilities/:id - Get single facility
router.get('/:id(\\d+)', authenticateToken, getFacilityById);

// POST /api/facilities - Create new facility
router.post('/', authenticateToken, createFacility);

// PUT /api/facilities/:id - Update facility
router.put('/:id(\\d+)', authenticateToken, updateFacility);

// DELETE /api/facilities/:id - Delete facility
router.delete('/:id(\\d+)', authenticateToken, deleteFacility);

module.exports = router;
