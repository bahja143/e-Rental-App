process.env.NODE_ENV = 'test';

const request = require('supertest');
const { sequelize, PromotionPack } = require('../src/models');

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

describe('PromotionPacks API', () => {
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
    await PromotionPack.destroy({ where: {} });
    // Reset SQLite auto-increment sequence
    await sequelize.query('DELETE FROM sqlite_sequence WHERE name = "promotion_packs"');
  });

  describe('GET /api/promotion-packs', () => {
    it('should return empty array when no promotion packs exist', async () => {
      const response = await request(app)
        .get('/api/promotion-packs')
        .expect(200);

      expect(response.body).toHaveProperty('data');
      expect(response.body).toHaveProperty('pagination');
      expect(response.body.data).toHaveLength(0);
      expect(response.body.pagination.totalItems).toBe(0);
    });

    it('should return promotion packs with default pagination', async () => {
      // Create test promotion packs
      const packs = [];
      for (let i = 1; i <= 15; i++) {
        packs.push({
          name_en: `Pack ${i} EN`,
          name_so: `Pack ${i} SO`,
          duration: i,
          price: i * 10.0,
          availability: i % 2,
        });
      }
      await PromotionPack.bulkCreate(packs);

      const response = await request(app)
        .get('/api/promotion-packs')
        .expect(200);

      expect(response.body.data).toHaveLength(10); // Default limit
      expect(response.body.pagination.totalItems).toBe(15);
      expect(response.body.pagination.totalPages).toBe(2);
      expect(response.body.pagination.currentPage).toBe(1);
      expect(response.body.pagination.hasNextPage).toBe(true);
      expect(response.body.pagination.hasPrevPage).toBe(false);
    });

    it('should support pagination', async () => {
      // Create test promotion packs
      const packs = [];
      for (let i = 1; i <= 25; i++) {
        packs.push({
          name_en: `Pack ${i} EN`,
          name_so: `Pack ${i} SO`,
          duration: i,
          price: i * 10.0,
          availability: 1,
        });
      }
      await PromotionPack.bulkCreate(packs);

      const response = await request(app)
        .get('/api/promotion-packs?page=2&limit=10')
        .expect(200);

      expect(response.body.data).toHaveLength(10);
      expect(response.body.pagination.totalItems).toBe(25);
      expect(response.body.pagination.currentPage).toBe(2);
      expect(response.body.pagination.hasNextPage).toBe(true);
      expect(response.body.pagination.hasPrevPage).toBe(true);
    });

    it('should support search functionality', async () => {
      await PromotionPack.create({
        name_en: 'Basic Pack EN',
        name_so: 'Basic Pack SO',
        duration: 30,
        price: 50.0,
        availability: 1,
      });
      await PromotionPack.create({
        name_en: 'Premium Pack EN',
        name_so: 'Premium Pack SO',
        duration: 60,
        price: 100.0,
        availability: 1,
      });
      await PromotionPack.create({
        name_en: 'Standard Pack EN',
        name_so: 'Standard Pack SO',
        duration: 45,
        price: 75.0,
        availability: 1,
      });

      const response = await request(app)
        .get('/api/promotion-packs?search=premium')
        .expect(200);

      expect(response.body.data).toHaveLength(1);
      expect(response.body.data[0].name_en).toBe('Premium Pack EN');
    });

    it('should support duration filtering', async () => {
      await PromotionPack.create({
        name_en: 'Short Pack EN',
        name_so: 'Short Pack SO',
        duration: 30,
        price: 50.0,
        availability: 1,
      });
      await PromotionPack.create({
        name_en: 'Long Pack EN',
        name_so: 'Long Pack SO',
        duration: 60,
        price: 100.0,
        availability: 1,
      });

      const response = await request(app)
        .get('/api/promotion-packs?duration=30')
        .expect(200);

      expect(response.body.data).toHaveLength(1);
      expect(response.body.data[0].duration).toBe(30);
    });

    it('should support price range filtering', async () => {
      await PromotionPack.create({
        name_en: 'Cheap Pack EN',
        name_so: 'Cheap Pack SO',
        duration: 30,
        price: 25.0,
        availability: 1,
      });
      await PromotionPack.create({
        name_en: 'Expensive Pack EN',
        name_so: 'Expensive Pack SO',
        duration: 60,
        price: 150.0,
        availability: 1,
      });
      await PromotionPack.create({
        name_en: 'Medium Pack EN',
        name_so: 'Medium Pack SO',
        duration: 45,
        price: 75.0,
        availability: 1,
      });

      const response = await request(app)
        .get('/api/promotion-packs?price_min=50&price_max=100')
        .expect(200);

      expect(response.body.data).toHaveLength(1);
      expect(response.body.data[0].price).toBe(75.0);
    });

    it('should support availability filtering', async () => {
      await PromotionPack.create({
        name_en: 'Available Pack EN',
        name_so: 'Available Pack SO',
        duration: 30,
        price: 50.0,
        availability: 1,
      });
      await PromotionPack.create({
        name_en: 'Unavailable Pack EN',
        name_so: 'Unavailable Pack SO',
        duration: 60,
        price: 100.0,
        availability: 0,
      });

      const response = await request(app)
        .get('/api/promotion-packs?availability=1')
        .expect(200);

      expect(response.body.data).toHaveLength(1);
      expect(response.body.data[0].availability).toBe(1);
    });

    it('should support sorting', async () => {
      await PromotionPack.create({
        name_en: 'Z Pack EN',
        name_so: 'Z Pack SO',
        duration: 30,
        price: 50.0,
        availability: 1,
      });
      await PromotionPack.create({
        name_en: 'A Pack EN',
        name_so: 'A Pack SO',
        duration: 60,
        price: 100.0,
        availability: 1,
      });

      const response = await request(app)
        .get('/api/promotion-packs?sortBy=name_en&sortOrder=ASC')
        .expect(200);

      expect(response.body.data[0].name_en).toBe('A Pack EN');
      expect(response.body.data[1].name_en).toBe('Z Pack EN');
    });

    it('should handle invalid page number', async () => {
      const response = await request(app)
        .get('/api/promotion-packs?page=invalid')
        .expect(400);

      expect(response.body.error).toBe('Invalid page number');
    });

    it('should handle invalid limit', async () => {
      const response = await request(app)
        .get('/api/promotion-packs?limit=200')
        .expect(400);

      expect(response.body.error).toBe('Invalid limit (1-100)');
    });
  });

  describe('GET /api/promotion-packs/:id', () => {
    it('should return a promotion pack by ID', async () => {
      const pack = await PromotionPack.create({
        name_en: 'Test Pack EN',
        name_so: 'Test Pack SO',
        duration: 30,
        price: 50.0,
        availability: 1,
      });

      const response = await request(app)
        .get(`/api/promotion-packs/${pack.id}`)
        .expect(200);

      expect(response.body.id).toBe(pack.id);
      expect(response.body.name_en).toBe('Test Pack EN');
      expect(response.body.name_so).toBe('Test Pack SO');
      expect(response.body.duration).toBe(30);
      expect(response.body.price).toBe(50.0);
      expect(response.body.availability).toBe(1);
    });

    it('should return 404 for non-existent promotion pack', async () => {
      const response = await request(app)
        .get('/api/promotion-packs/999')
        .expect(404);

      expect(response.body.error).toBe('Promotion pack not found');
    });

    it('should handle invalid ID', async () => {
      const response = await request(app)
        .get('/api/promotion-packs/invalid')
        .expect(400);

      expect(response.body.error).toBe('Invalid promotion pack ID');
    });
  });

  describe('POST /api/promotion-packs', () => {
    it('should create a new promotion pack', async () => {
      const newPack = {
        name_en: 'New Pack EN',
        name_so: 'New Pack SO',
        duration: 45,
        price: 75.5,
        availability: 1,
      };

      const response = await request(app)
        .post('/api/promotion-packs')
        .send(newPack)
        .expect(201);

      expect(response.body.message).toBe('Promotion pack created successfully');
      expect(response.body.promotionPack.name_en).toBe(newPack.name_en);
      expect(response.body.promotionPack.name_so).toBe(newPack.name_so);
      expect(response.body.promotionPack.duration).toBe(newPack.duration);
      expect(response.body.promotionPack.price).toBe(newPack.price);
      expect(response.body.promotionPack.availability).toBe(newPack.availability);
    });

    it('should create promotion pack with default availability', async () => {
      const newPack = {
        name_en: 'Default Pack EN',
        name_so: 'Default Pack SO',
        duration: 30,
        price: 50.0,
      };

      const response = await request(app)
        .post('/api/promotion-packs')
        .send(newPack)
        .expect(201);

      expect(response.body.promotionPack.availability).toBe(1); // default value
    });

    it('should validate required fields', async () => {
      const response = await request(app)
        .post('/api/promotion-packs')
        .send({})
        .expect(400);

      expect(response.body.error).toBe('name_en must be 1-255 characters');
    });

    it('should validate name_en length', async () => {
      const response = await request(app)
        .post('/api/promotion-packs')
        .send({
          name_en: '',
          name_so: 'Test SO',
          duration: 30,
          price: 50.0,
        })
        .expect(400);

      expect(response.body.error).toBe('name_en must be 1-255 characters');
    });

    it('should validate name_so length', async () => {
      const response = await request(app)
        .post('/api/promotion-packs')
        .send({
          name_en: 'Test EN',
          name_so: '',
          duration: 30,
          price: 50.0,
        })
        .expect(400);

      expect(response.body.error).toBe('name_so must be 1-255 characters');
    });

    it('should validate duration', async () => {
      const response = await request(app)
        .post('/api/promotion-packs')
        .send({
          name_en: 'Test EN',
          name_so: 'Test SO',
          duration: 0,
          price: 50.0,
        })
        .expect(400);

      expect(response.body.error).toBe('Duration must be a positive integer');
    });

    it('should validate price', async () => {
      const response = await request(app)
        .post('/api/promotion-packs')
        .send({
          name_en: 'Test EN',
          name_so: 'Test SO',
          duration: 30,
          price: -10,
        })
        .expect(400);

      expect(response.body.error).toBe('Price must be a non-negative number');
    });

    it('should validate availability', async () => {
      const response = await request(app)
        .post('/api/promotion-packs')
        .send({
          name_en: 'Test EN',
          name_so: 'Test SO',
          duration: 30,
          price: 50.0,
          availability: 2,
        })
        .expect(400);

      expect(response.body.error).toBe('Availability must be 0 or 1');
    });
  });

  describe('PUT /api/promotion-packs/:id', () => {
    let testPack;

    beforeEach(async () => {
      testPack = await PromotionPack.create({
        name_en: 'Test Pack EN',
        name_so: 'Test Pack SO',
        duration: 30,
        price: 50.0,
        availability: 1,
      });
    });

    it('should update a promotion pack', async () => {
      const updates = {
        name_en: 'Updated Pack EN',
        name_so: 'Updated Pack SO',
        duration: 60,
        price: 100.0,
        availability: 0,
      };

      const response = await request(app)
        .put(`/api/promotion-packs/${testPack.id}`)
        .send(updates)
        .expect(200);

      expect(response.body.message).toBe('Promotion pack updated successfully');
      expect(response.body.promotionPack.name_en).toBe(updates.name_en);
      expect(response.body.promotionPack.name_so).toBe(updates.name_so);
      expect(response.body.promotionPack.duration).toBe(updates.duration);
      expect(response.body.promotionPack.price).toBe(updates.price);
      expect(response.body.promotionPack.availability).toBe(updates.availability);
    });

    it('should return 404 for non-existent promotion pack', async () => {
      const response = await request(app)
        .put('/api/promotion-packs/999')
        .send({ name_en: 'Updated' })
        .expect(404);

      expect(response.body.error).toBe('Promotion pack not found');
    });

    it('should validate update data', async () => {
      const response = await request(app)
        .put(`/api/promotion-packs/${testPack.id}`)
        .send({ name_en: '' })
        .expect(400);

      expect(response.body.error).toBe('name_en must be 1-255 characters');
    });

    it('should validate duration on update', async () => {
      const response = await request(app)
        .put(`/api/promotion-packs/${testPack.id}`)
        .send({ duration: -5 })
        .expect(400);

      expect(response.body.error).toBe('Duration must be a positive integer');
    });

    it('should validate price on update', async () => {
      const response = await request(app)
        .put(`/api/promotion-packs/${testPack.id}`)
        .send({ price: -100 })
        .expect(400);

      expect(response.body.error).toBe('Price must be a non-negative number');
    });

    it('should validate availability on update', async () => {
      const response = await request(app)
        .put(`/api/promotion-packs/${testPack.id}`)
        .send({ availability: 3 })
        .expect(400);

      expect(response.body.error).toBe('Availability must be 0 or 1');
    });
  });

  describe('DELETE /api/promotion-packs/:id', () => {
    let testPack;

    beforeEach(async () => {
      testPack = await PromotionPack.create({
        name_en: 'Test Pack EN',
        name_so: 'Test Pack SO',
        duration: 30,
        price: 50.0,
        availability: 1,
      });
    });

    it('should delete a promotion pack', async () => {
      const response = await request(app)
        .delete(`/api/promotion-packs/${testPack.id}`)
        .expect(200);

      expect(response.body.message).toBe('Promotion pack deleted successfully');

      // Verify deletion
      const deleted = await PromotionPack.findByPk(testPack.id);
      expect(deleted).toBeNull();
    });

    it('should return 404 for non-existent promotion pack', async () => {
      const response = await request(app)
        .delete('/api/promotion-packs/999')
        .expect(404);

      expect(response.body.error).toBe('Promotion pack not found');
    });

    it('should handle invalid ID', async () => {
      const response = await request(app)
        .delete('/api/promotion-packs/invalid')
        .expect(400);

      expect(response.body.error).toBe('Invalid promotion pack ID');
    });
  });
});
