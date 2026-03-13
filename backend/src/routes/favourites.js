const express = require('express');
const { authenticateToken } = require('../middleware/authMiddleware');
const {
  getFavourites,
  getFavouriteById,
  createFavourite,
  updateFavourite,
  deleteFavourite,
} = require('../controllers/favouriteController');

const router = express.Router();

// GET /api/favourites - Get all favourites with pagination, filtering, and sorting
router.get('/', authenticateToken, getFavourites);

// GET /api/favourites/:user_id/:listing_id - Get single favourite
router.get('/:user_id/:listing_id', authenticateToken, getFavouriteById);

// POST /api/favourites - Create new favourite
router.post('/', authenticateToken, createFavourite);

// PUT /api/favourites/:user_id/:listing_id - Update favourite
router.put('/:user_id/:listing_id', authenticateToken, updateFavourite);

// DELETE /api/favourites/:user_id/:listing_id - Delete favourite
router.delete('/:user_id/:listing_id', authenticateToken, deleteFavourite);

module.exports = router;
