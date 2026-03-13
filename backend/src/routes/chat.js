const express = require('express');
const router = express.Router();
const { upload } = require('../services/mediaService');
const {
  getConversations,
  createConversation,
  sendMessage,
  editMessage,
  addReaction,
  markAsRead,
  getMessages,
  getListingConversationCount,
  getDailyConversationCount,
  getAppSettings
} = require('../controllers/chatController');
const authMiddleware = require('../middleware/authMiddleware');

// Apply auth middleware to all routes
router.use(authMiddleware.authenticateToken);

// Conversations
router.get('/conversations', getConversations);
router.post('/conversations', createConversation);

// Messages
router.post('/messages', upload.single('media'), sendMessage);
router.put('/messages/:id', editMessage);
router.post('/messages/:id/reactions', addReaction);

// Mark as read
router.put('/conversations/:id/read', markAsRead);

// Get messages with pagination
router.get('/conversations/:id/messages', getMessages);

// Listing conversation counts
router.get('/listings/:id/conversation-count', getListingConversationCount);
router.get('/listings/:id/daily-conversation-count', getDailyConversationCount);

// App settings
router.get('/settings', getAppSettings);

module.exports = router;
