const express = require('express');
const { authenticateToken } = require('../middleware/authMiddleware');
const {
  getPropertyCategories,
  getPropertyCategoryById,
  createPropertyCategory,
  updatePropertyCategory,
  deletePropertyCategory,
} = require('../controllers/propertyCategoryController');

const router = express.Router();

// GET /api/property-categories - Get all property categories with pagination, filtering, sorting
router.get('/', authenticateToken, getPropertyCategories);

// GET /api/property-categories/:id - Get single property category
router.get('/:id', authenticateToken, getPropertyCategoryById);

// POST /api/property-categories - Create new property category
router.post('/', authenticateToken, createPropertyCategory);

// PUT /api/property-categories/:id - Update property category
router.put('/:id', authenticateToken, updatePropertyCategory);

// DELETE /api/property-categories/:id - Delete property category
router.delete('/:id', authenticateToken, deletePropertyCategory);

module.exports = router;
