const express = require('express');
const router = express.Router();
const couponController = require('../controllers/couponController');
const { authenticateToken } = require('../middleware/authMiddleware');

// GET /api/coupons - Get all coupons with pagination, filtering, and sorting
router.get('/', couponController.getCoupons);

// GET /api/coupons/:id - Get single coupon
router.get('/:id', couponController.getCouponById);

// POST /api/coupons - Create new coupon (authenticated)
router.post('/', authenticateToken, couponController.createCoupon);

// PUT /api/coupons/:id - Update coupon (authenticated)
router.put('/:id', authenticateToken, couponController.updateCoupon);

// DELETE /api/coupons/:id - Delete coupon (authenticated)
router.delete('/:id', authenticateToken, couponController.deleteCoupon);

module.exports = router;
