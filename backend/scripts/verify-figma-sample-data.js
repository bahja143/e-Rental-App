require('dotenv').config();

const mongoose = require('mongoose');
const db = require('../src/models');
const Conversation = require('../src/models/Conversation');
const Message = require('../src/models/Message');

async function verifySqlSeed() {
  const checks = {
    users: await db.User.count(),
    listings: await db.Listing.count(),
    locations: await db.Location.count(),
    faqs: await db.Faq.count(),
    notifications: await db.Notification.count(),
    favourites: await db.Favourite.count(),
    reviews: await db.ListingReview.count(),
    recentSearches: await db.RecentSearch.count(),
    listingRentals: await db.ListingRental.count(),
    listingBuyings: await db.ListingBuying.count(),
  };

  const minimums = {
    users: 4,
    listings: 7,
    locations: 5,
    faqs: 3,
    notifications: 3,
    favourites: 4,
    reviews: 3,
    recentSearches: 3,
    listingRentals: 1,
    listingBuyings: 1,
  };

  const failed = Object.entries(minimums).filter(([key, min]) => checks[key] < min);
  return { checks, failed };
}

async function verifyMongoSeed() {
  const mongoUri = process.env.MONGO_URI;
  if (!mongoUri) {
    return { skipped: true };
  }

  await mongoose.connect(mongoUri);
  try {
    const conversation = await Conversation.findOne({ listing_id: 'figma-seed-listing-1' }).lean();
    const messageCount = conversation
      ? await Message.countDocuments({ conversation_id: conversation._id })
      : 0;

    const failed = [];
    if (!conversation) failed.push('conversation');
    if (messageCount < 3) failed.push('messages');

    return {
      skipped: false,
      conversationFound: Boolean(conversation),
      messageCount,
      failed,
    };
  } finally {
    await mongoose.disconnect();
  }
}

async function run() {
  try {
    await db.sequelize.authenticate();
    const sql = await verifySqlSeed();
    const mongo = await verifyMongoSeed();

    console.log('Figma sample data verification report');
    console.log(JSON.stringify({ sql: sql.checks, mongo }, null, 2));

    const hasSqlFailure = sql.failed.length > 0;
    const hasMongoFailure = !mongo.skipped && mongo.failed.length > 0;
    if (hasSqlFailure || hasMongoFailure) {
      if (hasSqlFailure) {
        console.error('SQL checks failed:', sql.failed.map(([key]) => key).join(', '));
      }
      if (hasMongoFailure) {
        console.error('Mongo checks failed:', mongo.failed.join(', '));
      }
      process.exitCode = 1;
      return;
    }

    console.log('Verification passed.');
  } catch (error) {
    console.error('Verification failed:', error);
    process.exitCode = 1;
  } finally {
    await db.sequelize.close();
  }
}

run();
