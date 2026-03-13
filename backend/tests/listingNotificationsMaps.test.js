process.env.NODE_ENV = 'test';

const request = require('supertest');
const { sequelize, ListingNotificationsMap, Listing, User } = require('../src/models');

// Mock the auth middleware to bypass authentication for tests
jest.mock('../src/middleware/authMiddleware', () => ({
  authenticateToken: (req, res, next) => {
    // Mock user for authenticated requests
    req.user = { id: 1, role: 'user' };
    next();
  }
}));

const mongoose = require('mongoose');
jest.mock('../src/queues', () => ({
  emailQueue: {
    add: jest.fn(),
    close: jest.fn(),
  },
  emailWorker: {
    close: jest.fn(),
  },
}));

describe('ListingNotificationsMaps API', () => {
  let app;
  let server;
  let testUser;
  let testListing;

  beforeAll(async () => {
    // Import app after mocking
    app = require('../src/app');

    // Sync the in-memory database
    await sequelize.sync({ force: true });

    // Create test user and listing
    testUser = await User.create({
      name: 'Test User',
      email: 'test@example.com',
      phone: '+252123456789',
      password: 'hashedpassword',
      city: 'Test City',
      lat: 2.0469,
      lng: 45.3182,
      user_type: 'buyer',
    });

    testListing = await Listing.create({
      user_id: testUser.id,
      title: 'Test Listing',
      address: 'Test Address',
      lat: 2.0469,
      lng: 45.3182,
      sell_price: 100000,
      description: 'Test description',
      availability: '1',
    });

    // Start the server
    server = app.listen(0); // Use port 0 for automatic port assignment
  });

  afterAll(async () => {
    if (server) {
      server.close();
    }
    await sequelize.close();
    await mongoose.connection.close();
  });

  beforeEach(async () => {
    // Clear the table before each test
    await ListingNotificationsMap.destroy({ where: {} });
    // Reset SQLite auto-increment sequence
    await sequelize.query('DELETE FROM sqlite_sequence WHERE name = "listing_notifications_maps"');
  });

  describe('GET /api/listing-notifications-maps', () => {
    it('should return empty array when no listing notifications maps exist', async () => {
      const response = await request(app)
        .get('/api/listing-notifications-maps')
        .expect(200);

      expect(response.body).toHaveProperty('data');
      expect(response.body).toHaveProperty('pagination');
      expect(response.body.data).toHaveLength(0);
      expect(response.body.pagination.totalItems).toBe(0);
    });

    it('should return listing notifications maps with default pagination', async () => {
      // Create test maps
      const maps = [];
      for (let i = 1; i <= 15; i++) {
        maps.push({
          listing_id: testListing.id,
          user_id: testUser.id,
          sent_at: new Date(Date.now() - i * 3600000), // Different times
        });
      }
      await ListingNotificationsMap.bulkCreate(maps);

      const response = await request(app)
        .get('/api/listing-notifications-maps')
        .expect(200);

      expect(response.body.data).toHaveLength(10); // Default limit
      expect(response.body.pagination.totalItems).toBe(15);
      expect(response.body.pagination.totalPages).toBe(2);
      expect(response.body.pagination.hasNextPage).toBe(true);
      expect(response.body.pagination.hasPrevPage).toBe(false);
    });

    it('should support pagination', async () => {
      // Create test maps
      const maps = [];
      for (let i = 1; i <= 25; i++) {
        maps.push({
          listing_id: testListing.id,
          user_id: testUser.id,
          sent_at: new Date(),
        });
      }
      await ListingNotificationsMap.bulkCreate(maps);

      const response = await request(app)
        .get('/api/listing-notifications-maps?page=2&limit=10')
        .expect(200);

      expect(response.body.data).toHaveLength(10);
      expect(response.body.pagination.currentPage).toBe(2);
      expect(response.body.pagination.totalItems).toBe(25);
      expect(response.body.pagination.totalPages).toBe(3);
      expect(response.body.pagination.hasNextPage).toBe(true);
      expect(response.body.pagination.hasPrevPage).toBe(true);
    });

    it('should filter by listing_id', async () => {
      // Create another listing
      const anotherListing = await Listing.create({
        user_id: testUser.id,
        title: 'Another Listing',
        address: 'Another Address',
        lat: 2.0469,
        lng: 45.3182,
        sell_price: 200000,
        description: 'Another description',
        availability: '1',
      });

      await ListingNotificationsMap.create({
        listing_id: testListing.id,
        user_id: testUser.id,
        sent_at: new Date(),
      });

      await ListingNotificationsMap.create({
        listing_id: anotherListing.id,
        user_id: testUser.id,
        sent_at: new Date(),
      });

      const response = await request(app)
        .get(`/api/listing-notifications-maps?listing_id=${testListing.id}`)
        .expect(200);

      expect(response.body.data).toHaveLength(1);
      expect(response.body.data[0].listing_id).toBe(testListing.id);
    });

    it('should filter by user_id', async () => {
      // Create another user
      const anotherUser = await User.create({
        name: 'Another User',
        email: 'another@example.com',
        phone: '+252987654321',
        password: 'hashedpassword',
        city: 'Another City',
        lat: 2.0469,
        lng: 45.3182,
        user_type: 'seller',
      });

      await ListingNotificationsMap.create({
        listing_id: testListing.id,
        user_id: testUser.id,
        sent_at: new Date(),
      });

      await ListingNotificationsMap.create({
        listing_id: testListing.id,
        user_id: anotherUser.id,
        sent_at: new Date(),
      });

      const response = await request(app)
        .get(`/api/listing-notifications-maps?user_id=${testUser.id}`)
        .expect(200);

      expect(response.body.data).toHaveLength(1);
      expect(response.body.data[0].user_id).toBe(testUser.id);
    });

    it('should filter by sent_at date range', async () => {
      const now = new Date();
      const yesterday = new Date(now.getTime() - 24 * 60 * 60 * 1000);
      const tomorrow = new Date(now.getTime() + 24 * 60 * 60 * 1000);

      await ListingNotificationsMap.create({
        listing_id: testListing.id,
        user_id: testUser.id,
        sent_at: yesterday,
      });

      await ListingNotificationsMap.create({
        listing_id: testListing.id,
        user_id: testUser.id,
        sent_at: now,
      });

      await ListingNotificationsMap.create({
        listing_id: testListing.id,
        user_id: testUser.id,
        sent_at: tomorrow,
      });

      const response = await request(app)
        .get(`/api/listing-notifications-maps?sent_at_from=${yesterday.toISOString()}&sent_at_to=${now.toISOString()}`)
        .expect(200);

      expect(response.body.data).toHaveLength(2);
    });

    it('should sort by sent_at DESC by default', async () => {
      const now = new Date();
      await ListingNotificationsMap.create({
        listing_id: testListing.id,
        user_id: testUser.id,
        sent_at: new Date(now.getTime() - 3600000), // 1 hour ago
      });

      await ListingNotificationsMap.create({
        listing_id: testListing.id,
        user_id: testUser.id,
        sent_at: now,
      });

      const response = await request(app)
        .get('/api/listing-notifications-maps')
        .expect(200);

      expect(response.body.data).toHaveLength(2);
      expect(new Date(response.body.data[0].sent_at).getTime()).toBeGreaterThan(new Date(response.body.data[1].sent_at).getTime());
    });

    it('should handle invalid page number', async () => {
      const response = await request(app)
        .get('/api/listing-notifications-maps?page=invalid')
        .expect(400);

      expect(response.body.error).toBe('Invalid page number');
    });

    it('should handle invalid limit', async () => {
      const response = await request(app)
        .get('/api/listing-notifications-maps?limit=200')
        .expect(400);

      expect(response.body.error).toBe('Invalid limit (1-100)');
    });
  });

  describe('GET /api/listing-notifications-maps/:id', () => {
    let testMap;

    beforeEach(async () => {
      testMap = await ListingNotificationsMap.create({
        listing_id: testListing.id,
        user_id: testUser.id,
        sent_at: new Date(),
      });
    });

    it('should return a listing notifications map by ID', async () => {
      const response = await request(app)
        .get(`/api/listing-notifications-maps/${testMap.id}`)
        .expect(200);

      expect(response.body.id).toBe(testMap.id);
      expect(response.body.listing_id).toBe(testListing.id);
      expect(response.body.user_id).toBe(testUser.id);
      expect(response.body.listing).toBeDefined();
      expect(response.body.user).toBeDefined();
    });

    it('should return 404 for non-existent map', async () => {
      const response = await request(app)
        .get('/api/listing-notifications-maps/999')
        .expect(404);

      expect(response.body.error).toBe('Listing notifications map not found');
    });

    it('should handle invalid ID', async () => {
      const response = await request(app)
        .get('/api/listing-notifications-maps/invalid')
        .expect(400);

      expect(response.body.error).toBe('Invalid map ID');
    });
  });

  describe('POST /api/listing-notifications-maps', () => {
    it('should create a new listing notifications map', async () => {
      const sentAt = new Date();
      const response = await request(app)
        .post('/api/listing-notifications-maps')
        .send({
          listing_id: testListing.id,
          user_id: testUser.id,
          sent_at: sentAt.toISOString(),
        })
        .expect(201);

      expect(response.body.message).toBe('Listing notifications map created successfully');
      expect(response.body.listingNotificationsMap.listing_id).toBe(testListing.id);
      expect(response.body.listingNotificationsMap.user_id).toBe(testUser.id);
      expect(response.body.listingNotificationsMap.listing).toBeDefined();
      expect(response.body.listingNotificationsMap.user).toBeDefined();
    });

    it('should create map with default sent_at if not provided', async () => {
      const response = await request(app)
        .post('/api/listing-notifications-maps')
        .send({
          listing_id: testListing.id,
          user_id: testUser.id,
        })
        .expect(201);

      expect(response.body.listingNotificationsMap.sent_at).toBeDefined();
    });

    it('should validate required fields', async () => {
      const response = await request(app)
        .post('/api/listing-notifications-maps')
        .send({})
        .expect(400);

      expect(response.body.error).toBe('listing_id and user_id are required');
    });

    it('should validate listing_id', async () => {
      const response = await request(app)
        .post('/api/listing-notifications-maps')
        .send({
          listing_id: 'invalid',
          user_id: testUser.id,
        })
        .expect(400);

      expect(response.body.error).toBe('Invalid listing_id');
    });

    it('should validate user_id', async () => {
      const response = await request(app)
        .post('/api/listing-notifications-maps')
        .send({
          listing_id: testListing.id,
          user_id: 'invalid',
        })
        .expect(400);

      expect(response.body.error).toBe('Invalid user_id');
    });

    it('should validate sent_at date', async () => {
      const response = await request(app)
        .post('/api/listing-notifications-maps')
        .send({
          listing_id: testListing.id,
          user_id: testUser.id,
          sent_at: 'invalid-date',
        })
        .expect(400);

      expect(response.body.error).toBe('Invalid sent_at date');
    });

    it('should return 404 for non-existent listing', async () => {
      const response = await request(app)
        .post('/api/listing-notifications-maps')
        .send({
          listing_id: 999,
          user_id: testUser.id,
        })
        .expect(404);

      expect(response.body.error).toBe('Listing not found');
    });

    it('should return 404 for non-existent user', async () => {
      const response = await request(app)
        .post('/api/listing-notifications-maps')
        .send({
          listing_id: testListing.id,
          user_id: 999,
        })
        .expect(404);

      expect(response.body.error).toBe('User not found');
    });

    it('should prevent duplicate listing-user mappings', async () => {
      await ListingNotificationsMap.create({
        listing_id: testListing.id,
        user_id: testUser.id,
        sent_at: new Date(),
      });

      const response = await request(app)
        .post('/api/listing-notifications-maps')
        .send({
          listing_id: testListing.id,
          user_id: testUser.id,
        })
        .expect(409);

      expect(response.body.error).toBe('Notification mapping already exists for this listing and user');
    });
  });

  describe('PUT /api/listing-notifications-maps/:id', () => {
    let testMap;

    beforeEach(async () => {
      testMap = await ListingNotificationsMap.create({
        listing_id: testListing.id,
        user_id: testUser.id,
        sent_at: new Date(),
      });
    });

    it('should update a listing notifications map', async () => {
      const newSentAt = new Date(Date.now() + 3600000); // 1 hour from now
      const response = await request(app)
        .put(`/api/listing-notifications-maps/${testMap.id}`)
        .send({
          sent_at: newSentAt.toISOString(),
        })
        .expect(200);

      expect(response.body.message).toBe('Listing notifications map updated successfully');
      expect(new Date(response.body.listingNotificationsMap.sent_at).getTime()).toBe(newSentAt.getTime());
    });

    it('should return 404 for non-existent map', async () => {
      const response = await request(app)
        .put('/api/listing-notifications-maps/999')
        .send({
          sent_at: new Date().toISOString(),
        })
        .expect(404);

      expect(response.body.error).toBe('Listing notifications map not found');
    });

    it('should validate sent_at date on update', async () => {
      const response = await request(app)
        .put(`/api/listing-notifications-maps/${testMap.id}`)
        .send({
          sent_at: 'invalid-date',
        })
        .expect(400);

      expect(response.body.error).toBe('Invalid sent_at date');
    });

    it('should handle no fields to update', async () => {
      const response = await request(app)
        .put(`/api/listing-notifications-maps/${testMap.id}`)
        .send({})
        .expect(400);

      expect(response.body.error).toBe('No valid fields to update');
    });
  });

  describe('DELETE /api/listing-notifications-maps/:id', () => {
    let testMap;

    beforeEach(async () => {
      testMap = await ListingNotificationsMap.create({
        listing_id: testListing.id,
        user_id: testUser.id,
        sent_at: new Date(),
      });
    });

    it('should delete a listing notifications map', async () => {
      const response = await request(app)
        .delete(`/api/listing-notifications-maps/${testMap.id}`)
        .expect(200);

      expect(response.body.message).toBe('Listing notifications map deleted successfully');

      // Verify deletion
      const deleted = await ListingNotificationsMap.findByPk(testMap.id);
      expect(deleted).toBeNull();
    });

    it('should return 404 for non-existent map', async () => {
      const response = await request(app)
        .delete('/api/listing-notifications-maps/999')
        .expect(404);

      expect(response.body.error).toBe('Listing notifications map not found');
    });

    it('should handle invalid ID', async () => {
      const response = await request(app)
        .delete('/api/listing-notifications-maps/invalid')
        .expect(400);

      expect(response.body.error).toBe('Invalid map ID');
    });
  });
});
