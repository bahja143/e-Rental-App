process.env.NODE_ENV = 'test';

const request = require('supertest');
const { sequelize, Coupon } = require('../src/models');

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

describe('Coupons API', () => {
  let app;
  let server;

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
    await Coupon.destroy({ where: {} });
    // Reset SQLite auto-increment sequence
    await sequelize.query('DELETE FROM sqlite_sequence WHERE name = "coupons"');
  });

  describe('GET /api/coupons', () => {
    it('should return empty array when no coupons exist', async () => {
      const response = await request(app)
        .get('/api/coupons')
        .expect(200);

      expect(response.body).toHaveProperty('data');
      expect(response.body).toHaveProperty('pagination');
      expect(response.body.data).toHaveLength(0);
      expect(response.body.pagination.totalItems).toBe(0);
    });

    it('should return coupons with default pagination', async () => {
      // Create test coupons
      const coupons = [];
      for (let i = 1; i <= 15; i++) {
        coupons.push({
          code: `COUPON${i}`,
          type: i % 2 === 0 ? 'percentage' : 'fixed',
          value: i * 10,
          use_case: i % 4 === 0 ? 'listing_package' : i % 4 === 1 ? 'promotion_package' : i % 4 === 2 ? 'listing_buy' : 'listing_rent',
          min_purchase: i * 100,
          is_active: true,
        });
      }
      await Coupon.bulkCreate(coupons);

      const response = await request(app)
        .get('/api/coupons')
        .expect(200);

      expect(response.body.data).toHaveLength(10); // Default limit
      expect(response.body.pagination.totalItems).toBe(15);
      expect(response.body.pagination.totalPages).toBe(2);
      expect(response.body.pagination.currentPage).toBe(1);
      expect(response.body.pagination.hasNextPage).toBe(true);
      expect(response.body.pagination.hasPrevPage).toBe(false);
    });

    it('should support pagination', async () => {
      // Create test coupons
      const coupons = [];
      for (let i = 1; i <= 25; i++) {
        coupons.push({
          code: `COUPON${i}`,
          type: 'fixed',
          value: i * 10,
          use_case: 'listing_package',
          is_active: true,
        });
      }
      await Coupon.bulkCreate(coupons);

      const response = await request(app)
        .get('/api/coupons?page=2&limit=10')
        .expect(200);

      expect(response.body.data).toHaveLength(10);
      expect(response.body.pagination.totalItems).toBe(25);
      expect(response.body.pagination.currentPage).toBe(2);
      expect(response.body.pagination.hasNextPage).toBe(true);
      expect(response.body.pagination.hasPrevPage).toBe(true);
    });

    it('should support search functionality', async () => {
      await Coupon.create({
        code: 'SUMMER2024',
        type: 'percentage',
        value: 20,
        use_case: 'listing_package',
        is_active: true,
      });
      await Coupon.create({
        code: 'WINTER2024',
        type: 'fixed',
        value: 5000,
        use_case: 'promotion_package',
        is_active: true,
      });
      await Coupon.create({
        code: 'SPRING2024',
        type: 'percentage',
        value: 15,
        use_case: 'listing_buy',
        is_active: true,
      });

      const response = await request(app)
        .get('/api/coupons?search=summer')
        .expect(200);

      expect(response.body.data).toHaveLength(1);
      expect(response.body.data[0].code).toBe('SUMMER2024');
    });

    it('should support type filtering', async () => {
      await Coupon.create({
        code: 'PERCENT20',
        type: 'percentage',
        value: 20,
        use_case: 'listing_package',
        is_active: true,
      });
      await Coupon.create({
        code: 'FIXED5000',
        type: 'fixed',
        value: 5000,
        use_case: 'listing_package',
        is_active: true,
      });

      const response = await request(app)
        .get('/api/coupons?type=percentage')
        .expect(200);

      expect(response.body.data).toHaveLength(1);
      expect(response.body.data[0].type).toBe('percentage');
    });

    it('should support use_case filtering', async () => {
      await Coupon.create({
        code: 'LISTINGCOUPON',
        type: 'fixed',
        value: 1000,
        use_case: 'listing_package',
        is_active: true,
      });
      await Coupon.create({
        code: 'PROMOTIONCOUPON',
        type: 'percentage',
        value: 10,
        use_case: 'promotion_package',
        is_active: true,
      });

      const response = await request(app)
        .get('/api/coupons?use_case=listing_package')
        .expect(200);

      expect(response.body.data).toHaveLength(1);
      expect(response.body.data[0].use_case).toBe('listing_package');
    });

    it('should support is_active filtering', async () => {
      await Coupon.create({
        code: 'ACTIVECOUPON',
        type: 'fixed',
        value: 1000,
        use_case: 'listing_package',
        is_active: true,
      });
      await Coupon.create({
        code: 'INACTIVECOUPON',
        type: 'percentage',
        value: 20,
        use_case: 'listing_package',
        is_active: false,
      });

      const response = await request(app)
        .get('/api/coupons?is_active=true')
        .expect(200);

      expect(response.body.data).toHaveLength(1);
      expect(response.body.data[0].is_active).toBe(true);
    });

    it('should support min_purchase range filtering', async () => {
      await Coupon.create({
        code: 'LOWMIN',
        type: 'fixed',
        value: 1000,
        use_case: 'listing_package',
        min_purchase: 500,
        is_active: true,
      });
      await Coupon.create({
        code: 'HIGHMIN',
        type: 'percentage',
        value: 20,
        use_case: 'listing_package',
        min_purchase: 5000,
        is_active: true,
      });
      await Coupon.create({
        code: 'MEDMIN',
        type: 'fixed',
        value: 2000,
        use_case: 'listing_package',
        min_purchase: 2000,
        is_active: true,
      });

      const response = await request(app)
        .get('/api/coupons?min_purchase_min=1000&min_purchase_max=3000')
        .expect(200);

      expect(response.body.data).toHaveLength(1);
      expect(response.body.data[0].min_purchase).toBe(2000);
    });

    it('should support sorting', async () => {
      await Coupon.create({
        code: 'ZCOUPON',
        type: 'fixed',
        value: 1000,
        use_case: 'listing_package',
        is_active: true,
      });
      await Coupon.create({
        code: 'ACOUPON',
        type: 'percentage',
        value: 20,
        use_case: 'listing_package',
        is_active: true,
      });

      const response = await request(app)
        .get('/api/coupons?sortBy=code&sortOrder=ASC')
        .expect(200);

      expect(response.body.data[0].code).toBe('ACOUPON');
      expect(response.body.data[1].code).toBe('ZCOUPON');
    });

    it('should handle invalid page number', async () => {
      const response = await request(app)
        .get('/api/coupons?page=invalid')
        .expect(400);

      expect(response.body.error).toBe('Invalid page number');
    });

    it('should handle invalid limit', async () => {
      const response = await request(app)
        .get('/api/coupons?limit=200')
        .expect(400);

      expect(response.body.error).toBe('Invalid limit (1-100)');
    });
  });

  describe('GET /api/coupons/:id', () => {
    it('should return a coupon by ID', async () => {
      const coupon = await Coupon.create({
        code: 'TESTCOUPON',
        type: 'percentage',
        value: 25,
        use_case: 'listing_package',
        min_purchase: 1000,
        start_date: new Date('2024-01-01'),
        expire_date: new Date('2024-12-31'),
        usage_limit: 100,
        per_user_limit: 5,
        is_active: true,
        used: 10,
      });

      const response = await request(app)
        .get(`/api/coupons/${coupon.id}`)
        .expect(200);

      expect(response.body.id).toBe(coupon.id);
      expect(response.body.code).toBe('TESTCOUPON');
      expect(response.body.type).toBe('percentage');
      expect(response.body.value).toBe(25);
      expect(response.body.use_case).toBe('listing_package');
      expect(response.body.min_purchase).toBe(1000);
      expect(response.body.usage_limit).toBe(100);
      expect(response.body.per_user_limit).toBe(5);
      expect(response.body.is_active).toBe(true);
      expect(response.body.used).toBe(10);
    });

    it('should return 404 for non-existent coupon', async () => {
      const response = await request(app)
        .get('/api/coupons/999')
        .expect(404);

      expect(response.body.error).toBe('Coupon not found');
    });

    it('should handle invalid ID', async () => {
      const response = await request(app)
        .get('/api/coupons/invalid')
        .expect(400);

      expect(response.body.error).toBe('Invalid coupon ID');
    });
  });

  describe('POST /api/coupons', () => {
    it('should create a new coupon', async () => {
      const newCoupon = {
        code: 'NEWCOUPON',
        type: 'percentage',
        value: 15,
        use_case: 'listing_package',
        min_purchase: 500,
        start_date: '2024-01-01T00:00:00.000Z',
        expire_date: '2024-12-31T23:59:59.000Z',
        usage_limit: 50,
        per_user_limit: 3,
        is_active: true,
      };

      const response = await request(app)
        .post('/api/coupons')
        .send(newCoupon)
        .expect(201);

      expect(response.body.message).toBe('Coupon created successfully');
      expect(response.body.coupon.code).toBe('NEWCOUPON');
      expect(response.body.coupon.type).toBe('percentage');
      expect(response.body.coupon.value).toBe(15);
      expect(response.body.coupon.use_case).toBe('listing_package');
      expect(response.body.coupon.min_purchase).toBe(500);
      expect(response.body.coupon.usage_limit).toBe(50);
      expect(response.body.coupon.per_user_limit).toBe(3);
      expect(response.body.coupon.is_active).toBe(true);
    });

    it('should create coupon with default is_active', async () => {
      const newCoupon = {
        code: 'DEFAULTCOUPON',
        type: 'fixed',
        value: 1000,
        use_case: 'promotion_package',
      };

      const response = await request(app)
        .post('/api/coupons')
        .send(newCoupon)
        .expect(201);

      expect(response.body.coupon.is_active).toBe(true); // default value
    });

    it('should validate required fields', async () => {
      const response = await request(app)
        .post('/api/coupons')
        .send({})
        .expect(400);

      expect(response.body.error).toBe('Code must be 1-50 characters');
    });

    it('should validate code uniqueness', async () => {
      await Coupon.create({
        code: 'DUPLICATE',
        type: 'fixed',
        value: 1000,
        use_case: 'listing_package',
        is_active: true,
      });

      const response = await request(app)
        .post('/api/coupons')
        .send({
          code: 'DUPLICATE',
          type: 'percentage',
          value: 20,
          use_case: 'promotion_package',
        })
        .expect(400);

      expect(response.body.error).toBe('Coupon code already exists');
    });

    it('should validate code length', async () => {
      const response = await request(app)
        .post('/api/coupons')
        .send({
          code: '',
          type: 'fixed',
          value: 1000,
          use_case: 'listing_package',
        })
        .expect(400);

      expect(response.body.error).toBe('Code must be 1-50 characters');
    });

    it('should validate type', async () => {
      const response = await request(app)
        .post('/api/coupons')
        .send({
          code: 'INVALIDTYPE',
          type: 'invalid',
          value: 1000,
          use_case: 'listing_package',
        })
        .expect(400);

      expect(response.body.error).toBe('Type must be either "percentage" or "fixed"');
    });

    it('should validate value', async () => {
      const response = await request(app)
        .post('/api/coupons')
        .send({
          code: 'INVALIDVALUE',
          type: 'fixed',
          value: -100,
          use_case: 'listing_package',
        })
        .expect(400);

      expect(response.body.error).toBe('Value must be a positive number up to 999999.99');
    });

    it('should validate percentage value cannot exceed 100', async () => {
      const response = await request(app)
        .post('/api/coupons')
        .send({
          code: 'INVALIDPERCENTAGE',
          type: 'percentage',
          value: 150,
          use_case: 'listing_package',
        })
        .expect(400);

      expect(response.body.error).toBe('Percentage value cannot exceed 100%');
    });

    it('should validate use_case', async () => {
      const response = await request(app)
        .post('/api/coupons')
        .send({
          code: 'INVALIDUSECASE',
          type: 'fixed',
          value: 1000,
          use_case: 'invalid_case',
        })
        .expect(400);

      expect(response.body.error).toBe('Use case must be one of: listing_package, promotion_package, listing_buy, listing_rent');
    });

    it('should validate min_purchase', async () => {
      const response = await request(app)
        .post('/api/coupons')
        .send({
          code: 'INVALIDMINPURCHASE',
          type: 'fixed',
          value: 1000,
          use_case: 'listing_package',
          min_purchase: -100,
        })
        .expect(400);

      expect(response.body.error).toBe('Min purchase must be a non-negative integer');
    });

    it('should validate date ranges', async () => {
      const response = await request(app)
        .post('/api/coupons')
        .send({
          code: 'INVALIDDATES',
          type: 'fixed',
          value: 1000,
          use_case: 'listing_package',
          start_date: '2024-12-31T00:00:00.000Z',
          expire_date: '2024-01-01T00:00:00.000Z',
        })
        .expect(400);

      expect(response.body.error).toBe('Start date must be before expire date');
    });

    it('should validate usage_limit', async () => {
      const response = await request(app)
        .post('/api/coupons')
        .send({
          code: 'INVALIDUSAGELIMIT',
          type: 'fixed',
          value: 1000,
          use_case: 'listing_package',
          usage_limit: 0,
        })
        .expect(400);

      expect(response.body.error).toBe('Usage limit must be a positive integer');
    });

    it('should validate per_user_limit', async () => {
      const response = await request(app)
        .post('/api/coupons')
        .send({
          code: 'INVALIDPERUSERLIMIT',
          type: 'fixed',
          value: 1000,
          use_case: 'listing_package',
          per_user_limit: -1,
        })
        .expect(400);

      expect(response.body.error).toBe('Per user limit must be a positive integer');
    });
  });

  describe('PUT /api/coupons/:id', () => {
    let testCoupon;

    beforeEach(async () => {
      testCoupon = await Coupon.create({
        code: 'TESTCOUPON',
        type: 'percentage',
        value: 20,
        use_case: 'listing_package',
        min_purchase: 1000,
        start_date: new Date('2024-01-01'),
        expire_date: new Date('2024-12-31'),
        usage_limit: 100,
        per_user_limit: 5,
        is_active: true,
        used: 10,
      });
    });

    it('should update a coupon', async () => {
      const updates = {
        code: 'UPDATEDCOUPON',
        type: 'fixed',
        value: 5000,
        use_case: 'promotion_package',
        min_purchase: 2000,
        usage_limit: 200,
        per_user_limit: 10,
        is_active: false,
      };

      const response = await request(app)
        .put(`/api/coupons/${testCoupon.id}`)
        .send(updates)
        .expect(200);

      expect(response.body.message).toBe('Coupon updated successfully');
      expect(response.body.coupon.code).toBe('UPDATEDCOUPON');
      expect(response.body.coupon.type).toBe('fixed');
      expect(response.body.coupon.value).toBe(5000);
      expect(response.body.coupon.use_case).toBe('promotion_package');
      expect(response.body.coupon.min_purchase).toBe(2000);
      expect(response.body.coupon.usage_limit).toBe(200);
      expect(response.body.coupon.per_user_limit).toBe(10);
      expect(response.body.coupon.is_active).toBe(false);
    });

    it('should return 404 for non-existent coupon', async () => {
      const response = await request(app)
        .put('/api/coupons/999')
        .send({ code: 'UPDATED' })
        .expect(404);

      expect(response.body.error).toBe('Coupon not found');
    });

    it('should validate update data', async () => {
      const response = await request(app)
        .put(`/api/coupons/${testCoupon.id}`)
        .send({ code: '' })
        .expect(400);

      expect(response.body.error).toBe('Code must be 1-50 characters');
    });

    it('should validate percentage value on update', async () => {
      const response = await request(app)
        .put(`/api/coupons/${testCoupon.id}`)
        .send({ value: 150 })
        .expect(400);

      expect(response.body.error).toBe('Percentage value cannot exceed 100%');
    });

    it('should validate date ranges on update', async () => {
      const response = await request(app)
        .put(`/api/coupons/${testCoupon.id}`)
        .send({
          start_date: '2024-12-31T00:00:00.000Z',
          expire_date: '2024-01-01T00:00:00.000Z',
        })
        .expect(400);

      expect(response.body.error).toBe('Start date must be before expire date');
    });

    it('should allow null values for optional fields', async () => {
      const response = await request(app)
        .put(`/api/coupons/${testCoupon.id}`)
        .send({
          min_purchase: null,
          start_date: null,
          expire_date: null,
          usage_limit: null,
          per_user_limit: null,
        })
        .expect(200);

      expect(response.body.coupon.min_purchase).toBeNull();
      expect(response.body.coupon.start_date).toBeNull();
      expect(response.body.coupon.expire_date).toBeNull();
      expect(response.body.coupon.usage_limit).toBeNull();
      expect(response.body.coupon.per_user_limit).toBeNull();
    });
  });

  describe('DELETE /api/coupons/:id', () => {
    let testCoupon;

    beforeEach(async () => {
      testCoupon = await Coupon.create({
        code: 'TESTCOUPON',
        type: 'fixed',
        value: 1000,
        use_case: 'listing_package',
        is_active: true,
      });
    });

    it('should delete a coupon', async () => {
      const response = await request(app)
        .delete(`/api/coupons/${testCoupon.id}`)
        .expect(200);

      expect(response.body.message).toBe('Coupon deleted successfully');

      // Verify deletion
      const deleted = await Coupon.findByPk(testCoupon.id);
      expect(deleted).toBeNull();
    });

    it('should return 404 for non-existent coupon', async () => {
      const response = await request(app)
        .delete('/api/coupons/999')
        .expect(404);

      expect(response.body.error).toBe('Coupon not found');
    });

    it('should handle invalid ID', async () => {
      const response = await request(app)
        .delete('/api/coupons/invalid')
        .expect(400);

      expect(response.body.error).toBe('Invalid coupon ID');
    });
  });
});
