const express = require('express');
const { Op } = require('sequelize');
const { Language } = require('../models');
const { authenticateToken } = require('../middleware/authMiddleware');
const {
  getLanguages,
  getLanguageById,
  createLanguage,
  updateLanguage,
  deleteLanguage,
} = require('../controllers/languageController');

const router = express.Router();

// GET /api/languages - Get all languages with pagination and filtering
router.get('/', authenticateToken, getLanguages);

// GET /api/languages/:id - Get single language
router.get('/:id(\\d+)', authenticateToken, getLanguageById);

// POST /api/languages - Create new language
router.post('/', authenticateToken, createLanguage);

// PUT /api/languages/:id - Update language
router.put('/:id(\\d+)', authenticateToken, updateLanguage);

// DELETE /api/languages/:id - Delete language
router.delete('/:id(\\d+)', authenticateToken, deleteLanguage);

module.exports = router;
