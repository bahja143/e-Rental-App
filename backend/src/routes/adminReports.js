const express = require('express');
const router = express.Router();

const { authenticateToken } = require('../middleware/authMiddleware');
const { requireAdmin, getAdminOverview } = require('../controllers/adminReportsController');

router.get('/overview', authenticateToken, requireAdmin, getAdminOverview);

module.exports = router;
