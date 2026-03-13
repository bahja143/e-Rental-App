const express = require('express');
const router = express.Router();
const promotionController = require('../controllers/promotionController');
const { authenticateToken } = require('../middleware/authMiddleware');

// GET /api/promotions - Get all promotions with pagination, filtering, and sorting
router.get('/', promotionController.getPromotions);

// GET /api/promotions/:id - Get single promotion
router.get('/:id', promotionController.getPromotionById);

// POST /api/promotions - Create new promotion (authenticated)
router.post('/', authenticateToken, promotionController.createPromotion);

// PUT /api/promotions/:id - Update promotion (authenticated)
router.put('/:id', authenticateToken, promotionController.updatePromotion);

// DELETE /api/promotions/:id - Delete promotion (authenticated)
router.delete('/:id', authenticateToken, promotionController.deletePromotion);

module.exports = router;
