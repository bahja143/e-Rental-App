const express = require('express');
const { authenticateToken } = require('../middleware/authMiddleware');
const {
  getPropertyFeatures,
  getPropertyFeatureById,
  createPropertyFeature,
  updatePropertyFeature,
  deletePropertyFeature,
} = require('../controllers/propertyFeaturesController');

const router = express.Router();

// GET /api/property-features - Get all property features with pagination, filtering, sorting
router.get('/', authenticateToken, getPropertyFeatures);

// GET /api/property-features/:id - Get single property feature
router.get('/:id', authenticateToken, getPropertyFeatureById);

// POST /api/property-features - Create new property feature
router.post('/', authenticateToken, createPropertyFeature);

// PUT /api/property-features/:id - Update property feature
router.put('/:id', authenticateToken, updatePropertyFeature);

// DELETE /api/property-features/:id - Delete property feature
router.delete('/:id', authenticateToken, deletePropertyFeature);

module.exports = router;
