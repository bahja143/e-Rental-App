const express = require('express');
const { authenticateToken } = require('../middleware/authMiddleware');
const {
  getCompanies,
  getCompanyById,
  createCompany,
  updateCompany,
  deleteCompany,
} = require('../controllers/companyController');

const router = express.Router();

// GET /api/companies - Get all companies with pagination, filtering, and sorting
router.get('/', authenticateToken, getCompanies);

// GET /api/companies/:id - Get single company
router.get('/:id', authenticateToken, getCompanyById);

// POST /api/companies - Create new company
router.post('/', authenticateToken, createCompany);

// PUT /api/companies/:id - Update company
router.put('/:id', authenticateToken, updateCompany);

// DELETE /api/companies/:id - Delete company
router.delete('/:id', authenticateToken, deleteCompany);

module.exports = router;
