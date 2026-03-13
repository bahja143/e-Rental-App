const express = require('express');
const { authenticateToken } = require('../middleware/authMiddleware');
const {
  getFaqs,
  getFaqById,
  createFaq,
  updateFaq,
  deleteFaq,
} = require('../controllers/faqController');

const router = express.Router();

// GET /api/faqs - Get all faqs with pagination, filtering, and sorting
router.get('/', authenticateToken, getFaqs);

// GET /api/faqs/:id - Get single faq
router.get('/:id', authenticateToken, getFaqById);

// POST /api/faqs - Create new faq
router.post('/', authenticateToken, createFaq);

// PUT /api/faqs/:id - Update faq
router.put('/:id', authenticateToken, updateFaq);

// DELETE /api/faqs/:id - Delete faq
router.delete('/:id', authenticateToken, deleteFaq);

module.exports = router;
