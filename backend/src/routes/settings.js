const express = require('express');
const { authenticateToken } = require('../middleware/authMiddleware');
const { getSettings, updateSettings, requireAdmin } = require('../controllers/settingsController');

const router = express.Router();

router.get('/', authenticateToken, getSettings);
router.patch('/', authenticateToken, requireAdmin, updateSettings);

module.exports = router;
