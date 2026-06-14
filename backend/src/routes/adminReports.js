const express = require('express');
const router = express.Router();

const { authenticateToken } = require('../middleware/authMiddleware');
const { requireAdmin, getAdminOverview } = require('../controllers/adminReportsController');
const { getThirdPartyPayments } = require('../controllers/thirdPartyPaymentController');

router.get('/overview', authenticateToken, requireAdmin, getAdminOverview);
router.get('/third-party-payments', authenticateToken, requireAdmin, getThirdPartyPayments);

module.exports = router;
