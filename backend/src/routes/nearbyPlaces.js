const express = require('express');
const { authenticateToken } = require('../middleware/authMiddleware');
const {
  getNearbyPlaces,
  getNearbyPlaceById,
  createNearbyPlace,
  updateNearbyPlace,
  deleteNearbyPlace,
} = require('../controllers/nearbyPlaceController');

const router = express.Router();

// GET /api/nearby-places - Get all nearby places with pagination, filtering, sorting
router.get('/', authenticateToken, getNearbyPlaces);

// GET /api/nearby-places/:id - Get single nearby place
router.get('/:id(\\d+)', authenticateToken, getNearbyPlaceById);

// POST /api/nearby-places - Create new nearby place
router.post('/', authenticateToken, createNearbyPlace);

// PUT /api/nearby-places/:id - Update nearby place
router.put('/:id(\\d+)', authenticateToken, updateNearbyPlace);

// DELETE /api/nearby-places/:id - Delete nearby place
router.delete('/:id(\\d+)', authenticateToken, deleteNearbyPlace);

module.exports = router;
