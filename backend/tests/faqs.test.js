process.env.NODE_ENV = 'test';

const request = require('supertest');
const { sequelize, Faq } = require('../src/models');

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

describe('Faqs API', () => {
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
    await Faq.destroy({ where: {} });
    // Reset SQLite auto-increment sequence
    await sequelize.query('DELETE FROM sqlite_sequence WHERE name = "faqs"');
  });

  describe('GET /api/faqs', () => {
    it('should return empty array when no faqs exist', async () => {
      const response = await request(app)
        .get('/api/faqs')
        .expect(200);

      expect(response.body).toHaveProperty('data');
      expect(response.body).toHaveProperty('pagination');
      expect(response.body.data).toHaveLength(0);
      expect(response.body.pagination.totalItems).toBe(0);
    });

    it('should return faqs with default pagination', async () => {
      // Create test faqs
      const faqs = [];
      for (let i = 1; i <= 15; i++) {
        faqs.push({
          title_en: `FAQ Title ${i} English`,
          title_so: `FAQ Title ${i} Somali`,
          description_en: `Description ${i} English`,
          description_so: `Description ${i} Somali`,
          type: i % 2 === 0 ? 'buyer' : 'seller',
        });
      }
      await Faq.bulkCreate(faqs);

      const response = await request(app)
        .get('/api/faqs')
        .expect(200);

      expect(response.body.data).toHaveLength(10); // Default limit
      expect(response.body.pagination.totalItems).toBe(15);
      expect(response.body.pagination.totalPages).toBe(2);
      expect(response.body.pagination.hasNextPage).toBe(true);
      expect(response.body.pagination.hasPrevPage).toBe(false);
    });

    it('should support pagination', async () => {
      // Create test faqs
      const faqs = [];
      for (let i = 1; i <= 25; i++) {
        faqs.push({
          title_en: `FAQ Title ${i}`,
          type: 'buyer',
        });
      }
      await Faq.bulkCreate(faqs);

      const response = await request(app)
        .get('/api/faqs?page=2&limit=10')
        .expect(200);

      expect(response.body.data).toHaveLength(10);
      expect(response.body.pagination.currentPage).toBe(2);
      expect(response.body.pagination.totalItems).toBe(25);
      expect(response.body.pagination.totalPages).toBe(3);
      expect(response.body.pagination.hasNextPage).toBe(true);
      expect(response.body.pagination.hasPrevPage).toBe(true);
    });

    it('should filter by type', async () => {
      await Faq.create({
        title_en: 'Buyer FAQ',
        type: 'buyer',
      });

      await Faq.create({
        title_en: 'Seller FAQ',
        type: 'seller',
      });

      const response = await request(app)
        .get('/api/faqs?type=buyer')
        .expect(200);

      expect(response.body.data).toHaveLength(1);
      expect(response.body.data[0].type).toBe('buyer');
    });

    it('should search in titles and descriptions', async () => {
      await Faq.create({
        title_en: 'How to buy property',
        description_en: 'Learn about buying',
        type: 'buyer',
      });

      await Faq.create({
        title_en: 'Seller guide',
        description_en: 'Learn about selling',
        type: 'seller',
      });

      const response = await request(app)
        .get('/api/faqs?search=buy')
        .expect(200);

      expect(response.body.data).toHaveLength(1);
      expect(response.body.data[0].title_en).toContain('buy');
    });

    it('should handle invalid type filter', async () => {
      const response = await request(app)
        .get('/api/faqs?type=invalid')
        .expect(400);

      expect(response.body.error).toBe('Invalid type. Must be buyer or seller');
    });

    it('should handle invalid page number', async () => {
      const response = await request(app)
        .get('/api/faqs?page=invalid')
        .expect(400);

      expect(response.body.error).toBe('Invalid page number');
    });

    it('should handle invalid limit', async () => {
      const response = await request(app)
        .get('/api/faqs?limit=200')
        .expect(400);

      expect(response.body.error).toBe('Invalid limit (1-100)');
    });
  });

  describe('GET /api/faqs/:id', () => {
    let testFaq;

    beforeEach(async () => {
      testFaq = await Faq.create({
        title_en: 'Test FAQ',
        description_en: 'Test description',
        type: 'buyer',
      });
    });

    it('should return a faq by ID', async () => {
      const response = await request(app)
        .get(`/api/faqs/${testFaq.id}`)
        .expect(200);

      expect(response.body.id).toBe(testFaq.id);
      expect(response.body.title_en).toBe('Test FAQ');
      expect(response.body.type).toBe('buyer');
    });

    it('should return 404 for non-existent faq', async () => {
      const response = await request(app)
        .get('/api/faqs/999')
        .expect(404);

      expect(response.body.error).toBe('Faq not found');
    });

    it('should handle invalid ID', async () => {
      const response = await request(app)
        .get('/api/faqs/invalid')
        .expect(400);

      expect(response.body.error).toBe('Invalid faq ID');
    });
  });

  describe('POST /api/faqs', () => {
    it('should create a new faq', async () => {
      const response = await request(app)
        .post('/api/faqs')
        .send({
          title_en: 'New FAQ',
          title_so: 'FAQ Cusub',
          description_en: 'New description',
          description_so: 'Sharaxaad cusub',
          type: 'buyer',
        })
        .expect(201);

      expect(response.body.message).toBe('Faq created successfully');
      expect(response.body.faq.title_en).toBe('New FAQ');
      expect(response.body.faq.type).toBe('buyer');
    });

    it('should create faq with minimal required fields', async () => {
      const response = await request(app)
        .post('/api/faqs')
        .send({
          title_en: 'Minimal FAQ',
          type: 'seller',
        })
        .expect(201);

      expect(response.body.faq.title_en).toBe('Minimal FAQ');
      expect(response.body.faq.title_so).toBeNull();
      expect(response.body.faq.description_en).toBeNull();
      expect(response.body.faq.description_so).toBeNull();
    });

    it('should trim whitespace from titles', async () => {
      const response = await request(app)
        .post('/api/faqs')
        .send({
          title_en: '  FAQ with spaces  ',
          type: 'buyer',
        })
        .expect(201);

      expect(response.body.faq.title_en).toBe('FAQ with spaces');
    });

    it('should validate required title_en', async () => {
      const response = await request(app)
        .post('/api/faqs')
        .send({
          type: 'buyer',
        })
        .expect(400);

      expect(response.body.error).toBe('title_en is required and must be a non-empty string');
    });

    it('should validate title_en length', async () => {
      const longTitle = 'a'.repeat(256);
      const response = await request(app)
        .post('/api/faqs')
        .send({
          title_en: longTitle,
          type: 'buyer',
        })
        .expect(400);

      expect(response.body.error).toBe('title_en must be 255 characters or less');
    });

    it('should validate title_so length', async () => {
      const longTitle = 'a'.repeat(256);
      const response = await request(app)
        .post('/api/faqs')
        .send({
          title_en: 'Valid title',
          title_so: longTitle,
          type: 'buyer',
        })
        .expect(400);

      expect(response.body.error).toBe('title_so must be a string of 255 characters or less');
    });

    it('should validate type', async () => {
      const response = await request(app)
        .post('/api/faqs')
        .send({
          title_en: 'Test FAQ',
          type: 'invalid',
        })
        .expect(400);

      expect(response.body.error).toBe('type is required and must be either buyer or seller');
    });

    it('should validate description types', async () => {
      const response = await request(app)
        .post('/api/faqs')
        .send({
          title_en: 'Test FAQ',
          description_en: 123,
          type: 'buyer',
        })
        .expect(400);

      expect(response.body.error).toBe('description_en must be a string');
    });
  });

  describe('PUT /api/faqs/:id', () => {
    let testFaq;

    beforeEach(async () => {
      testFaq = await Faq.create({
        title_en: 'Original FAQ',
        description_en: 'Original description',
        type: 'buyer',
      });
    });

    it('should update a faq', async () => {
      const response = await request(app)
        .put(`/api/faqs/${testFaq.id}`)
        .send({
          title_en: 'Updated FAQ',
          type: 'seller',
        })
        .expect(200);

      expect(response.body.message).toBe('Faq updated successfully');
      expect(response.body.faq.title_en).toBe('Updated FAQ');
      expect(response.body.faq.type).toBe('seller');
    });

    it('should allow setting fields to null', async () => {
      const response = await request(app)
        .put(`/api/faqs/${testFaq.id}`)
        .send({
          title_so: null,
          description_en: null,
          description_so: null,
        })
        .expect(200);

      expect(response.body.faq.title_so).toBeNull();
      expect(response.body.faq.description_en).toBeNull();
      expect(response.body.faq.description_so).toBeNull();
    });

    it('should return 404 for non-existent faq', async () => {
      const response = await request(app)
        .put('/api/faqs/999')
        .send({
          title_en: 'Updated',
        })
        .expect(404);

      expect(response.body.error).toBe('Faq not found');
    });

    it('should validate title_en on update', async () => {
      const response = await request(app)
        .put(`/api/faqs/${testFaq.id}`)
        .send({
          title_en: '',
        })
        .expect(400);

      expect(response.body.error).toBe('title_en must be a non-empty string');
    });

    it('should validate type on update', async () => {
      const response = await request(app)
        .put(`/api/faqs/${testFaq.id}`)
        .send({
          type: 'invalid',
        })
        .expect(400);

      expect(response.body.error).toBe('type must be either buyer or seller');
    });

    it('should handle no fields to update', async () => {
      const response = await request(app)
        .put(`/api/faqs/${testFaq.id}`)
        .send({})
        .expect(400);

      expect(response.body.error).toBe('No valid fields to update');
    });
  });

  describe('DELETE /api/faqs/:id', () => {
    let testFaq;

    beforeEach(async () => {
      testFaq = await Faq.create({
        title_en: 'Test FAQ',
        type: 'buyer',
      });
    });

    it('should delete a faq', async () => {
      const response = await request(app)
        .delete(`/api/faqs/${testFaq.id}`)
        .expect(200);

      expect(response.body.message).toBe('Faq deleted successfully');

      // Verify deletion
      const deleted = await Faq.findByPk(testFaq.id);
      expect(deleted).toBeNull();
    });

    it('should return 404 for non-existent faq', async () => {
      const response = await request(app)
        .delete('/api/faqs/999')
        .expect(404);

      expect(response.body.error).toBe('Faq not found');
    });

    it('should handle invalid ID', async () => {
      const response = await request(app)
        .delete('/api/faqs/invalid')
        .expect(400);

      expect(response.body.error).toBe('Invalid faq ID');
    });
  });
});
