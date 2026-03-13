process.env.NODE_ENV = 'test';

const request = require('supertest');
const { sequelize, ListingBuying, User, Listing, Coupon } = require('../src/models');

// Mock the auth middleware to bypass authentication for tests
jest.mock('../src/middleware/authMiddleware', () => ({
  authenticateToken: (req, res, next) => {
    // Mock user for authenticated requests
    req.user = { id: 1, role: 'admin' };
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

describe('Listing Buyings API', () => {
  let app;
  let server;
  let testUser;
  let testListing;
  let testCoupon;

  beforeAll(async () => {
    // Import app after mocking
    app = require('../src/app');

    // Sync the in-memory database
    await sequelize.sync({ force: true });

    // Create a test user
    testUser = await User.create({
      name: 'Test Buyer',
      email: 'buyer@example.com',
      password: 'password123',
      available_balance: 10000,
      pending_balance: 0,
    });

    // Create a test listing
    testListing = await Listing.create({
      user_id: testUser.id,
      title: 'Test Property for Sale',
      address: '123 Test Street',
      lat: 40.7128,
      lng: -74.0060,
      sell_price: 500000,
      description: 'A beautiful test property',
    });

    // Create a test coupon
    testCoupon = await Coupon.create({
      code: 'TEST10',
      type: 'percentage',
      value: 10.00,
      use_case: 'listing_buy',
      is_active: true,
    });

    // Start the server
    server = app.listen(0);
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
    await ListingBuying.destroy({ where: {} });
    // Reset SQLite auto-increment sequence
    await sequelize.query('DELETE FROM sqlite_sequence WHERE name = "listing_buyings"');
  });

  describe('GET /api/listing-buyings', () => {
    it('should return empty array when no listing buyings exist', async () => {
      const response = await request(app)
        .get('/api/listing-buyings')
        .expect(200);

      expect(response.body).toHaveProperty('data');
      expect(response.body).toHaveProperty('pagination');
      expect(response.body.data).toHaveLength(0);
      expect(response.body.pagination.totalItems).toBe(0);
    });

    it('should return listing buyings with related data', async () => {
      const listingBuying = await ListingBuying.create({
        listing_id: testListing.id,
        buyer_id: testUser.id,
        subtotal: 500000.00,
        discount: 50000.00,
        total: 450000.00,
        status: 'pending',
        commission: 45000.00,
        sellers_value: 405000.00,
      });

      const response = await request(app)
        .get('/api/listing-buyings')
        .expect(200);

      expect(response.body.data).toHaveLength(1);
      expect(response.body.data[0]).toHaveProperty('id', listingBuying.id);
      expect(response.body.data[0]).toHaveProperty('buyer');
      expect(response.body.data[0]).toHaveProperty('listing');
      expect(response.body.data[0].buyer).toHaveProperty('name', 'Test Buyer');
      expect(response.body.data[0].listing).toHaveProperty('title', 'Test Property for Sale');
    });

    it('should support pagination', async () => {
      // Create multiple records
      for (let i = 0; i < 25; i++) {
        await ListingBuying.create({
          listing_id: testListing.id,
          buyer_id: testUser.id,
          subtotal: 100000.00 + i * 1000,
          discount: 0.00,
          total: 100000.00 + i * 1000,
          status: 'pending',
          commission: 10000.00,
          sellers_value: 90000.00 + i * 1000,
        });
      }

      const response = await request(app)
        .get('/api/listing-buyings?page=2&limit=10')
        .expect(200);

      expect(response.body.data).toHaveLength(10);
      expect(response.body.pagination.currentPage).toBe(2);
      expect(response.body.pagination.totalPages).toBe(3);
      expect(response.body.pagination.hasNextPage).toBe(true);
      expect(response.body.pagination.hasPrevPage).toBe(true);
    });

    it('should support status filtering', async () => {
      await ListingBuying.create({
        listing_id: testListing.id,
        buyer_id: testUser.id,
        subtotal: 100000.00,
        discount: 0.00,
        total: 100000.00,
        status: 'confirmed',
        commission: 10000.00,
        sellers_value: 90000.00,
      });

      await ListingBuying.create({
        listing_id: testListing.id,
        buyer_id: testUser.id,
        subtotal: 200000.00,
        discount: 0.00,
        total: 200000.00,
        status: 'pending',
        commission: 20000.00,
        sellers_value: 180000.00,
      });

      const response = await request(app)
        .get('/api/listing-buyings?status=confirmed')
        .expect(200);

      expect(response.body.data).toHaveLength(1);
      expect(response.body.data[0].status).toBe('confirmed');
    });

    it('should support buyer_id filtering', async () => {
      const otherUser = await User.create({
        name: 'Other Buyer',
        email: 'other@example.com',
        password: 'password123',
      });

      await ListingBuying.create({
        listing_id: testListing.id,
        buyer_id: testUser.id,
        subtotal: 100000.00,
        discount: 0.00,
        total: 100000.00,
        status: 'pending',
        commission: 10000.00,
        sellers_value: 90000.00,
      });

      await ListingBuying.create({
        listing_id: testListing.id,
        buyer_id: otherUser.id,
        subtotal: 200000.00,
        discount: 0.00,
        total: 200000.00,
        status: 'pending',
        commission: 20000.00,
        sellers_value: 180000.00,
      });

      const response = await request(app)
        .get(`/api/listing-buyings?buyer_id=${testUser.id}`)
        .expect(200);

      expect(response.body.data).toHaveLength(1);
      expect(response.body.data[0].buyer_id).toBe(testUser.id);
    });

    it('should support listing_id filtering', async () => {
      const otherListing = await Listing.create({
        user_id: testUser.id,
        title: 'Other Property',
        address: '456 Other Street',
        lat: 40.7128,
        lng: -74.0060,
        sell_price: 300000,
      });

      await ListingBuying.create({
        listing_id: testListing.id,
        buyer_id: testUser.id,
        subtotal: 500000.00,
        discount: 0.00,
        total: 500000.00,
        status: 'pending',
        commission: 50000.00,
        sellers_value: 450000.00,
      });

      await ListingBuying.create({
        listing_id: otherListing.id,
        buyer_id: testUser.id,
        subtotal: 300000.00,
        discount: 0.00,
        total: 300000.00,
        status: 'pending',
        commission: 30000.00,
        sellers_value: 270000.00,
      });

      const response = await request(app)
        .get(`/api/listing-buyings?listing_id=${testListing.id}`)
        .expect(200);

      expect(response.body.data).toHaveLength(1);
      expect(response.body.data[0].listing_id).toBe(testListing.id);
    });

    it('should handle invalid page number', async () => {
      const response = await request(app)
        .get('/api/listing-buyings?page=invalid')
        .expect(400);

      expect(response.body.error).toBe('Invalid page number');
    });

    it('should handle invalid limit', async () => {
      const response = await request(app)
        .get('/api/listing-buyings?limit=200')
        .expect(400);

      expect(response.body.error).toBe('Invalid limit (1-100)');
    });
  });

  describe('GET /api/listing-buyings/:id', () => {
    let testListingBuying;

    beforeEach(async () => {
      testListingBuying = await ListingBuying.create({
        listing_id: testListing.id,
        buyer_id: testUser.id,
        subtotal: 500000.00,
        discount: 50000.00,
        total: 450000.00,
        status: 'pending',
        commission: 45000.00,
        sellers_value: 405000.00,
        coupon_id: testCoupon.id,
        coupon_code: 'TEST10',
      });
    });

    it('should return a listing buying by ID with related data', async () => {
      const response = await request(app)
        .get(`/api/listing-buyings/${testListingBuying.id}`)
        .expect(200);

      expect(response.body).toHaveProperty('id', testListingBuying.id);
      expect(response.body).toHaveProperty('buyer');
      expect(response.body).toHaveProperty('listing');
      expect(response.body).toHaveProperty('coupon');
      expect(response.body.buyer.name).toBe('Test Buyer');
      expect(response.body.listing.title).toBe('Test Property for Sale');
      expect(response.body.coupon.code).toBe('TEST10');
    });

    it('should return 404 for non-existent listing buying', async () => {
      const response = await request(app)
        .get('/api/listing-buyings/999')
        .expect(404);

      expect(response.body.error).toBe('Listing buying not found');
    });

    it('should handle invalid ID', async () => {
      const response = await request(app)
        .get('/api/listing-buyings/invalid')
        .expect(400);

      expect(response.body.error).toBe('Invalid listing buying ID');
    });
  });

  describe('POST /api/listing-buyings', () => {
    it('should create a new listing buying', async () => {
      const response = await request(app)
        .post('/api/listing-buyings')
        .send({
          listing_id: testListing.id,
          buyer_id: testUser.id,
          subtotal: 500000.00,
          discount: 50000.00,
          total: 450000.00,
          status: 'pending',
          commission: 45000.00,
          sellers_value: 405000.00,
        })
        .expect(201);

      expect(response.body).toHaveProperty('message', 'Listing buying created successfully');
      expect(response.body).toHaveProperty('listingBuying');
      expect(response.body.listingBuying.subtotal).toBe(500000.00);
      expect(response.body.listingBuying.total).toBe(450000.00);
    });

    it('should create listing buying with coupon', async () => {
      const response = await request(app)
        .post('/api/listing-buyings')
        .send({
          listing_id: testListing.id,
          buyer_id: testUser.id,
          subtotal: 500000.00,
          coupon_id: testCoupon.id,
          coupon_code: 'TEST10',
          discount: 50000.00,
          total: 450000.00,
          status: 'pending',
          commission: 45000.00,
          sellers_value: 405000.00,
        })
        .expect(201);

      expect(response.body.listingBuying.coupon_id).toBe(testCoupon.id);
      expect(response.body.listingBuying.coupon_code).toBe('TEST10');
    });

    it('should create listing buying with bank details', async () => {
      const response = await request(app)
        .post('/api/listing-buyings')
        .send({
          listing_id: testListing.id,
          buyer_id: testUser.id,
          subtotal: 500000.00,
          discount: 0.00,
          total: 500000.00,
          status: 'pending',
          commission: 50000.00,
          sellers_value: 450000.00,
          bank_name: 'Test Bank',
          branch: 'Main Branch',
          bank_account: '1234567890',
          account_holder_name: 'Test Buyer',
          swift: 'TESTSWFT',
        })
        .expect(201);

      expect(response.body.listingBuying.bank_name).toBe('Test Bank');
      expect(response.body.listingBuying.swift).toBe('TESTSWFT');
    });

    it('should validate required fields', async () => {
      const response = await request(app)
        .post('/api/listing-buyings')
        .send({})
        .expect(400);

      expect(response.body.error).toBe('Invalid listing ID');
    });

    it('should validate monetary values', async () => {
      const response = await request(app)
        .post('/api/listing-buyings')
        .send({
          listing_id: testListing.id,
          buyer_id: testUser.id,
          subtotal: -100.00,
          discount: 0.00,
          total: -100.00,
          status: 'pending',
          commission: 0.00,
          sellers_value: 0.00,
        })
        .expect(400);

      expect(response.body.error).toBe('Invalid subtotal (must be non-negative number)');
    });

    it('should validate total calculation', async () => {
      const response = await request(app)
        .post('/api/listing-buyings')
        .send({
          listing_id: testListing.id,
          buyer_id: testUser.id,
          subtotal: 500000.00,
          discount: 50000.00,
          total: 500000.00, // Should be 450000.00
          status: 'pending',
          commission: 45000.00,
          sellers_value: 405000.00,
        })
        .expect(400);

      expect(response.body.error).toBe('Total must equal subtotal minus discount');
    });

    it('should validate status enum', async () => {
      const response = await request(app)
        .post('/api/listing-buyings')
        .send({
          listing_id: testListing.id,
          buyer_id: testUser.id,
          subtotal: 500000.00,
          discount: 0.00,
          total: 500000.00,
          status: 'invalid',
          commission: 50000.00,
          sellers_value: 450000.00,
        })
        .expect(400);

      expect(response.body.error).toBe('Invalid status value');
    });

    it('should handle non-existent listing', async () => {
      const response = await request(app)
        .post('/api/listing-buyings')
        .send({
          listing_id: 999,
          buyer_id: testUser.id,
          subtotal: 500000.00,
          discount: 0.00,
          total: 500000.00,
          status: 'pending',
          commission: 50000.00,
          sellers_value: 450000.00,
        })
        .expect(404);

      expect(response.body.error).toBe('Listing not found');
    });

    it('should handle non-existent buyer', async () => {
      const response = await request(app)
        .post('/api/listing-buyings')
        .send({
          listing_id: testListing.id,
          buyer_id: 999,
          subtotal: 500000.00,
          discount: 0.00,
          total: 500000.00,
          status: 'pending',
          commission: 50000.00,
          sellers_value: 450000.00,
        })
        .expect(404);

      expect(response.body.error).toBe('Buyer not found');
    });

    it('should handle non-existent coupon', async () => {
      const response = await request(app)
        .post('/api/listing-buyings')
        .send({
          listing_id: testListing.id,
          buyer_id: testUser.id,
          subtotal: 500000.00,
          coupon_id: 999,
          discount: 0.00,
          total: 500000.00,
          status: 'pending',
          commission: 50000.00,
          sellers_value: 450000.00,
        })
        .expect(404);

      expect(response.body.error).toBe('Coupon not found');
    });
  });

  describe('PUT /api/listing-buyings/:id', () => {
    let testListingBuying;

    beforeEach(async () => {
      testListingBuying = await ListingBuying.create({
        listing_id: testListing.id,
        buyer_id: testUser.id,
        subtotal: 500000.00,
        discount: 0.00,
        total: 500000.00,
        status: 'pending',
        commission: 50000.00,
        sellers_value: 450000.00,
      });
    });

    it('should update a listing buying', async () => {
      const response = await request(app)
        .put(`/api/listing-buyings/${testListingBuying.id}`)
        .send({
          status: 'paid',
          bank_name: 'Updated Bank',
        })
        .expect(200);

      expect(response.body).toHaveProperty('message', 'Listing buying updated successfully');
      expect(response.body.listingBuying.status).toBe('paid');
      expect(response.body.listingBuying.bank_name).toBe('Updated Bank');
    });

    it('should validate status on update', async () => {
      const response = await request(app)
        .put(`/api/listing-buyings/${testListingBuying.id}`)
        .send({ status: 'invalid' })
        .expect(400);

      expect(response.body.error).toBe('Invalid status value');
    });

    it('should validate monetary values on update', async () => {
      const response = await request(app)
        .put(`/api/listing-buyings/${testListingBuying.id}`)
        .send({ subtotal: -100.00 })
        .expect(400);

      expect(response.body.error).toBe('Invalid subtotal (must be non-negative number)');
    });

    it('should validate total calculation on update', async () => {
      const response = await request(app)
        .put(`/api/listing-buyings/${testListingBuying.id}`)
        .send({
          subtotal: 600000.00,
          discount: 100000.00,
          total: 600000.00, // Should be 500000.00
        })
        .expect(400);

      expect(response.body.error).toBe('Total must equal subtotal minus discount');
    });

    it('should return 404 for non-existent listing buying', async () => {
      const response = await request(app)
        .put('/api/listing-buyings/999')
        .send({ status: 'paid' })
        .expect(404);

      expect(response.body.error).toBe('Listing buying not found');
    });

    it('should allow setting optional fields to null', async () => {
      // First set some values
      await testListingBuying.update({
        bank_name: 'Test Bank',
        branch: 'Test Branch',
        swift: 'TESTSWFT',
      });

      const response = await request(app)
        .put(`/api/listing-buyings/${testListingBuying.id}`)
        .send({
          bank_name: null,
          branch: null,
          swift: null,
        })
        .expect(200);

      expect(response.body.listingBuying.bank_name).toBeNull();
      expect(response.body.listingBuying.branch).toBeNull();
      expect(response.body.listingBuying.swift).toBeNull();
    });
  });

  describe('DELETE /api/listing-buyings/:id', () => {
    let testListingBuying;

    beforeEach(async () => {
      testListingBuying = await ListingBuying.create({
        listing_id: testListing.id,
        buyer_id: testUser.id,
        subtotal: 500000.00,
        discount: 0.00,
        total: 500000.00,
        status: 'pending',
        commission: 50000.00,
        sellers_value: 450000.00,
      });
    });

    it('should delete a listing buying', async () => {
      const response = await request(app)
        .delete(`/api/listing-buyings/${testListingBuying.id}`)
        .expect(200);

      expect(response.body.message).toBe('Listing buying deleted successfully');

      // Verify deletion
      const deleted = await ListingBuying.findByPk(testListingBuying.id);
      expect(deleted).toBeNull();
    });

    it('should return 404 for non-existent listing buying', async () => {
      const response = await request(app)
        .delete('/api/listing-buyings/999')
        .expect(404);

      expect(response.body.error).toBe('Listing buying not found');
    });

    it('should handle invalid ID', async () => {
      const response = await request(app)
        .delete('/api/listing-buyings/invalid')
        .expect(400);

      expect(response.body.error).toBe('Invalid listing buying ID');
    });
  });
});
