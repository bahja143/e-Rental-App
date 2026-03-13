process.env.NODE_ENV = 'test';

const request = require('supertest');
const { sequelize, ListingRental, Listing, User, Coupon } = require('../src/models');

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

describe('Listing Rentals API', () => {
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
      name: 'Test User',
      email: 'test@example.com',
      password: 'password123',
      available_balance: 1000,
      pending_balance: 0,
    });

    // Create a test listing
    testListing = await Listing.create({
      user_id: testUser.id,
      title: 'Test Listing',
      address: '123 Test St',
      lat: 40.7128,
      lng: -74.0060,
      rent_price: 100,
      rent_type: 'daily',
      description: 'A test listing',
    });

    // Create a test coupon
    testCoupon = await Coupon.create({
      code: 'TEST10',
      type: 'percentage',
      value: 10.00,
      use_case: 'listing_rent',
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
    await ListingRental.destroy({ where: {} });
    // Reset SQLite auto-increment sequence
    await sequelize.query('DELETE FROM sqlite_sequence WHERE name = "listing_rentals"');
  });

  describe('GET /api/listing-rentals', () => {
    it('should return empty array when no listing rentals exist', async () => {
      const response = await request(app)
        .get('/api/listing-rentals')
        .expect(200);

      expect(response.body).toHaveProperty('data');
      expect(response.body).toHaveProperty('pagination');
      expect(response.body.data).toHaveLength(0);
      expect(response.body.pagination.totalItems).toBe(0);
    });

    it('should return listing rentals with related data', async () => {
      const rental = await ListingRental.create({
        list_id: testListing.id,
        renter_id: testUser.id,
        start_date: new Date('2024-01-01'),
        end_date: new Date('2024-01-05'),
        rent_type: 'daily',
        status: 'pending',
        subtotal: 500.00,
        discount: 0,
        total: 500.00,
        commission: 50.00,
        sellers_value: 450.00,
      });

      const response = await request(app)
        .get('/api/listing-rentals')
        .expect(200);

      expect(response.body.data).toHaveLength(1);
      expect(response.body.data[0].id).toBe(rental.id);
      expect(response.body.data[0].subtotal).toBe(500.00);
      expect(response.body.data[0].status).toBe('pending');
      expect(response.body.data[0].listing).toHaveProperty('id', testListing.id);
      expect(response.body.data[0].listing).toHaveProperty('title', testListing.title);
      expect(response.body.data[0].renter).toHaveProperty('id', testUser.id);
      expect(response.body.data[0].renter).toHaveProperty('name', testUser.name);
    });

    it('should support pagination', async () => {
      // Create multiple rental records
      const rentals = [];
      for (let i = 1; i <= 25; i++) {
        rentals.push({
          list_id: testListing.id,
          renter_id: testUser.id,
          start_date: new Date(`2024-01-${String(i).padStart(2, '0')}`),
          end_date: new Date(`2024-01-${String(i + 1).padStart(2, '0')}`),
          rent_type: 'daily',
          status: 'pending',
          subtotal: 100.00 + i,
          discount: 0,
          total: 100.00 + i,
          commission: 10.00,
          sellers_value: 90.00 + i,
        });
      }
      await ListingRental.bulkCreate(rentals);

      const response = await request(app)
        .get('/api/listing-rentals?page=2&limit=10')
        .expect(200);

      expect(response.body.data).toHaveLength(10);
      expect(response.body.pagination.totalItems).toBe(25);
      expect(response.body.pagination.currentPage).toBe(2);
      expect(response.body.pagination.hasNextPage).toBe(true);
    });

    it('should support status filtering', async () => {
      await ListingRental.create({
        list_id: testListing.id,
        renter_id: testUser.id,
        start_date: new Date('2024-01-01'),
        end_date: new Date('2024-01-05'),
        rent_type: 'daily',
        status: 'confirmed',
        subtotal: 500.00,
        discount: 0,
        total: 500.00,
        commission: 50.00,
        sellers_value: 450.00,
      });
      await ListingRental.create({
        list_id: testListing.id,
        renter_id: testUser.id,
        start_date: new Date('2024-02-01'),
        end_date: new Date('2024-02-05'),
        rent_type: 'daily',
        status: 'cancelled',
        subtotal: 400.00,
        discount: 0,
        total: 400.00,
        commission: 40.00,
        sellers_value: 360.00,
      });

      const response = await request(app)
        .get('/api/listing-rentals?status=confirmed')
        .expect(200);

      expect(response.body.data).toHaveLength(1);
      expect(response.body.data[0].status).toBe('confirmed');
    });

    it('should support rent_type filtering', async () => {
      await ListingRental.create({
        list_id: testListing.id,
        renter_id: testUser.id,
        start_date: new Date('2024-01-01'),
        end_date: new Date('2024-01-05'),
        rent_type: 'monthly',
        status: 'pending',
        subtotal: 1000.00,
        discount: 0,
        total: 1000.00,
        commission: 100.00,
        sellers_value: 900.00,
      });

      const response = await request(app)
        .get('/api/listing-rentals?rent_type=monthly')
        .expect(200);

      expect(response.body.data).toHaveLength(1);
      expect(response.body.data[0].rent_type).toBe('monthly');
    });

    it('should support list_id filtering', async () => {
      const anotherListing = await Listing.create({
        user_id: testUser.id,
        title: 'Another Listing',
        address: '456 Another St',
        lat: 40.7128,
        lng: -74.0060,
        rent_price: 200,
        rent_type: 'daily',
      });

      await ListingRental.create({
        list_id: testListing.id,
        renter_id: testUser.id,
        start_date: new Date('2024-01-01'),
        end_date: new Date('2024-01-05'),
        rent_type: 'daily',
        status: 'pending',
        subtotal: 500.00,
        discount: 0,
        total: 500.00,
        commission: 50.00,
        sellers_value: 450.00,
      });
      await ListingRental.create({
        list_id: anotherListing.id,
        renter_id: testUser.id,
        start_date: new Date('2024-02-01'),
        end_date: new Date('2024-02-05'),
        rent_type: 'daily',
        status: 'pending',
        subtotal: 1000.00,
        discount: 0,
        total: 1000.00,
        commission: 100.00,
        sellers_value: 900.00,
      });

      const response = await request(app)
        .get(`/api/listing-rentals?list_id=${testListing.id}`)
        .expect(200);

      expect(response.body.data).toHaveLength(1);
      expect(response.body.data[0].list_id).toBe(testListing.id);
    });

    it('should support renter_id filtering', async () => {
      const anotherUser = await User.create({
        name: 'Another User',
        email: 'another@example.com',
        password: 'password123',
      });

      await ListingRental.create({
        list_id: testListing.id,
        renter_id: testUser.id,
        start_date: new Date('2024-01-01'),
        end_date: new Date('2024-01-05'),
        rent_type: 'daily',
        status: 'pending',
        subtotal: 500.00,
        discount: 0,
        total: 500.00,
        commission: 50.00,
        sellers_value: 450.00,
      });
      await ListingRental.create({
        list_id: testListing.id,
        renter_id: anotherUser.id,
        start_date: new Date('2024-02-01'),
        end_date: new Date('2024-02-05'),
        rent_type: 'daily',
        status: 'pending',
        subtotal: 400.00,
        discount: 0,
        total: 400.00,
        commission: 40.00,
        sellers_value: 360.00,
      });

      const response = await request(app)
        .get(`/api/listing-rentals?renter_id=${testUser.id}`)
        .expect(200);

      expect(response.body.data).toHaveLength(1);
      expect(response.body.data[0].renter_id).toBe(testUser.id);
    });

    it('should handle invalid page number', async () => {
      const response = await request(app)
        .get('/api/listing-rentals?page=invalid')
        .expect(400);

      expect(response.body.error).toBe('Invalid page number');
    });

    it('should handle invalid limit', async () => {
      const response = await request(app)
        .get('/api/listing-rentals?limit=200')
        .expect(400);

      expect(response.body.error).toBe('Invalid limit (1-100)');
    });
  });

  describe('GET /api/listing-rentals/:id', () => {
    it('should return a listing rental by ID with related data', async () => {
      const rental = await ListingRental.create({
        list_id: testListing.id,
        renter_id: testUser.id,
        start_date: new Date('2024-01-01'),
        end_date: new Date('2024-01-05'),
        rent_type: 'daily',
        status: 'pending',
        subtotal: 500.00,
        discount: 50.00,
        total: 450.00,
        commission: 45.00,
        sellers_value: 405.00,
        coupon_code: 'TEST10',
        coupon_id: testCoupon.id,
      });

      const response = await request(app)
        .get(`/api/listing-rentals/${rental.id}`)
        .expect(200);

      expect(response.body.id).toBe(rental.id);
      expect(response.body.subtotal).toBe(500.00);
      expect(response.body.discount).toBe(50.00);
      expect(response.body.total).toBe(450.00);
      expect(response.body.listing).toHaveProperty('id', testListing.id);
      expect(response.body.renter).toHaveProperty('id', testUser.id);
      expect(response.body.coupon).toHaveProperty('id', testCoupon.id);
      expect(response.body.coupon).toHaveProperty('code', testCoupon.code);
    });

    it('should return 404 for non-existent listing rental', async () => {
      const response = await request(app)
        .get('/api/listing-rentals/999')
        .expect(404);

      expect(response.body.error).toBe('Listing rental not found');
    });

    it('should handle invalid ID', async () => {
      const response = await request(app)
        .get('/api/listing-rentals/invalid')
        .expect(400);

      expect(response.body.error).toBe('Invalid listing rental ID');
    });
  });

  describe('POST /api/listing-rentals', () => {
    it('should create a new listing rental', async () => {
      const newRental = {
        list_id: testListing.id,
        renter_id: testUser.id,
        start_date: '2024-01-01',
        end_date: '2024-01-05',
        rent_type: 'daily',
        status: 'pending',
        subtotal: 500.00,
        discount: 50.00,
        total: 450.00,
        commission: 45.00,
        sellers_value: 405.00,
        bank_name: 'Test Bank',
        account_holder_name: 'Test User',
        coupon_code: 'TEST10',
        coupon_id: testCoupon.id,
      };

      const response = await request(app)
        .post('/api/listing-rentals')
        .send(newRental)
        .expect(201);

      expect(response.body.message).toBe('Listing rental created successfully');
      expect(response.body.listingRental.subtotal).toBe(500.00);
      expect(response.body.listingRental.discount).toBe(50.00);
      expect(response.body.listingRental.total).toBe(450.00);
      expect(response.body.listingRental.status).toBe('pending');
      expect(response.body.listingRental.listing).toHaveProperty('id', testListing.id);
      expect(response.body.listingRental.renter).toHaveProperty('id', testUser.id);
      expect(response.body.listingRental.coupon).toHaveProperty('id', testCoupon.id);
    });

    it('should create listing rental with minimal required fields', async () => {
      const minimalRental = {
        list_id: testListing.id,
        renter_id: testUser.id,
        start_date: '2024-01-01',
        end_date: '2024-01-05',
        rent_type: 'daily',
        subtotal: 500.00,
        discount: 0,
        total: 500.00,
        commission: 50.00,
        sellers_value: 450.00,
      };

      const response = await request(app)
        .post('/api/listing-rentals')
        .send(minimalRental)
        .expect(201);

      expect(response.body.listingRental.subtotal).toBe(500.00);
      expect(response.body.listingRental.status).toBe('pending'); // default value
      expect(response.body.listingRental.discount).toBe(0); // default value
    });

    it('should validate required fields', async () => {
      const response = await request(app)
        .post('/api/listing-rentals')
        .send({})
        .expect(400);

      expect(response.body.error).toBe('Valid list ID is required');
    });

    it('should validate date range', async () => {
      const response = await request(app)
        .post('/api/listing-rentals')
        .send({
          list_id: testListing.id,
          renter_id: testUser.id,
          start_date: '2024-01-05',
          end_date: '2024-01-01', // Before start date
          rent_type: 'daily',
          subtotal: 500.00,
          discount: 0,
          total: 500.00,
          commission: 50.00,
          sellers_value: 450.00,
        })
        .expect(400);

      expect(response.body.error).toBe('End date must be after start date');
    });

    it('should validate rent_type enum', async () => {
      const response = await request(app)
        .post('/api/listing-rentals')
        .send({
          list_id: testListing.id,
          renter_id: testUser.id,
          start_date: '2024-01-01',
          end_date: '2024-01-05',
          rent_type: 'invalid_type',
          subtotal: 500.00,
          discount: 0,
          total: 500.00,
          commission: 50.00,
          sellers_value: 450.00,
        })
        .expect(400);

      expect(response.body.error).toBe('Valid rent_type is required');
    });

    it('should validate status enum', async () => {
      const response = await request(app)
        .post('/api/listing-rentals')
        .send({
          list_id: testListing.id,
          renter_id: testUser.id,
          start_date: '2024-01-01',
          end_date: '2024-01-05',
          rent_type: 'daily',
          status: 'invalid_status',
          subtotal: 500.00,
          discount: 0,
          total: 500.00,
          commission: 50.00,
          sellers_value: 450.00,
        })
        .expect(400);

      expect(response.body.error).toBe('Invalid status value');
    });

    it('should validate monetary values', async () => {
      const response = await request(app)
        .post('/api/listing-rentals')
        .send({
          list_id: testListing.id,
          renter_id: testUser.id,
          start_date: '2024-01-01',
          end_date: '2024-01-05',
          rent_type: 'daily',
          subtotal: -500,
          discount: 0,
          total: -500,
          commission: 50.00,
          sellers_value: 450.00,
        })
        .expect(400);

      expect(response.body.error).toBe('Subtotal must be a non-negative number');
    });

    it('should validate total calculation', async () => {
      const response = await request(app)
        .post('/api/listing-rentals')
        .send({
          list_id: testListing.id,
          renter_id: testUser.id,
          start_date: '2024-01-01',
          end_date: '2024-01-05',
          rent_type: 'daily',
          subtotal: 500.00,
          discount: 50.00,
          total: 400.00, // Should be 450.00
          commission: 45.00,
          sellers_value: 405.00,
        })
        .expect(400);

      expect(response.body.error).toBe('Total must equal subtotal minus discount');
    });

    it('should handle non-existent listing', async () => {
      const response = await request(app)
        .post('/api/listing-rentals')
        .send({
          list_id: 999,
          renter_id: testUser.id,
          start_date: '2024-01-01',
          end_date: '2024-01-05',
          rent_type: 'daily',
          subtotal: 500.00,
          discount: 0,
          total: 500.00,
          commission: 50.00,
          sellers_value: 450.00,
        })
        .expect(404);

      expect(response.body.error).toBe('Listing not found');
    });

    it('should handle non-existent renter', async () => {
      const response = await request(app)
        .post('/api/listing-rentals')
        .send({
          list_id: testListing.id,
          renter_id: 999,
          start_date: '2024-01-01',
          end_date: '2024-01-05',
          rent_type: 'daily',
          subtotal: 500.00,
          discount: 0,
          total: 500.00,
          commission: 50.00,
          sellers_value: 450.00,
        })
        .expect(404);

      expect(response.body.error).toBe('Renter not found');
    });

    it('should handle non-existent coupon', async () => {
      const response = await request(app)
        .post('/api/listing-rentals')
        .send({
          list_id: testListing.id,
          renter_id: testUser.id,
          start_date: '2024-01-01',
          end_date: '2024-01-05',
          rent_type: 'daily',
          subtotal: 500.00,
          discount: 0,
          total: 500.00,
          commission: 50.00,
          sellers_value: 450.00,
          coupon_id: 999,
        })
        .expect(404);

      expect(response.body.error).toBe('Coupon not found');
    });
  });

  describe('PUT /api/listing-rentals/:id', () => {
    let testRental;

    beforeEach(async () => {
      testRental = await ListingRental.create({
        list_id: testListing.id,
        renter_id: testUser.id,
        start_date: new Date('2024-01-01'),
        end_date: new Date('2024-01-05'),
        rent_type: 'daily',
        status: 'pending',
        subtotal: 500.00,
        discount: 0,
        total: 500.00,
        commission: 50.00,
        sellers_value: 450.00,
      });
    });

    it('should update a listing rental', async () => {
      const updates = {
        status: 'confirmed',
        discount: 50.00,
        total: 450.00,
        bank_name: 'Updated Bank',
        account_holder_name: 'Updated Name',
      };

      const response = await request(app)
        .put(`/api/listing-rentals/${testRental.id}`)
        .send(updates)
        .expect(200);

      expect(response.body.message).toBe('Listing rental updated successfully');
      expect(response.body.listingRental.status).toBe('confirmed');
      expect(response.body.listingRental.discount).toBe(50.00);
      expect(response.body.listingRental.total).toBe(450.00);
      expect(response.body.listingRental.bank_name).toBe('Updated Bank');
      expect(response.body.listingRental.account_holder_name).toBe('Updated Name');
    });

    it('should validate status on update', async () => {
      const response = await request(app)
        .put(`/api/listing-rentals/${testRental.id}`)
        .send({ status: 'invalid' })
        .expect(400);

      expect(response.body.error).toBe('Invalid status value');
    });

    it('should validate date range on update', async () => {
      const response = await request(app)
        .put(`/api/listing-rentals/${testRental.id}`)
        .send({
          start_date: '2024-01-10',
          end_date: '2024-01-05', // Before start date
        })
        .expect(400);

      expect(response.body.error).toBe('End date must be after start date');
    });

    it('should validate monetary values on update', async () => {
      const response = await request(app)
        .put(`/api/listing-rentals/${testRental.id}`)
        .send({ subtotal: -100 })
        .expect(400);

      expect(response.body.error).toBe('Subtotal must be a non-negative number');
    });

    it('should validate total calculation on update', async () => {
      const response = await request(app)
        .put(`/api/listing-rentals/${testRental.id}`)
        .send({
          subtotal: 500.00,
          discount: 50.00,
          total: 400.00, // Should be 450.00
        })
        .expect(400);

      expect(response.body.error).toBe('Total must equal subtotal minus discount');
    });

    it('should return 404 for non-existent listing rental', async () => {
      const response = await request(app)
        .put('/api/listing-rentals/999')
        .send({ status: 'confirmed' })
        .expect(404);

      expect(response.body.error).toBe('Listing rental not found');
    });

    it('should allow setting optional fields to null', async () => {
      const response = await request(app)
        .put(`/api/listing-rentals/${testRental.id}`)
        .send({
          bank_name: null,
          branch: null,
          swift: null,
          coupon_id: null,
        })
        .expect(200);

      expect(response.body.listingRental.bank_name).toBeNull();
      expect(response.body.listingRental.branch).toBeNull();
      expect(response.body.listingRental.swift).toBeNull();
      expect(response.body.listingRental.coupon_id).toBeNull();
    });
  });

  describe('DELETE /api/listing-rentals/:id', () => {
    let testRental;

    beforeEach(async () => {
      testRental = await ListingRental.create({
        list_id: testListing.id,
        renter_id: testUser.id,
        start_date: new Date('2024-01-01'),
        end_date: new Date('2024-01-05'),
        rent_type: 'daily',
        status: 'pending',
        subtotal: 500.00,
        discount: 0,
        total: 500.00,
        commission: 50.00,
        sellers_value: 450.00,
      });
    });

    it('should delete a listing rental', async () => {
      const response = await request(app)
        .delete(`/api/listing-rentals/${testRental.id}`)
        .expect(200);

      expect(response.body.message).toBe('Listing rental deleted successfully');

      // Verify deletion
      const deleted = await ListingRental.findByPk(testRental.id);
      expect(deleted).toBeNull();
    });

    it('should return 404 for non-existent listing rental', async () => {
      const response = await request(app)
        .delete('/api/listing-rentals/999')
        .expect(404);

      expect(response.body.error).toBe('Listing rental not found');
    });

    it('should handle invalid ID', async () => {
      const response = await request(app)
        .delete('/api/listing-rentals/invalid')
        .expect(400);

      expect(response.body.error).toBe('Invalid listing rental ID');
    });
  });
});
