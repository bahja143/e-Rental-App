const express = require('express');
const { authenticateToken } = require('../middleware/authMiddleware');
const {
  getCompanyEarnings,
  getCompanyEarningById,
  createCompanyEarning,
  updateCompanyEarning,
  deleteCompanyEarning,
  getEarningsSummary,
} = require('../controllers/companyEarningController');

const router = express.Router();

// GET /api/company-earnings - Get all company earnings with pagination, filtering, and sorting
router.get('/', authenticateToken, getCompanyEarnings);

// GET /api/company-earnings/summary - Get earnings summary
router.get('/summary', authenticateToken, getEarningsSummary);

// GET /api/company-earnings/:id - Get single company earning
router.get('/:id', authenticateToken, getCompanyEarningById);

// POST /api/company-earnings - Create new company earning
router.post('/', authenticateToken, createCompanyEarning);

// PUT /api/company-earnings/:id - Update company earning
router.put('/:id', authenticateToken, updateCompanyEarning);

// DELETE /api/company-earnings/:id - Delete company earning
router.delete('/:id', authenticateToken, deleteCompanyEarning);

module.exports = router;
