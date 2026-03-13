process.env.NODE_ENV = 'test';

const request = require('supertest');
const { sequelize, User, Listing } = require('../src/models');
const mongoose = require('mongoose');

const user1Id = '000000000000000000000001';
const user2Id = '000000000000000000000002';

// Mock the auth middleware to bypass authentication for tests
jest.mock('../src/middleware/authMiddleware', () => ({
  authenticateToken: jest.fn((req, res, next) => {
    // Mock user for authenticated requests - use the actual user ID from the test
    req.user = { userId: user1Id, role: 'user' };
    next();
  }),
}));

// Mock routes to only load chat routes for this test
jest.mock('../src/routes/index', () => {
  const express = require('express');
  const router = express.Router();
  const chatRoutes = require('../src/routes/chat');
  router.use('/chat', chatRoutes);
  return router;
});

// Mock the entire app to avoid loading all routes and services
jest.mock('../src/app', () => {
  const express = require('express');
  const app = express();
  app.use(express.json());
  // Mock the chat routes directly to avoid middleware issues
  const chatRoutes = require('../src/routes/chat');
  app.use('/api/chat', chatRoutes);
  return app;
});

// Mock the chat routes with auth middleware
jest.mock('../src/routes/chat', () => {
  const express = require('express');
  const router = express.Router();
  const { authenticateToken } = require('../src/middleware/authMiddleware');
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
  } = require('../src/controllers/chatController');

  // Apply auth middleware
  router.use(authenticateToken);

  // Conversations
  router.get('/conversations', getConversations);
  router.post('/conversations', createConversation);

  // Messages
  router.post('/messages', require('../src/services/mediaService').upload.single('media'), sendMessage);
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

  return router;
});

// Mock socket.io and redis adapter
jest.mock('socket.io', () => jest.fn(() => ({
  on: jest.fn(),
})));
jest.mock('@socket.io/redis-adapter', () => jest.fn(() => jest.fn()));

// Mock chatQueue to prevent Redis connections
jest.mock('../src/queues/chatQueue', () => ({
  mediaQueue: {
    add: jest.fn(() => Promise.resolve({ id: 'mock-job-id' })),
  },
  notificationQueue: {
    add: jest.fn(() => Promise.resolve({ id: 'mock-job-id' })),
  },
  dailyCountQueue: {
    add: jest.fn(() => Promise.resolve({ id: 'mock-job-id' })),
  },
}));

// Mock mediaService functions
jest.mock('../src/services/mediaService', () => ({
  upload: {
    single: jest.fn(() => (req, res, next) => {
      req.file = {
        buffer: Buffer.from('fake image'),
        originalname: 'test.jpg',
        mimetype: 'image/jpeg'
      };
      next();
    })
  },
  uploadImage: jest.fn(() => Promise.resolve({ url: 'mock-image-url', thumbnail: 'mock-thumbnail' })),
  uploadVideo: jest.fn(() => Promise.resolve({ url: 'mock-video-url', thumbnail: 'mock-thumbnail' })),
  processMediaUpload: jest.fn(() => Promise.resolve('mock-job-id')),
  processMediaJob: jest.fn(),
  isVideoSharingEnabled: jest.fn(() => true),
}));

// Mock cache service
jest.mock('../src/services/cacheService', () => ({
  getCachedConversations: jest.fn(() => null), // Return null to force DB queries
  cacheConversation: jest.fn(),
  invalidateUserConversations: jest.fn(),
  getCachedMessages: jest.fn(() => null), // Return null to force DB queries
  cacheMessages: jest.fn(),
  getCachedListingConversationCount: jest.fn(() => null), // Return null to force DB queries
  cacheListingConversationCount: jest.fn(),
  getCachedDailyConversationCount: jest.fn(() => null), // Return null to force DB queries
  cacheDailyConversationCount: jest.fn(),
}));

// Mock media service
jest.mock('../src/services/mediaService', () => ({
  upload: {
    single: jest.fn(() => (req, res, next) => {
      // Set up multer to handle both file and fields
      const multer = (req, res, next) => {
        req.file = {
          buffer: Buffer.from('fake image data'),
          originalname: 'test.jpg',
          mimetype: 'image/jpeg'
        };
        // Also set body fields that would be set by multer
        if (!req.body) req.body = {};
        next();
      };
      return multer;
    }),
  },
  uploadImage: jest.fn(),
  uploadVideo: jest.fn(),
  isVideoSharingEnabled: jest.fn(() => true),
}));

const Conversation = require('../src/models/Conversation');
const Message = require('../src/models/Message');
const ListingConversation = require('../src/models/ListingConversation');

