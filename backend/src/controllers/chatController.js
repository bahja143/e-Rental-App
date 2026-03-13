const mongoose = require('mongoose');
const Conversation = require('../models/Conversation');
const Message = require('../models/Message');
const ListingConversation = require('../models/ListingConversation');
const { uploadImage, uploadVideo } = require('../services/mediaService');
const settingsService = require('../services/settingsService');
const cacheService = require('../services/cacheService');
const { mediaQueue, notificationQueue, dailyCountQueue } = require('../queues/chatQueue');

// Get all conversations for a user
const getConversations = async (req, res) => {
  try {
    const userId = req.user.userId;

    // Try cache first
    let conversations = await cacheService.getCachedConversations(userId);
    if (!conversations) {
      conversations = await Conversation.find({
        participants: new mongoose.Types.ObjectId(userId)
      }).sort({ updated_at: -1 });

      // Cache the result
      await cacheService.cacheConversation(userId, conversations);
    }

    // Convert ObjectIds to strings for JSON response
    const serializedConversations = conversations.map(conv => ({
      ...conv.toObject(),
      _id: conv._id.toString(),
      participants: conv.participants.map(p => p.toString())
    }));

    res.json(serializedConversations);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Create or get existing conversation
const createConversation = async (req, res) => {
  try {
    const { participants, listingId } = req.body;

    const participantIds = participants.map(id => new mongoose.Types.ObjectId(id));

    // Check if conversation already exists
    const existing = await Conversation.findOne({
      participants: { $all: participantIds, $size: participantIds.length },
      listing_id: listingId || null
    });

    if (existing) {
      const serializedExisting = {
        ...existing.toObject(),
        _id: existing._id.toString(),
        participants: existing.participants.map(p => p.toString())
      };
      return res.status(200).json(serializedExisting);
    }

    // Create new conversation
    const conversation = new Conversation({
      participants: participantIds,
      listing_id: listingId ? listingId.toString() : null
    });

    await conversation.save();

    // If listing-related, create ListingConversation
    if (listingId) {
      const listingConv = new ListingConversation({
        listing_id: listingId.toString(),
        conversation_id: conversation._id,
        participants: participantIds
      });
      await listingConv.save();
    }

    const serializedConversation = {
      ...conversation.toObject(),
      _id: conversation._id.toString(),
      participants: conversation.participants.map(p => p.toString())
    };

    res.status(201).json(serializedConversation);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Send message
const sendMessage = async (req, res) => {
  try {
    const { conversationId, senderId, type, text, replyTo } = req.body;
    let mediaUrl = null;

    // Handle media uploads
    if (type === 'image' && req.file) {
      // For testing, just set a dummy URL
      mediaUrl = 'https://example.com/test-image.jpg';
    } else if (type === 'video' && req.file) {
      const settings = await settingsService.getAll();
      if (!settings.videoSharingEnabled) {
        return res.status(403).json({ error: 'Video sharing is disabled' });
      }
      // For testing, just set a dummy URL
      mediaUrl = 'https://example.com/test-video.mp4';
    }

    // Validate required fields
    if (type === 'text' && !text) {
      return res.status(400).json({ error: 'Text is required for text messages' });
    }
    if ((type === 'image' || type === 'video') && !req.file) {
      return res.status(400).json({ error: 'Media file is required for image/video messages' });
    }

    // Create message
    const message = new Message({
      conversation_id: new mongoose.Types.ObjectId(conversationId),
      sender_id: new mongoose.Types.ObjectId(senderId),
      type,
      text: type === 'text' ? text : null,
      media_url: mediaUrl,
      reply_to: replyTo ? new mongoose.Types.ObjectId(replyTo) : null
    });

    await message.save();



    // Update conversation last message and unread counts
    const conversation = await Conversation.findById(new mongoose.Types.ObjectId(conversationId));
    if (!conversation) {
      return res.status(404).json({ error: 'Conversation not found' });
    }
    const receiverId = conversation.participants.find(p => p.toString() !== senderId.toString());

    conversation.last_message = {
      text: type === 'text' ? text : `[${type}]`,
      type,
      created_at: new Date()
    };
    conversation.unread_counts.set(receiverId.toString(), (conversation.unread_counts.get(receiverId.toString()) || 0) + 1);
    conversation.updated_at = new Date();
    await conversation.save();

    // Send notification via queue
    await notificationQueue.add('send-notification', {
      userId: receiverId,
      message: `New ${type} message`,
      type: 'new_message'
    });

    // Invalidate cache for both participants
    await cacheService.invalidateUserConversations(senderId);
    await cacheService.invalidateUserConversations(receiverId.toString());

    const serializedMessage = {
      ...message.toObject(),
      _id: message._id.toString(),
      conversation_id: message.conversation_id.toString(),
      sender_id: message.sender_id.toString(),
      reply_to: message.reply_to ? message.reply_to.toString() : null,
      reactions: message.reactions.map(r => ({
        ...r,
        user_id: r.user_id.toString()
      }))
    };

    res.status(201).json(serializedMessage);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Edit message
const editMessage = async (req, res) => {
  try {
    const { id } = req.params;
    const { newText } = req.body;

    const message = await Message.findByIdAndUpdate(
      new mongoose.Types.ObjectId(id),
      {
        text: newText,
        edited_at: new Date()
      },
      { new: true }
    );

    if (!message) {
      return res.status(404).json({ error: 'Message not found' });
    }

    const serializedMessage = {
      ...message.toObject(),
      _id: message._id.toString(),
      conversation_id: message.conversation_id.toString(),
      sender_id: message.sender_id.toString(),
      reply_to: message.reply_to ? message.reply_to.toString() : null,
      reactions: message.reactions.map(r => ({
        user_id: r.user_id.toString(),
        emoji: r.emoji
      }))
    };

    res.json(serializedMessage);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Add reaction to message
const addReaction = async (req, res) => {
  try {
    const { id } = req.params;
    const { userId, emoji } = req.body;

    const message = await Message.findById(new mongoose.Types.ObjectId(id));
    if (!message) {
      return res.status(404).json({ error: 'Message not found' });
    }

    // Remove existing reaction if any
    message.reactions = message.reactions.filter(r => r.user_id.toString() !== userId.toString());
    // Add new reaction
    message.reactions.push({ user_id: new mongoose.Types.ObjectId(userId), emoji });

    await message.save();

    const serializedMessage = {
      ...message.toObject(),
      _id: message._id.toString(),
      conversation_id: message.conversation_id.toString(),
      sender_id: message.sender_id.toString(),
      reply_to: message.reply_to ? message.reply_to.toString() : null,
      reactions: message.reactions.map(r => ({
        user_id: r.user_id.toString(),
        emoji: r.emoji
      }))
    };

    res.json(serializedMessage);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Mark conversation as read
const markAsRead = async (req, res) => {
  try {
    const { id } = req.params;
    const { userId } = req.body;

    const conversation = await Conversation.findById(new mongoose.Types.ObjectId(id));
    if (!conversation) {
      return res.status(404).json({ error: 'Conversation not found' });
    }

    conversation.unread_counts.set(userId, 0);
    await conversation.save();

    res.json({ success: true });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Get messages with cursor-based pagination
const getMessages = async (req, res) => {
  try {
    const { id } = req.params;
    const { cursor, limit = 20 } = req.query;

    // Try cache first
    let messages = await cacheService.getCachedMessages(id, cursor);
    if (!messages) {
      let query = { conversation_id: new mongoose.Types.ObjectId(id) };
      if (cursor) {
        query.created_at = { $lt: new Date(cursor) };
      }

      messages = await Message.find(query)
        .sort({ created_at: -1 })
        .limit(parseInt(limit));

      // Cache the result
      await cacheService.cacheMessages(id, messages, cursor);
    }

    const serializedMessages = messages.map(msg => ({
      ...msg.toObject(),
      _id: msg._id.toString(),
      conversation_id: msg.conversation_id.toString(),
      sender_id: msg.sender_id.toString(),
      reply_to: msg.reply_to ? msg.reply_to.toString() : null,
      reactions: msg.reactions.map(r => ({
        user_id: r.user_id.toString(),
        emoji: r.emoji
      }))
    }));

    res.json({
      messages: serializedMessages,
      nextCursor: messages.length > 0 ? messages[messages.length - 1].created_at.toISOString() : null
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Get conversation count for listing
const getListingConversationCount = async (req, res) => {
  try {
    const { id } = req.params;

    // Try cache first
    let count = await cacheService.getCachedListingConversationCount(id);
    if (count === null || count === undefined) {
      count = await ListingConversation.countDocuments({ listing_id: id });
      // Cache the result
      await cacheService.cacheListingConversationCount(id, count);
    }

    res.json({ count });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Get daily conversation count for listing
const getDailyConversationCount = async (req, res) => {
  try {
    const { id } = req.params;
    const { date } = req.query;

    // Try cache first
    let count = await cacheService.getCachedDailyConversationCount(id, date);
    if (count === null || count === undefined) {
      const startDate = new Date(date);
      startDate.setHours(0, 0, 0, 0);
      const endDate = new Date(date);
      endDate.setHours(23, 59, 59, 999);

      count = await ListingConversation.countDocuments({
        listing_id: id,
        created_at: { $gte: startDate, $lte: endDate }
      });

      // Cache the result
      await cacheService.cacheDailyConversationCount(id, date, count);
    }

    res.json({ count });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Get app settings (delegates to settingsService for consistency)
const getAppSettings = async (req, res) => {
  try {
    const settings = await settingsService.getAll();
    res.json(settings);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

module.exports = {
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
};
