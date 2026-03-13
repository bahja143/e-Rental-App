const express = require('express');
const { authenticateToken } = require('../middleware/authMiddleware');
const {
  getStateCategories,
  getStateCategoryById,
  createStateCategory,
  updateStateCategory,
  deleteStateCategory,
} = require('../controllers/stateCategoryController');

const router = express.Router();

// GET /api/state-categories - Get all state categories with pagination and filtering
router.get('/', authenticateToken, getStateCategories);

// GET /api/state-categories/:id - Get single state category
router.get('/:id', authenticateToken, getStateCategoryById);

// POST /api/state-categories - Create new state category
router.post('/', createStateCategory);

// PUT /api/state-categories/:id - Update state category
router.put('/:id', updateStateCategory);

// DELETE /api/state-categories/:id - Delete state category
router.delete('/:id', deleteStateCategory);

module.exports = router;
