process.env.NODE_ENV = 'test';

const request = require('supertest');
const { sequelize, Promotion, Listing, Coupon, PromotionPack } = require('../src/models');

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

describe('Promotions API', () => {
  let app;
  let server;
  let testListing;
  let testCoupon;
  let testPromotionPack;

  beforeAll(async () => {
    // Import app after mocking
    app = require('../src/app');

    // Sync the in-memory database
    await sequelize.sync({ force: true });

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
    await Promotion.destroy({ where: {} });
    // Reset SQLite auto-increment sequence
    await sequelize.query('DELETE FROM sqlite_sequence WHERE name = "promotions"');

    // Create test listing and coupon for each test
    testListing = await Listing.create({
      user_id: 1,
      title: 'Test Listing',
      lat: 0,
      lng: 0,
      address: 'Test Address',
      sell_price: 100000,
      availability: '1',
      location: { type: 'Point', coordinates: [0, 0] },
    });

    testCoupon = await Coupon.create({
      code: 'TESTCOUPON',
      type: 'percentage',
      value: 10,
      use_case: 'listing_package',
      is_active: true,
    });

    testPromotionPack = await PromotionPack.create({
      name_en: 'Test Promotion Pack',
      name_so: 'Baakada Xayeysiiska Tijaabada',
      duration: 30,
      price: 50.00,
      availability: 1,
    });
  });

  describe('GET /api/promotions', () => {
    it('should return empty array when no promotions exist', async () => {
      const response = await request(app)
        .get('/api/promotions')
        .expect(200);

      expect(response.body).toHaveProperty('data');
      expect(response.body).toHaveProperty('pagination');
      expect(response.body.data).toHaveLength(0);
      expect(response.body.pagination.totalItems).toBe(0);
    });

    it('should return promotions with default pagination', async () => {
      // Create test promotions
      const promotions = [];
      for (let i = 1; i <= 15; i++) {
        promotions.push({
          listing_id: testListing.id,
          subtotal: 1000 + i * 100,
          discount: i * 10,
          total: 1000 + i * 100 - i * 10,
          start_date: new Date('2024-01-01'),
          end_date: new Date('2024-12-31'),
          status: 'active',
        });
      }
      await Promotion.bulkCreate(promotions);

      const response = await request(app)
        .get('/api/promotions')
        .expect(200);

      expect(response.body.data).toHaveLength(10); // Default limit
      expect(response.body.pagination.totalItems).toBe(15);
      expect(response.body.pagination.totalPages).toBe(2);
      expect(response.body.pagination.currentPage).toBe(1);
      expect(response.body.pagination.hasNextPage).toBe(true);
      expect(response.body.pagination.hasPrevPage).toBe(false);
    });

    it('should support pagination', async () => {
      // Create test promotions
      const promotions = [];
      for (let i = 1; i <= 25; i++) {
        promotions.push({
          listing_id: testListing.id,
          subtotal: 1000 + i * 100,
          discount: i * 10,
          total: 1000 + i * 100 - i * 10,
          start_date: new Date('2024-01-01'),
          end_date: new Date('2024-12-31'),
          status: 'active',
        });
      }
      await Promotion.bulkCreate(promotions);

      const response = await request(app)
        .get('/api/promotions?page=2&limit=10')
        .expect(200);

      expect(response.body.data).toHaveLength(10);
      expect(response.body.pagination.totalItems).toBe(25);
      expect(response.body.pagination.currentPage).toBe(2);
      expect(response.body.pagination.hasNextPage).toBe(true);
      expect(response.body.pagination.hasPrevPage).toBe(true);
    });

    it('should support search functionality', async () => {
      await Promotion.create({
        listing_id: testListing.id,
        subtotal: 1000,
        discount: 100,
        total: 900,
        coupon_code: 'SUMMER2024',
        start_date: new Date('2024-01-01'),
        end_date: new Date('2024-12-31'),
        status: 'active',
      });
      await Promotion.create({
        listing_id: testListing.id,
        subtotal: 2000,
        discount: 200,
        total: 1800,
        coupon_code: 'WINTER2024',
        start_date: new Date('2024-01-01'),
        end_date: new Date('2024-12-31'),
        status: 'active',
      });

      const response = await request(app)
        .get('/api/promotions?search=summer')
        .expect(200);

      expect(response.body.data).toHaveLength(1);
      expect(response.body.data[0].coupon_code).toBe('SUMMER2024');
    });

    it('should support status filtering', async () => {
      await Promotion.create({
        listing_id: testListing.id,
        subtotal: 1000,
        discount: 0,
        total: 1000,
        start_date: new Date('2024-01-01'),
        end_date: new Date('2024-12-31'),
        status: 'active',
      });
      await Promotion.create({
        listing_id: testListing.id,
        subtotal: 2000,
        discount: 0,
        total: 2000,
        start_date: new Date('2023-01-01'),
        end_date: new Date('2023-12-31'),
        status: 'expired',
      });

      const response = await request(app)
        .get('/api/promotions?status=active')
        .expect(200);

      expect(response.body.data).toHaveLength(1);
      expect(response.body.data[0].status).toBe('active');
    });

    it('should support listing_id filtering', async () => {
      const anotherListing = await Listing.create({
        user_id: 1,
        title: 'Another Listing',
        lat: 1,
        lng: 1,
        address: 'Another Address',
        sell_price: 200000,
        availability: '1',
        location: { type: 'Point', coordinates: [1, 1] },
      });

      await Promotion.create({
        listing_id: testListing.id,
        subtotal: 1000,
        discount: 0,
        total: 1000,
        start_date: new Date('2024-01-01'),
        end_date: new Date('2024-12-31'),
        status: 'active',
      });
      await Promotion.create({
        listing_id: anotherListing.id,
        subtotal: 2000,
        discount: 0,
        total: 2000,
        start_date: new Date('2024-01-01'),
        end_date: new Date('2024-12-31'),
        status: 'active',
      });

      const response = await request(app)
        .get(`/api/promotions?listing_id=${testListing.id}`)
        .expect(200);

      expect(response.body.data).toHaveLength(1);
      expect(response.body.data[0].listing_id).toBe(testListing.id);
    });

    it('should support promotion_package_id filtering', async () => {
      await Promotion.create({
        listing_id: testListing.id,
        subtotal: 1000,
        discount: 0,
        total: 1000,
        start_date: new Date('2024-01-01'),
        end_date: new Date('2024-12-31'),
        promotion_package_id: testPromotionPack.id,
        status: 'active',
      });
      await Promotion.create({
        listing_id: testListing.id,
        subtotal: 2000,
        discount: 0,
        total: 2000,
        start_date: new Date('2024-01-01'),
        end_date: new Date('2024-12-31'),
        status: 'active',
      });

      const response = await request(app)
        .get(`/api/promotions?promotion_package_id=${testPromotionPack.id}`)
        .expect(200);

      expect(response.body.data).toHaveLength(1);
      expect(response.body.data[0].promotion_package_id).toBe(testPromotionPack.id);
    });

    it('should support sorting', async () => {
      await Promotion.create({
        listing_id: testListing.id,
        subtotal: 2000,
        discount: 0,
        total: 2000,
        start_date: new Date('2024-01-01'),
        end_date: new Date('2024-12-31'),
        status: 'active',
      });
      await Promotion.create({
        listing_id: testListing.id,
        subtotal: 1000,
        discount: 0,
        total: 1000,
        start_date: new Date('2024-01-01'),
        end_date: new Date('2024-12-31'),
        status: 'active',
      });

      const response = await request(app)
        .get('/api/promotions?sortBy=subtotal&sortOrder=ASC')
        .expect(200);

      expect(response.body.data[0].subtotal).toBe('1000.00');
      expect(response.body.data[1].subtotal).toBe('2000.00');
    });

    it('should include listing data when requested', async () => {
      await Promotion.create({
        listing_id: testListing.id,
        subtotal: 1000,
        discount: 0,
        total: 1000,
        start_date: new Date('2024-01-01'),
        end_date: new Date('2024-12-31'),
        status: 'active',
      });

      const response = await request(app)
        .get('/api/promotions?include_listing=true')
        .expect(200);

      expect(response.body.data[0]).toHaveProperty('listing');
      expect(response.body.data[0].listing.title).toBe('Test Listing');
    });

    it('should handle invalid page number', async () => {
      const response = await request(app)
        .get('/api/promotions?page=invalid')
        .expect(400);

      expect(response.body.error).toBe('Invalid page number');
    });

    it('should handle invalid limit', async () => {
      const response = await request(app)
        .get('/api/promotions?limit=200')
        .expect(400);

      expect(response.body.error).toBe('Invalid limit (1-100)');
    });
  });

  describe('GET /api/promotions/:id', () => {
    it('should return a promotion by ID', async () => {
      const promotion = await Promotion.create({
        listing_id: testListing.id,
        subtotal: 1000,
        discount: 100,
        total: 900,
        coupon_code: 'TESTCODE',
        start_date: new Date('2024-01-01'),
        end_date: new Date('2024-12-31'),
        coupon_id: testCoupon.id,
        status: 'active',
        bank_name: 'Test Bank',
        branch: 'Main Branch',
        bank_account: '123456789',
        account_holder_name: 'Test Holder',
        swift: 'TESTSWFT',
      });

      const response = await request(app)
        .get(`/api/promotions/${promotion.id}`)
        .expect(200);

      expect(response.body.id).toBe(promotion.id);
      expect(response.body.subtotal).toBe('1000.00');
      expect(response.body.discount).toBe('100.00');
      expect(response.body.total).toBe('900.00');
      expect(response.body.coupon_code).toBe('TESTCODE');
      expect(response.body.status).toBe('active');
      expect(response.body.bank_name).toBe('Test Bank');
    });

    it('should return 404 for non-existent promotion', async () => {
      const response = await request(app)
        .get('/api/promotions/999')
        .expect(404);

      expect(response.body.error).toBe('Promotion not found');
    });

    it('should handle invalid ID', async () => {
      const response = await request(app)
        .get('/api/promotions/invalid')
        .expect(400);

      expect(response.body.error).toBe('Invalid promotion ID');
    });
  });

  describe('POST /api/promotions', () => {
    it('should create a new promotion', async () => {
      const newPromotion = {
        listing_id: testListing.id,
        subtotal: 1000,
        coupon_code: 'NEWCOUPON',
        discount: 100,
        total: 900,
        start_date: '2024-01-01T00:00:00.000Z',
        end_date: '2024-12-31T23:59:59.000Z',
        coupon_id: testCoupon.id,
        promotion_package_id: testPromotionPack.id,
        status: 'active',
        bank_name: 'New Bank',
        branch: 'Downtown Branch',
        bank_account: '987654321',
        account_holder_name: 'New Holder',
        swift: 'NEWSWIFT',
      };

      const response = await request(app)
        .post('/api/promotions')
        .send(newPromotion)
        .expect(201);

      expect(response.body.message).toBe('Promotion created successfully');
      expect(response.body.promotion.subtotal).toBe('1000.00');
      expect(response.body.promotion.discount).toBe('100.00');
      expect(response.body.promotion.total).toBe('900.00');
      expect(response.body.promotion.coupon_code).toBe('NEWCOUPON');
      expect(response.body.promotion.promotion_package_id).toBe(testPromotionPack.id);
      expect(response.body.promotion.status).toBe('active');
      expect(response.body.promotion.bank_name).toBe('New Bank');
    });

    it('should create promotion with default values', async () => {
      const newPromotion = {
        listing_id: testListing.id,
        subtotal: 1000,
        discount: 0,
        total: 1000,
        start_date: '2024-01-01T00:00:00.000Z',
        end_date: '2024-12-31T23:59:59.000Z',
      };

      const response = await request(app)
        .post('/api/promotions')
        .send(newPromotion)
        .expect(201);

      expect(response.body.promotion.status).toBe('active'); // default value
      expect(response.body.promotion.discount).toBe('0.00'); // default value
    });

    it('should validate required fields', async () => {
      const response = await request(app)
        .post('/api/promotions')
        .send({})
        .expect(400);

      expect(response.body.error).toBe('Valid listing ID is required');
    });

    it('should validate listing existence', async () => {
      const response = await request(app)
        .post('/api/promotions')
        .send({
          listing_id: 999,
          subtotal: 1000,
          discount: 0,
          total: 1000,
          start_date: '2024-01-01T00:00:00.000Z',
          end_date: '2024-12-31T23:59:59.000Z',
        })
        .expect(404);

      expect(response.body.error).toBe('Listing not found');
    });

    it('should validate coupon existence', async () => {
      const response = await request(app)
        .post('/api/promotions')
        .send({
          listing_id: testListing.id,
          subtotal: 1000,
          discount: 0,
          total: 1000,
          start_date: '2024-01-01T00:00:00.000Z',
          end_date: '2024-12-31T23:59:59.000Z',
          coupon_id: 999,
        })
        .expect(404);

      expect(response.body.error).toBe('Coupon not found');
    });

    it('should validate promotion pack existence', async () => {
      const response = await request(app)
        .post('/api/promotions')
        .send({
          listing_id: testListing.id,
          subtotal: 1000,
          discount: 0,
          total: 1000,
          start_date: '2024-01-01T00:00:00.000Z',
          end_date: '2024-12-31T23:59:59.000Z',
          promotion_package_id: 999,
        })
        .expect(404);

      expect(response.body.error).toBe('Promotion pack not found');
    });

    it('should validate subtotal', async () => {
      const response = await request(app)
        .post('/api/promotions')
        .send({
          listing_id: testListing.id,
          subtotal: -100,
          discount: 0,
          total: -100,
          start_date: '2024-01-01T00:00:00.000Z',
          end_date: '2024-12-31T23:59:59.000Z',
        })
        .expect(400);

      expect(response.body.error).toBe('Subtotal must be a non-negative number');
    });

    it('should validate date ranges', async () => {
      const response = await request(app)
        .post('/api/promotions')
        .send({
          listing_id: testListing.id,
          subtotal: 1000,
          discount: 0,
          total: 1000,
          start_date: '2024-12-31T00:00:00.000Z',
          end_date: '2024-01-01T00:00:00.000Z',
        })
        .expect(400);

      expect(response.body.error).toBe('Start date must be before end date');
    });

    it('should validate total calculation', async () => {
      const response = await request(app)
        .post('/api/promotions')
        .send({
          listing_id: testListing.id,
          subtotal: 1000,
          discount: 100,
          total: 800, // Should be 900
          start_date: '2024-01-01T00:00:00.000Z',
          end_date: '2024-12-31T23:59:59.000Z',
        })
        .expect(400);

      expect(response.body.error).toBe('Total must equal subtotal minus discount');
    });

    it('should validate status', async () => {
      const response = await request(app)
        .post('/api/promotions')
        .send({
          listing_id: testListing.id,
          subtotal: 1000,
          discount: 0,
          total: 1000,
          start_date: '2024-01-01T00:00:00.000Z',
          end_date: '2024-12-31T23:59:59.000Z',
          status: 'invalid',
        })
        .expect(400);

      expect(response.body.error).toBe('Status must be either "active" or "expired"');
    });
  });

  describe('PUT /api/promotions/:id', () => {
    let testPromotion;

    beforeEach(async () => {
      testPromotion = await Promotion.create({
        listing_id: testListing.id,
        subtotal: 1000,
        discount: 100,
        total: 900,
        coupon_code: 'TESTCODE',
        start_date: new Date('2024-01-01'),
        end_date: new Date('2024-12-31'),
        coupon_id: testCoupon.id,
        status: 'active',
        bank_name: 'Test Bank',
        branch: 'Main Branch',
        bank_account: '123456789',
        account_holder_name: 'Test Holder',
        swift: 'TESTSWFT',
      });
    });

    it('should update a promotion', async () => {
      const updates = {
        subtotal: 2000,
        discount: 200,
        total: 1800,
        coupon_code: 'UPDATEDCODE',
        promotion_package_id: testPromotionPack.id,
        status: 'expired',
        bank_name: 'Updated Bank',
      };

      const response = await request(app)
        .put(`/api/promotions/${testPromotion.id}`)
        .send(updates)
        .expect(200);

      expect(response.body.message).toBe('Promotion updated successfully');
      expect(response.body.promotion.subtotal).toBe('2000.00');
      expect(response.body.promotion.discount).toBe('200.00');
      expect(response.body.promotion.total).toBe('1800.00');
      expect(response.body.promotion.coupon_code).toBe('UPDATEDCODE');
      expect(response.body.promotion.promotion_package_id).toBe(testPromotionPack.id);
      expect(response.body.promotion.status).toBe('expired');
      expect(response.body.promotion.bank_name).toBe('Updated Bank');
    });

    it('should return 404 for non-existent promotion', async () => {
      const response = await request(app)
        .put('/api/promotions/999')
        .send({ coupon_code: 'UPDATED' })
        .expect(404);

      expect(response.body.error).toBe('Promotion not found');
    });

    it('should validate update data', async () => {
      const response = await request(app)
        .put(`/api/promotions/${testPromotion.id}`)
        .send({ subtotal: -100 })
        .expect(400);

      expect(response.body.error).toBe('Subtotal must be a non-negative number');
    });

    it('should validate date ranges on update', async () => {
      const response = await request(app)
        .put(`/api/promotions/${testPromotion.id}`)
        .send({
          start_date: '2024-12-31T00:00:00.000Z',
          end_date: '2024-01-01T00:00:00.000Z',
        })
        .expect(400);

      expect(response.body.error).toBe('Start date must be before end date');
    });

    it('should allow null values for optional fields', async () => {
      const response = await request(app)
        .put(`/api/promotions/${testPromotion.id}`)
        .send({
          coupon_code: null,
          coupon_id: null,
          promotion_package_id: null,
          bank_name: null,
          branch: null,
          bank_account: null,
          account_holder_name: null,
          swift: null,
        })
        .expect(200);

      expect(response.body.promotion.coupon_code).toBeNull();
      expect(response.body.promotion.coupon_id).toBeNull();
      expect(response.body.promotion.promotion_package_id).toBeNull();
      expect(response.body.promotion.bank_name).toBeNull();
      expect(response.body.promotion.branch).toBeNull();
      expect(response.body.promotion.bank_account).toBeNull();
      expect(response.body.promotion.account_holder_name).toBeNull();
      expect(response.body.promotion.swift).toBeNull();
    });
  });

  describe('DELETE /api/promotions/:id', () => {
    let testPromotion;

    beforeEach(async () => {
      testPromotion = await Promotion.create({
        listing_id: testListing.id,
        subtotal: 1000,
        discount: 0,
        total: 1000,
        start_date: new Date('2024-01-01'),
        end_date: new Date('2024-12-31'),
        status: 'active',
      });
    });

    it('should delete a promotion', async () => {
      const response = await request(app)
        .delete(`/api/promotions/${testPromotion.id}`)
        .expect(200);

      expect(response.body.message).toBe('Promotion deleted successfully');

      // Verify deletion
      const deleted = await Promotion.findByPk(testPromotion.id);
      expect(deleted).toBeNull();
    });

    it('should return 404 for non-existent promotion', async () => {
      const response = await request(app)
        .delete('/api/promotions/999')
        .expect(404);

      expect(response.body.error).toBe('Promotion not found');
    });

    it('should handle invalid ID', async () => {
      const response = await request(app)
        .delete('/api/promotions/invalid')
        .expect(400);

      expect(response.body.error).toBe('Invalid promotion ID');
    });
  });
});
