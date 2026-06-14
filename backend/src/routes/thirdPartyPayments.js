const express = require('express');
const { authenticateToken } = require('../middleware/authMiddleware');
const {
  requireAdmin,
  initiateWaafiListingRentalPayment,
  getThirdPartyPayments,
} = require('../controllers/thirdPartyPaymentController');

const router = express.Router();

router.post('/waafi/listing-rentals', authenticateToken, initiateWaafiListingRentalPayment);
router.get('/', authenticateToken, requireAdmin, getThirdPartyPayments);

module.exports = router;
