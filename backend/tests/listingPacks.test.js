process.env.NODE_ENV = 'test';

const request = require('supertest');
const { sequelize, ListingPack } = require('../src/models');

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

describe('ListingPacks API', () => {
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
    await ListingPack.destroy({ where: {} });
    // Reset SQLite auto-increment sequence
    await sequelize.query('DELETE FROM sqlite_sequence WHERE name = "listing_packs"');
  });

  describe('GET /api/listing-packs', () => {
    it('should return empty array when no listing packs exist', async () => {
      const response = await request(app)
        .get('/api/listing-packs')
        .expect(200);

      expect(response.body).toHaveProperty('data');
      expect(response.body).toHaveProperty('pagination');
      expect(response.body.data).toHaveLength(0);
      expect(response.body.pagination.totalItems).toBe(0);
    });

    it('should return listing packs with default pagination', async () => {
      // Create test listing packs
      const packs = [];
      for (let i = 1; i <= 15; i++) {
        packs.push({
          name_en: `Pack ${i} EN`,
          name_so: `Pack ${i} SO`,
          price: i * 100,
          duration: i,
          features: { feature1: `value${i}` },
          listing_amount: i * 5,
          display: i % 2,
        });
      }
      await ListingPack.bulkCreate(packs);

      const response = await request(app)
        .get('/api/listing-packs')
        .expect(200);

      expect(response.body.data).toHaveLength(10); // Default limit
      expect(response.body.pagination.totalItems).toBe(15);
      expect(response.body.pagination.totalPages).toBe(2);
      expect(response.body.pagination.currentPage).toBe(1);
      expect(response.body.pagination.hasNextPage).toBe(true);
      expect(response.body.pagination.hasPrevPage).toBe(false);
    });

    it('should support pagination', async () => {
      // Create test listing packs
      const packs = [];
      for (let i = 1; i <= 25; i++) {
        packs.push({
          name_en: `Pack ${i} EN`,
          name_so: `Pack ${i} SO`,
          price: i * 100,
          duration: i,
          features: {},
          listing_amount: i * 5,
          display: 1,
        });
      }
      await ListingPack.bulkCreate(packs);

      const response = await request(app)
        .get('/api/listing-packs?page=2&limit=10')
        .expect(200);

      expect(response.body.data).toHaveLength(10);
      expect(response.body.pagination.totalItems).toBe(25);
      expect(response.body.pagination.currentPage).toBe(2);
      expect(response.body.pagination.hasNextPage).toBe(true);
      expect(response.body.pagination.hasPrevPage).toBe(true);
    });

    it('should support search functionality', async () => {
      await ListingPack.create({
        name_en: 'Basic Pack EN',
        name_so: 'Basic Pack SO',
        price: 5000,
        duration: 30,
        features: {},
        listing_amount: 10,
        display: 1,
      });
      await ListingPack.create({
        name_en: 'Premium Pack EN',
        name_so: 'Premium Pack SO',
        price: 10000,
        duration: 60,
        features: {},
        listing_amount: 20,
        display: 1,
      });
      await ListingPack.create({
        name_en: 'Standard Pack EN',
        name_so: 'Standard Pack SO',
        price: 7500,
        duration: 45,
        features: {},
        listing_amount: 15,
        display: 1,
      });

      const response = await request(app)
        .get('/api/listing-packs?search=premium')
        .expect(200);

      expect(response.body.data).toHaveLength(1);
      expect(response.body.data[0].name_en).toBe('Premium Pack EN');
    });

    it('should support duration filtering', async () => {
      await ListingPack.create({
        name_en: 'Short Pack EN',
        name_so: 'Short Pack SO',
        price: 5000,
        duration: 30,
        features: {},
        listing_amount: 10,
        display: 1,
      });
      await ListingPack.create({
        name_en: 'Long Pack EN',
        name_so: 'Long Pack SO',
        price: 10000,
        duration: 60,
        features: {},
        listing_amount: 20,
        display: 1,
      });

      const response = await request(app)
        .get('/api/listing-packs?duration=30')
        .expect(200);

      expect(response.body.data).toHaveLength(1);
      expect(response.body.data[0].duration).toBe(30);
    });

    it('should support price range filtering', async () => {
      await ListingPack.create({
        name_en: 'Cheap Pack EN',
        name_so: 'Cheap Pack SO',
        price: 2500,
        duration: 30,
        features: {},
        listing_amount: 5,
        display: 1,
      });
      await ListingPack.create({
        name_en: 'Expensive Pack EN',
        name_so: 'Expensive Pack SO',
        price: 15000,
        duration: 60,
        features: {},
        listing_amount: 30,
        display: 1,
      });
      await ListingPack.create({
        name_en: 'Medium Pack EN',
        name_so: 'Medium Pack SO',
        price: 7500,
        duration: 45,
        features: {},
        listing_amount: 15,
        display: 1,
      });

      const response = await request(app)
        .get('/api/listing-packs?price_min=5000&price_max=10000')
        .expect(200);

      expect(response.body.data).toHaveLength(1);
      expect(response.body.data[0].price).toBe(7500);
    });

    it('should support listing_amount filtering', async () => {
      await ListingPack.create({
        name_en: 'Small Pack EN',
        name_so: 'Small Pack SO',
        price: 5000,
        duration: 30,
        features: {},
        listing_amount: 5,
        display: 1,
      });
      await ListingPack.create({
        name_en: 'Large Pack EN',
        name_so: 'Large Pack SO',
        price: 10000,
        duration: 60,
        features: {},
        listing_amount: 20,
        display: 1,
      });

      const response = await request(app)
        .get('/api/listing-packs?listing_amount=5')
        .expect(200);

      expect(response.body.data).toHaveLength(1);
      expect(response.body.data[0].listing_amount).toBe(5);
    });

    it('should support display filtering', async () => {
      await ListingPack.create({
        name_en: 'Visible Pack EN',
        name_so: 'Visible Pack SO',
        price: 5000,
        duration: 30,
        features: {},
        listing_amount: 10,
        display: 1,
      });
      await ListingPack.create({
        name_en: 'Hidden Pack EN',
        name_so: 'Hidden Pack SO',
        price: 10000,
        duration: 60,
        features: {},
        listing_amount: 20,
        display: 0,
      });

      const response = await request(app)
        .get('/api/listing-packs?display=1')
        .expect(200);

      expect(response.body.data).toHaveLength(1);
      expect(response.body.data[0].display).toBe(1);
    });

    it('should support sorting', async () => {
      await ListingPack.create({
        name_en: 'Z Pack EN',
        name_so: 'Z Pack SO',
        price: 5000,
        duration: 30,
        features: {},
        listing_amount: 10,
        display: 1,
      });
      await ListingPack.create({
        name_en: 'A Pack EN',
        name_so: 'A Pack SO',
        price: 10000,
        duration: 60,
        features: {},
        listing_amount: 20,
        display: 1,
      });

      const response = await request(app)
        .get('/api/listing-packs?sortBy=name_en&sortOrder=ASC')
        .expect(200);

      expect(response.body.data[0].name_en).toBe('A Pack EN');
      expect(response.body.data[1].name_en).toBe('Z Pack EN');
    });

    it('should handle invalid page number', async () => {
      const response = await request(app)
        .get('/api/listing-packs?page=invalid')
        .expect(400);

      expect(response.body.error).toBe('Invalid page number');
    });

    it('should handle invalid limit', async () => {
      const response = await request(app)
        .get('/api/listing-packs?limit=200')
        .expect(400);

      expect(response.body.error).toBe('Invalid limit (1-100)');
    });
  });

  describe('GET /api/listing-packs/:id', () => {
    it('should return a listing pack by ID', async () => {
      const pack = await ListingPack.create({
        name_en: 'Test Pack EN',
        name_so: 'Test Pack SO',
        price: 5000,
        duration: 30,
        features: { test: 'feature' },
        listing_amount: 10,
        display: 1,
      });

      const response = await request(app)
        .get(`/api/listing-packs/${pack.id}`)
        .expect(200);

      expect(response.body.id).toBe(pack.id);
      expect(response.body.name_en).toBe('Test Pack EN');
      expect(response.body.name_so).toBe('Test Pack SO');
      expect(response.body.price).toBe(5000);
      expect(response.body.duration).toBe(30);
      expect(response.body.features).toEqual({ test: 'feature' });
      expect(response.body.listing_amount).toBe(10);
      expect(response.body.display).toBe(1);
    });

    it('should return 404 for non-existent listing pack', async () => {
      const response = await request(app)
        .get('/api/listing-packs/999')
        .expect(404);

      expect(response.body.error).toBe('Listing pack not found');
    });

    it('should handle invalid ID', async () => {
      const response = await request(app)
        .get('/api/listing-packs/invalid')
        .expect(400);

      expect(response.body.error).toBe('Invalid listing pack ID');
    });
  });

  describe('POST /api/listing-packs', () => {
    it('should create a new listing pack', async () => {
      const newPack = {
        name_en: 'New Pack EN',
        name_so: 'New Pack SO',
        price: 7500,
        duration: 45,
        features: { feature1: 'value1' },
        listing_amount: 15,
        display: 1,
      };

      const response = await request(app)
        .post('/api/listing-packs')
        .send(newPack)
        .expect(201);

      expect(response.body.message).toBe('Listing pack created successfully');
      expect(response.body.listingPack.name_en).toBe(newPack.name_en);
      expect(response.body.listingPack.name_so).toBe(newPack.name_so);
      expect(response.body.listingPack.price).toBe(newPack.price);
      expect(response.body.listingPack.duration).toBe(newPack.duration);
      expect(response.body.listingPack.features).toEqual(newPack.features);
      expect(response.body.listingPack.listing_amount).toBe(newPack.listing_amount);
      expect(response.body.listingPack.display).toBe(newPack.display);
    });

    it('should create listing pack with default display', async () => {
      const newPack = {
        name_en: 'Default Pack EN',
        name_so: 'Default Pack SO',
        price: 5000,
        duration: 30,
        features: {},
        listing_amount: 10,
      };

      const response = await request(app)
        .post('/api/listing-packs')
        .send(newPack)
        .expect(201);

      expect(response.body.listingPack.display).toBe(1); // default value
    });

    it('should validate required fields', async () => {
      const response = await request(app)
        .post('/api/listing-packs')
        .send({})
        .expect(400);

      expect(response.body.error).toBe('name_en must be 1-255 characters');
    });

    it('should validate name_en length', async () => {
      const response = await request(app)
        .post('/api/listing-packs')
        .send({
          name_en: '',
          name_so: 'Test SO',
          price: 5000,
          duration: 30,
          features: {},
          listing_amount: 10,
        })
        .expect(400);

      expect(response.body.error).toBe('name_en must be 1-255 characters');
    });

    it('should validate name_so length', async () => {
      const response = await request(app)
        .post('/api/listing-packs')
        .send({
          name_en: 'Test EN',
          name_so: '',
          price: 5000,
          duration: 30,
          features: {},
          listing_amount: 10,
        })
        .expect(400);

      expect(response.body.error).toBe('name_so must be 1-255 characters');
    });

    it('should validate price', async () => {
      const response = await request(app)
        .post('/api/listing-packs')
        .send({
          name_en: 'Test EN',
          name_so: 'Test SO',
          price: -100,
          duration: 30,
          features: {},
          listing_amount: 10,
        })
        .expect(400);

      expect(response.body.error).toBe('Price must be a non-negative integer');
    });

    it('should validate duration', async () => {
      const response = await request(app)
        .post('/api/listing-packs')
        .send({
          name_en: 'Test EN',
          name_so: 'Test SO',
          price: 5000,
          duration: 0,
          features: {},
          listing_amount: 10,
        })
        .expect(400);

      expect(response.body.error).toBe('Duration must be a positive integer');
    });

    it('should validate listing_amount', async () => {
      const response = await request(app)
        .post('/api/listing-packs')
        .send({
          name_en: 'Test EN',
          name_so: 'Test SO',
          price: 5000,
          duration: 30,
          features: {},
          listing_amount: -5,
        })
        .expect(400);

      expect(response.body.error).toBe('Listing amount must be a non-negative integer');
    });

    it('should validate display', async () => {
      const response = await request(app)
        .post('/api/listing-packs')
        .send({
          name_en: 'Test EN',
          name_so: 'Test SO',
          price: 5000,
          duration: 30,
          features: {},
          listing_amount: 10,
          display: 2,
        })
        .expect(400);

      expect(response.body.error).toBe('Display must be 0 or 1');
    });

    it('should validate features is an object', async () => {
      const response = await request(app)
        .post('/api/listing-packs')
        .send({
          name_en: 'Test EN',
          name_so: 'Test SO',
          price: 5000,
          duration: 30,
          features: 'invalid',
          listing_amount: 10,
        })
        .expect(400);

      expect(response.body.error).toBe('Features must be a valid JSON object');
    });
  });

  describe('PUT /api/listing-packs/:id', () => {
    let testPack;

    beforeEach(async () => {
      testPack = await ListingPack.create({
        name_en: 'Test Pack EN',
        name_so: 'Test Pack SO',
        price: 5000,
        duration: 30,
        features: { test: 'feature' },
        listing_amount: 10,
        display: 1,
      });
    });

    it('should update a listing pack', async () => {
      const updates = {
        name_en: 'Updated Pack EN',
        name_so: 'Updated Pack SO',
        price: 10000,
        duration: 60,
        features: { updated: 'feature' },
        listing_amount: 20,
        display: 0,
      };

      const response = await request(app)
        .put(`/api/listing-packs/${testPack.id}`)
        .send(updates)
        .expect(200);

      expect(response.body.message).toBe('Listing pack updated successfully');
      expect(response.body.listingPack.name_en).toBe(updates.name_en);
      expect(response.body.listingPack.name_so).toBe(updates.name_so);
      expect(response.body.listingPack.price).toBe(updates.price);
      expect(response.body.listingPack.duration).toBe(updates.duration);
      expect(response.body.listingPack.features).toEqual(updates.features);
      expect(response.body.listingPack.listing_amount).toBe(updates.listing_amount);
      expect(response.body.listingPack.display).toBe(updates.display);
    });

    it('should return 404 for non-existent listing pack', async () => {
      const response = await request(app)
        .put('/api/listing-packs/999')
        .send({ name_en: 'Updated' })
        .expect(404);

      expect(response.body.error).toBe('Listing pack not found');
    });

    it('should validate update data', async () => {
      const response = await request(app)
        .put(`/api/listing-packs/${testPack.id}`)
        .send({ name_en: '' })
        .expect(400);

      expect(response.body.error).toBe('name_en must be 1-255 characters');
    });

    it('should validate duration on update', async () => {
      const response = await request(app)
        .put(`/api/listing-packs/${testPack.id}`)
        .send({ duration: -5 })
        .expect(400);

      expect(response.body.error).toBe('Duration must be a positive integer');
    });

    it('should validate price on update', async () => {
      const response = await request(app)
        .put(`/api/listing-packs/${testPack.id}`)
        .send({ price: -1000 })
        .expect(400);

      expect(response.body.error).toBe('Price must be a non-negative integer');
    });

    it('should validate listing_amount on update', async () => {
      const response = await request(app)
        .put(`/api/listing-packs/${testPack.id}`)
        .send({ listing_amount: -10 })
        .expect(400);

      expect(response.body.error).toBe('Listing amount must be a non-negative integer');
    });

    it('should validate display on update', async () => {
      const response = await request(app)
        .put(`/api/listing-packs/${testPack.id}`)
        .send({ display: 3 })
        .expect(400);

      expect(response.body.error).toBe('Display must be 0 or 1');
    });

    it('should validate features on update', async () => {
      const response = await request(app)
        .put(`/api/listing-packs/${testPack.id}`)
        .send({ features: 'invalid' })
        .expect(400);

      expect(response.body.error).toBe('Features must be a valid JSON object');
    });
  });

  describe('DELETE /api/listing-packs/:id', () => {
    let testPack;

    beforeEach(async () => {
      testPack = await ListingPack.create({
        name_en: 'Test Pack EN',
        name_so: 'Test Pack SO',
        price: 5000,
        duration: 30,
        features: {},
        listing_amount: 10,
        display: 1,
      });
    });

    it('should delete a listing pack', async () => {
      const response = await request(app)
        .delete(`/api/listing-packs/${testPack.id}`)
        .expect(200);

      expect(response.body.message).toBe('Listing pack deleted successfully');

      // Verify deletion
      const deleted = await ListingPack.findByPk(testPack.id);
      expect(deleted).toBeNull();
    });

    it('should return 404 for non-existent listing pack', async () => {
      const response = await request(app)
        .delete('/api/listing-packs/999')
        .expect(404);

      expect(response.body.error).toBe('Listing pack not found');
    });

    it('should handle invalid ID', async () => {
      const response = await request(app)
        .delete('/api/listing-packs/invalid')
        .expect(400);

      expect(response.body.error).toBe('Invalid listing pack ID');
    });
  });
});
