const { Queue, Worker } = require('bullmq');
const { redisClient } = require('../config/database');
const mediaService = require('../services/mediaService');

// Create queues only if not in test environment
let mediaQueue, notificationQueue, dailyCountQueue;
if (process.env.NODE_ENV !== 'test') {
  mediaQueue = new Queue('media-processing', {
    connection: redisClient,
    defaultJobOptions: {
      removeOnComplete: 50,
      removeOnFail: 5,
    },
  });

  notificationQueue = new Queue('chat-notifications', {
    connection: redisClient,
    defaultJobOptions: {
      removeOnComplete: 100,
      removeOnFail: 10,
    },
  });

  dailyCountQueue = new Queue('daily-counts', {
    connection: redisClient,
    defaultJobOptions: {
      removeOnComplete: 30,
      removeOnFail: 5,
    },
  });
}

// Media processing worker
let mediaWorker;
if (process.env.NODE_ENV !== 'test') {
  mediaWorker = new Worker('media-processing', async (job) => {
    const { file, type, messageId } = job.data;

    try {
      let result;
      if (type === 'image') {
        result = await mediaService.uploadImage(file);
      } else if (type === 'video') {
        result = await mediaService.uploadVideo(file);
      }

      // Update message with media URL
      const Message = require('../models/Message');
      await Message.findByIdAndUpdate(messageId, {
        media_url: result.url,
      });

      return { success: true, url: result.url };
    } catch (error) {
      console.error('Media processing error:', error);
      throw error;
    }
  }, { connection: redisClient });
}

// Notification worker
let notificationWorker;
if (process.env.NODE_ENV !== 'test') {
  notificationWorker = new Worker('chat-notifications', async (job) => {
    const { userId, message, type } = job.data;

    try {
      // Integrate with push notification service (e.g., Firebase, OneSignal)
      // For now, log the notification
      console.log(`Sending ${type} notification to user ${userId}:`, message);

      // TODO: Implement actual push notification sending
      // Example: await sendPushNotification(userId, { title: 'New Message', body: message });

      // You could also send email notifications or in-app notifications here

      return { success: true };
    } catch (error) {
      console.error('Notification error:', error);
      throw error;
    }
  }, { connection: redisClient });
}

// Daily count worker
let dailyCountWorker;
if (process.env.NODE_ENV !== 'test') {
  dailyCountWorker = new Worker('daily-counts', async (job) => {
    const { listingId, date } = job.data;

    try {
      const ListingConversation = require('../models/ListingConversation');
      const cacheService = require('../services/cacheService');

      const startDate = new Date(date);
      startDate.setHours(0, 0, 0, 0);
      const endDate = new Date(date);
      endDate.setHours(23, 59, 59, 999);

      const count = await ListingConversation.countDocuments({
        listing_id: listingId,
        created_at: { $gte: startDate, $lte: endDate }
      });

      // Cache the daily count
      await cacheService.cacheDailyConversationCount(listingId, date, count);

      console.log(`Daily conversation count for listing ${listingId} on ${date}: ${count}`);

      return { count };
    } catch (error) {
      console.error('Daily count error:', error);
      throw error;
    }
  }, { connection: redisClient });
}

// Export queues and workers
module.exports = {
  mediaQueue,
  notificationQueue,
  dailyCountQueue,
  mediaWorker,
  notificationWorker,
  dailyCountWorker,
};
