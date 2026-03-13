const express = require('express');
const { authenticateToken } = require('../middleware/authMiddleware');
const {
  getPromotionPacks,
  getPromotionPackById,
  createPromotionPack,
  updatePromotionPack,
  deletePromotionPack,
} = require('../controllers/promotionPackController');

const router = express.Router();

// GET /api/promotion-packs - Get all promotion packs with pagination, filtering, and sorting
router.get('/', getPromotionPacks);

// GET /api/promotion-packs/:id - Get single promotion pack
router.get('/:id', getPromotionPackById);

// POST /api/promotion-packs - Create new promotion pack
router.post('/', authenticateToken, createPromotionPack);

// PUT /api/promotion-packs/:id - Update promotion pack
router.put('/:id', authenticateToken, updatePromotionPack);

// DELETE /api/promotion-packs/:id - Delete promotion pack
router.delete('/:id', authenticateToken, deletePromotionPack);

module.exports = router;
