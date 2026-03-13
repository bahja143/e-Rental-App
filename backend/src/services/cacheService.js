const { redisClient } = require('../config/database');

// Cache TTL in seconds
const CONVERSATION_TTL = 3600; // 1 hour
const MESSAGE_TTL = 1800; // 30 minutes
const UNREAD_COUNT_TTL = 86400; // 24 hours

class CacheService {
  // Cache conversation data
  async cacheConversation(userId, conversations) {
    const key = `conversations:${userId}`;
    await redisClient.setEx(key, CONVERSATION_TTL, JSON.stringify(conversations));
  }

  // Get cached conversations
  async getCachedConversations(userId) {
    const key = `conversations:${userId}`;
    const data = await redisClient.get(key);
    return data ? JSON.parse(data) : null;
  }

  // Cache messages for a conversation
  async cacheMessages(conversationId, messages, cursor = null) {
    const key = `messages:${conversationId}:${cursor || 'latest'}`;
    await redisClient.setEx(key, MESSAGE_TTL, JSON.stringify(messages));
  }

  // Get cached messages
  async getCachedMessages(conversationId, cursor = null) {
    const key = `messages:${conversationId}:${cursor || 'latest'}`;
    const data = await redisClient.get(key);
    return data ? JSON.parse(data) : null;
  }

  // Cache unread counts
  async cacheUnreadCounts(userId, counts) {
    const key = `unread_counts:${userId}`;
    await redisClient.setEx(key, UNREAD_COUNT_TTL, JSON.stringify(counts));
  }

  // Get cached unread counts
  async getCachedUnreadCounts(userId) {
    const key = `unread_counts:${userId}`;
    const data = await redisClient.get(key);
    return data ? JSON.parse(data) : null;
  }

  // Update unread count in cache
  async updateUnreadCount(userId, conversationId, count) {
    const key = `unread_counts:${userId}`;
    const currentCounts = await this.getCachedUnreadCounts(userId) || {};
    currentCounts[conversationId] = count;
    await this.cacheUnreadCounts(userId, currentCounts);
  }

  // Cache listing conversation count
  async cacheListingConversationCount(listingId, count) {
    const key = `listing_conversation_count:${listingId}`;
    await redisClient.setEx(key, CONVERSATION_TTL, count.toString());
  }

  // Get cached listing conversation count
  async getCachedListingConversationCount(listingId) {
    const key = `listing_conversation_count:${listingId}`;
    const data = await redisClient.get(key);
    return data ? parseInt(data) : null;
  }

  // Invalidate cache for user conversations
  async invalidateUserConversations(userId) {
    const key = `conversations:${userId}`;
    await redisClient.del(key);
  }

  // Invalidate cache for conversation messages
  async invalidateConversationMessages(conversationId) {
    const pattern = `messages:${conversationId}:*`;
    const keys = await redisClient.keys(pattern);
    if (keys.length > 0) {
      await redisClient.del(keys);
    }
  }

  // Invalidate cache for listing conversation count
  async invalidateListingConversationCount(listingId) {
    const key = `listing_conversation_count:${listingId}`;
    await redisClient.del(key);
  }

  // Cache daily conversation count
  async cacheDailyConversationCount(listingId, date, count) {
    const key = `daily_conversation_count:${listingId}:${date}`;
    await redisClient.setEx(key, CONVERSATION_TTL, count.toString());
  }

  // Get cached daily conversation count
  async getCachedDailyConversationCount(listingId, date) {
    const key = `daily_conversation_count:${listingId}:${date}`;
    const data = await redisClient.get(key);
    return data ? parseInt(data) : null;
  }

  // Clear all cache (for maintenance)
  async clearAllCache() {
    await redisClient.flushAll();
  }
}

module.exports = new CacheService();
