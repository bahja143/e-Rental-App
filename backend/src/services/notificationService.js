/**
 * Notification Service
 * Helper to create in-app notifications for users (e.g. rental events).
 */

const { Notification, UserDevice } = require('../models');
const { Op } = require('sequelize');
const firebaseService = require('./firebaseService');

async function sendPushNotificationToUser(userId, title, message, data = {}) {
  const devices = await UserDevice.findAll({
    where: { user_id: userId },
    attributes: ['fcm_token']
  });
  const tokens = devices.map((d) => `${d.fcm_token || ''}`.trim()).filter(Boolean);
  if (tokens.length === 0) {
    return { enabled: false, sentCount: 0, failedCount: 0, invalidTokens: [] };
  }

  const pushResult = await firebaseService.sendPushToTokens(tokens, {
    title,
    body: message,
    data
  });

  if (pushResult.invalidTokens?.length) {
    await UserDevice.destroy({
      where: {
        user_id: userId,
        fcm_token: { [Op.in]: pushResult.invalidTokens }
      }
    });
  }

  return pushResult;
}

/**
 * Create a notification for a user.
 * @param {number} userId - Target user ID
 * @param {string} type - Notification type (e.g. 'rental_request', 'rental_confirmed')
 * @param {string} title - Short title
 * @param {string} message - Body message
 * @param {object} [data] - Optional JSON data (e.g. { rental_id, listing_id })
 * @returns {Promise<Notification>}
 */
async function notifyUser(userId, type, title, message, data = {}) {
  if (!userId) return null;
  const notification = await Notification.create({
    user_id: userId,
    type,
    title,
    message,
    data: data || {},
  });
  try {
    await sendPushNotificationToUser(userId, title, message, {
      ...data,
      type,
      notification_id: notification.id
    });
  } catch (error) {
    // Keep in-app notification creation successful even if push delivery fails.
    console.error('Push notification delivery failed:', error.message);
  }
  return notification;
}

/**
 * Notify listing owner about a new rental request.
 */
async function notifyOwnerRentalRequest(ownerId, renterName, listingTitle, rentalId) {
  return notifyUser(
    ownerId,
    'rental_request',
    'New Rental Request',
    `${renterName} has requested to rent "${listingTitle}"`,
    { rental_id: rentalId, type: 'rental_request' }
  );
}

/**
 * Notify listing owner when rental status changes.
 * (confirmed = owner confirmed it; cancelled = renter cancelled; completed = rental ended)
 */
async function notifyOwnerRentalStatusChange(ownerId, renterName, listingTitle, rentalId, newStatus) {
  const messages = {
    confirmed: `You have confirmed the rental request from ${renterName} for "${listingTitle}".`,
    cancelled: `${renterName} has cancelled their rental for "${listingTitle}".`,
    completed: `The rental for "${listingTitle}" with ${renterName} has been completed.`,
  };
  const titles = {
    confirmed: 'Rental Confirmed',
    cancelled: 'Rental Cancelled',
    completed: 'Rental Completed',
  };
  return notifyUser(
    ownerId,
    `rental_${newStatus}`,
    titles[newStatus] || `Rental ${newStatus}`,
    messages[newStatus] || `Rental status: ${newStatus}`,
    { rental_id: rentalId, renter_name: renterName, listing_title: listingTitle }
  );
}

/**
 * Notify renter when rental status changes.
 */
async function notifyRenterStatusChange(renterId, listingTitle, rentalId, newStatus) {
  const messages = {
    confirmed: `Your rental for "${listingTitle}" has been confirmed by the owner.`,
    cancelled: `Your rental for "${listingTitle}" has been cancelled.`,
    completed: `Your rental for "${listingTitle}" has been completed.`,
  };
  const titles = {
    confirmed: 'Rental Confirmed',
    cancelled: 'Rental Cancelled',
    completed: 'Rental Completed',
  };
  return notifyUser(
    renterId,
    `rental_${newStatus}`,
    titles[newStatus] || `Rental ${newStatus}`,
    messages[newStatus] || `Rental status: ${newStatus}`,
    { rental_id: rentalId, listing_title: listingTitle }
  );
}

module.exports = {
  notifyUser,
  notifyOwnerRentalRequest,
  notifyOwnerRentalStatusChange,
  notifyRenterStatusChange,
  sendPushNotificationToUser,
};