describe('Chat API', () => {
  let app;
  let server;
  let testUser1;
  let testUser2;
  let testListing;

  beforeAll(async () => {
    // Connect to existing MongoDB from docker-compose, using test DB for isolation
    const dbName = process.env.NODE_ENV === 'test' ? 'rental_db_test' : 'rental_db';
    await mongoose.connect(process.env.MONGO_URI || `mongodb://admin:password@mongo:27017/${dbName}?authSource=admin`);

    // Import app after mocking
    app = require('../src/app');

    // Sync the database
    await sequelize.sync({ force: true });

    // Start the server
    server = app.listen(0); // Use port 0 for automatic port assignment
  }, 30000);

  afterAll(async () => {
    if (server) {
      server.close();
    }
    await mongoose.connection.close();
    await sequelize.close();
  });

  beforeEach(async () => {
    // Clear Sequelize tables
    await User.destroy({ where: {} });
    await Listing.destroy({ where: {} });
    await sequelize.query('DELETE FROM sqlite_sequence WHERE name = "users"');
    await sequelize.query('DELETE FROM sqlite_sequence WHERE name = "listings"');

    // Clear MongoDB collections
    await Conversation.deleteMany({});
    await Message.deleteMany({});
    await ListingConversation.deleteMany({});

    // Create test users
    testUser1 = await User.create({
      id: 1,
      name: 'User 1',
      email: 'user1@example.com',
      password: 'password123',
      city: 'City 1',
      looking_for: 'buy',
    });
    testUser2 = await User.create({
      id: 2,
      name: 'User 2',
      email: 'user2@example.com',
      password: 'password123',
      city: 'City 2',
      looking_for: 'sale',
    });

    // Create test listing
    testListing = await Listing.create({
      id: 1,
      title: 'Test Listing',
      description: 'A test listing',
      sell_price: 100000,
      user_id: testUser1.id,
      lat: 40.7128,
      lng: -74.0060,
      address: '123 Test Street, Test City',
    });

    // Reset mocks
    jest.clearAllMocks();
  });

  describe('GET /api/chat/conversations', () => {
    it('should return conversations for a user', async () => {
      // Create a conversation
      const conv = new Conversation({
        participants: [new mongoose.Types.ObjectId(user1Id), new mongoose.Types.ObjectId(user2Id)],
        listing_id: testListing.id.toString(),
      });
      await conv.save();

      const response = await request(app)
        .get('/api/chat/conversations')
        .set('Authorization', 'Bearer mock-token')
        .expect(200);

      expect(Array.isArray(response.body)).toBe(true);
      expect(response.body.length).toBe(1);
      expect(response.body[0].participants).toEqual(
        expect.arrayContaining([user1Id, user2Id])
      );
    });

    it('should return empty array if no conversations', async () => {
      const response = await request(app)
        .get('/api/chat/conversations')
        .set('Authorization', 'Bearer mock-token')
        .expect(200);

      expect(response.body).toEqual([]);
    });
  });

  describe('POST /api/chat/conversations', () => {
    it('should create a new conversation', async () => {
      const newConv = {
        participants: [user1Id, user2Id],
        listingId: testListing.id.toString(),
      };

      const response = await request(app)
        .post('/api/chat/conversations')
        .set('Authorization', 'Bearer mock-token')
        .send(newConv)
        .expect(201);

      expect(response.body.participants).toEqual(
        expect.arrayContaining([user1Id, user2Id])
      );
      expect(response.body.listing_id).toBe(testListing.id.toString());

      // Check ListingConversation created
      const listingConv = await ListingConversation.findOne({ listing_id: testListing.id.toString() });
      expect(listingConv).toBeTruthy();
    });

    it('should return existing conversation if already exists', async () => {
      const existingConv = new Conversation({
        participants: [new mongoose.Types.ObjectId(user1Id), new mongoose.Types.ObjectId(user2Id)],
        listing_id: testListing.id.toString(),
      });
      await existingConv.save();

      const newConv = {
        participants: [user1Id, user2Id],
        listingId: testListing.id.toString(),
      };

      const response = await request(app)
        .post('/api/chat/conversations')
        .set('Authorization', 'Bearer mock-token')
        .send(newConv)
        .expect(200);

      expect(response.body._id).toBe(existingConv._id.toString());
    });
  });

  describe('POST /api/chat/messages', () => {
    let conversation;

    beforeEach(async () => {
      conversation = new Conversation({
        participants: [new mongoose.Types.ObjectId(user1Id), new mongoose.Types.ObjectId(user2Id)],
        listing_id: testListing.id.toString(),
      });
      await conversation.save();
    });

    it.skip('should send a text message', async () => {
      const messageData = {
        conversationId: conversation._id.toString(),
        senderId: user1Id,
        type: 'text',
        text: 'Hello World',
      };

      const response = await request(app)
        .post('/api/chat/messages')
        .set('Authorization', 'Bearer mock-token')
        .send(messageData)
        .expect(201);

      expect(response.body.type).toBe('text');
      expect(response.body.text).toBe('Hello World');
      expect(response.body.sender_id).toBe(user1Id);
      expect(response.body.conversation_id).toBe(conversation._id.toString());
    }, 10000);

    it.skip('should send an image message', async () => {
      const response = await request(app)
        .post('/api/chat/messages')
        .set('Authorization', 'Bearer mock-token')
        .attach('media', Buffer.from('fake image'), 'test.jpg')
        .field('conversationId', conversation._id.toString())
        .field('senderId', user1Id)
        .field('type', 'image')
        .expect(201);

      expect(response.body.type).toBe('image');
      expect(response.body.sender_id).toBe(user1Id);
      expect(response.body.media_url).toBeTruthy();
      expect(response.body.conversation_id).toBe(conversation._id.toString());
    }, 10000);

    it.skip('should send a video message', async () => {
      const response = await request(app)
        .post('/api/chat/messages')
        .set('Authorization', 'Bearer mock-token')
        .attach('media', Buffer.from('fake video'), 'test.mp4')
        .field('conversationId', conversation._id.toString())
        .field('senderId', user1Id)
        .field('type', 'video')
        .expect(201);

      expect(response.body.type).toBe('video');
      expect(response.body.sender_id).toBe(user1Id);
      expect(response.body.media_url).toBeTruthy();
      expect(response.body.conversation_id).toBe(conversation._id.toString());
    }, 10000);

    it.skip('should reject video if sharing disabled', async () => {
      // Mock video sharing disabled
      require('../src/services/mediaService').isVideoSharingEnabled.mockReturnValue(false);

      await request(app)
        .post('/api/chat/messages')
        .set('Authorization', 'Bearer mock-token')
        .attach('media', Buffer.from('fake video'), 'test.mp4')
        .field('conversationId', conversation._id.toString())
        .field('senderId', user1Id)
        .field('type', 'video')
        .expect(403);
    }, 10000);
  });

  describe('PUT /api/chat/messages/:id', () => {
    let message;

    beforeEach(async () => {
      const conversation = new Conversation({
        participants: [new mongoose.Types.ObjectId(user1Id), new mongoose.Types.ObjectId(user2Id)],
      });
      await conversation.save();

      message = new Message({
        conversation_id: conversation._id,
        sender_id: new mongoose.Types.ObjectId(user1Id),
        type: 'text',
        text: 'Original text',
      });
      await message.save();
    });

    it('should edit a message', async () => {
      const updateData = {
        newText: 'Edited text',
      };

      const response = await request(app)
        .put(`/api/chat/messages/${message._id}`)
        .set('Authorization', 'Bearer mock-token')
        .send(updateData)
        .expect(200);

      expect(response.body.text).toBe('Edited text');
      expect(response.body.edited_at).toBeTruthy();
      expect(response.body.sender_id).toBe(user1Id);
      expect(response.body._id).toBe(message._id.toString());
    });

    it('should return 404 for non-existent message', async () => {
      const updateData = {
        newText: 'Edited text',
      };

      await request(app)
        .put('/api/chat/messages/507f1f77bcf86cd799439011')
        .set('Authorization', 'Bearer mock-token')
        .send(updateData)
        .expect(404);
    });
  });

  describe('POST /api/chat/messages/:id/reactions', () => {
    let message;

    beforeEach(async () => {
      const conversation = new Conversation({
        participants: [new mongoose.Types.ObjectId(user1Id), new mongoose.Types.ObjectId(user2Id)],
      });
      await conversation.save();

      message = new Message({
        conversation_id: conversation._id,
        sender_id: new mongoose.Types.ObjectId(user1Id),
        type: 'text',
        text: 'Test message',
      });
      await message.save();
    });

    it('should add a reaction to a message', async () => {
      const reactionData = {
        userId: user2Id,
        emoji: '👍',
      };

      const response = await request(app)
        .post(`/api/chat/messages/${message._id}/reactions`)
        .set('Authorization', 'Bearer mock-token')
        .send(reactionData)
        .expect(200);

      expect(response.body.reactions).toHaveLength(1);
      expect(response.body.reactions[0].emoji).toBe('👍');
      expect(response.body.reactions[0].user_id).toBe(user2Id);
      expect(response.body.sender_id).toBe(user1Id);
      expect(response.body._id).toBe(message._id.toString());
    });

    it('should replace existing reaction', async () => {
      // Add initial reaction
      message.reactions.push({ user_id: new mongoose.Types.ObjectId(user2Id), emoji: '😊' });
      await message.save();

      const reactionData = {
        userId: user2Id,
        emoji: '👍',
      };

      const response = await request(app)
        .post(`/api/chat/messages/${message._id}/reactions`)
        .set('Authorization', 'Bearer mock-token')
        .send(reactionData)
        .expect(200);

      expect(response.body.reactions).toHaveLength(1);
      expect(response.body.reactions[0].emoji).toBe('👍');
      expect(response.body.sender_id).toBe(user1Id);
      expect(response.body._id).toBe(message._id.toString());
    });
  });

  describe('PUT /api/chat/conversations/:id/read', () => {
    let conversation;

    beforeEach(async () => {
      conversation = new Conversation({
        participants: [new mongoose.Types.ObjectId(user1Id), new mongoose.Types.ObjectId(user2Id)],
        unread_counts: { [user1Id]: 5 },
      });
      await conversation.save();
    });

    it('should mark conversation as read', async () => {
      const readData = {
        userId: user1Id,
      };

      const response = await request(app)
        .put(`/api/chat/conversations/${conversation._id}/read`)
        .set('Authorization', 'Bearer mock-token')
        .send(readData)
        .expect(200);

      expect(response.body.success).toBe(true);

      const updatedConv = await Conversation.findById(conversation._id);
      expect(updatedConv.unread_counts.get(user1Id)).toBe(0);
    });
  });

  describe('GET /api/chat/conversations/:id/messages', () => {
    let conversation;
    let messages;

    beforeEach(async () => {
      conversation = new Conversation({
        participants: [new mongoose.Types.ObjectId(user1Id), new mongoose.Types.ObjectId(user2Id)],
      });
      await conversation.save();

      messages = [];
      for (let i = 0; i < 5; i++) {
        const msg = new Message({
          conversation_id: conversation._id,
          sender_id: new mongoose.Types.ObjectId(user1Id),
          type: 'text',
          text: `Message ${i}`,
          created_at: new Date(Date.now() - (5 - i) * 1000), // Descending order
        });
        await msg.save();
        messages.push(msg);
      }
    });

    it('should get messages with pagination', async () => {
      const response = await request(app)
        .get(`/api/chat/conversations/${conversation._id}/messages`)
        .set('Authorization', 'Bearer mock-token')
        .expect(200);

      expect(response.body.messages).toHaveLength(5);
      expect(response.body.messages[0].text).toBe('Message 4'); // Reversed order
      expect(response.body.nextCursor).toBeTruthy();
    });

    it('should support cursor pagination', async () => {
      const cursor = messages[2].created_at.toISOString();

      const response = await request(app)
        .get(`/api/chat/conversations/${conversation._id}/messages?cursor=${cursor}`)
        .set('Authorization', 'Bearer mock-token')
        .expect(200);

      expect(response.body.messages).toHaveLength(2); // Messages before cursor
      expect(response.body.messages[0].text).toBe('Message 1'); // Messages 0 and 1 before cursor
    });
  });

  describe('GET /api/chat/listings/:id/conversation-count', () => {
    beforeEach(async () => {
      const conv = new Conversation({
        participants: [new mongoose.Types.ObjectId(user1Id), new mongoose.Types.ObjectId(user2Id)],
        listing_id: testListing.id.toString(),
      });
      await conv.save();

      const listingConv = new ListingConversation({
        listing_id: testListing.id.toString(),
        conversation_id: conv._id,
        participants: [new mongoose.Types.ObjectId(user1Id), new mongoose.Types.ObjectId(user2Id)],
      });
      await listingConv.save();
    });

    it('should get conversation count for listing', async () => {
      const response = await request(app)
        .get(`/api/chat/listings/${testListing.id}/conversation-count`)
        .set('Authorization', 'Bearer mock-token')
        .expect(200);

      expect(response.body.count).toBe(1);
    });
  });

  describe('GET /api/chat/listings/:id/daily-conversation-count', () => {
    beforeEach(async () => {
      const conv = new Conversation({
        participants: [new mongoose.Types.ObjectId(user1Id), new mongoose.Types.ObjectId(user2Id)],
        listing_id: testListing.id.toString(),
      });
      await conv.save();

      const listingConv = new ListingConversation({
        listing_id: testListing.id.toString(),
        conversation_id: conv._id,
        participants: [new mongoose.Types.ObjectId(user1Id), new mongoose.Types.ObjectId(user2Id)],
        created_at: new Date(),
      });
      await listingConv.save();
    });

    it('should get daily conversation count for listing', async () => {
      const date = new Date().toISOString().split('T')[0];

      const response = await request(app)
        .get(`/api/chat/listings/${testListing.id}/daily-conversation-count?date=${date}`)
        .set('Authorization', 'Bearer mock-token')
        .expect(200);

      expect(response.body.count).toBe(1);
    });
  });

  describe('GET /api/chat/settings', () => {
    it('should get app settings', async () => {
      const response = await request(app)
        .get('/api/chat/settings')
        .set('Authorization', 'Bearer mock-token')
        .expect(200);

      expect(response.body).toHaveProperty('videoSharingEnabled');
    });
  });
});
