const express = require('express');
const { authenticateToken } = require('../middleware/authMiddleware');
const {
  getListingCategories,
  getListingCategoryById,
  createListingCategory,
  updateListingCategory,
  deleteListingCategory,
} = require('../controllers/listingCategoryController');

const router = express.Router();

// GET /api/listing-categories - Get all listing categories with pagination, filtering, and sorting
router.get('/', authenticateToken, getListingCategories);

// GET /api/listing-categories/:id - Get single listing category
router.get('/:id', authenticateToken, getListingCategoryById);

// POST /api/listing-categories - Create new listing category
router.post('/', authenticateToken, createListingCategory);

// PUT /api/listing-categories/:id - Update listing category
router.put('/:id', authenticateToken, updateListingCategory);

// DELETE /api/listing-categories/:id - Delete listing category
router.delete('/:id', authenticateToken, deleteListingCategory);

module.exports = router;
