const express = require('express');
const router = express.Router();
const recentSearchController = require('../controllers/recentSearchController');

// Routes for recent searches
router.post('/', recentSearchController.createRecentSearch);
router.get('/', recentSearchController.getRecentSearches);
router.get('/:id', recentSearchController.getRecentSearchById);
router.put('/:id', recentSearchController.updateRecentSearch);
router.delete('/:id', recentSearchController.deleteRecentSearch);

module.exports = router;
