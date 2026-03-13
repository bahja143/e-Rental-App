process.env.NODE_ENV = 'test';

const request = require('supertest');
const { sequelize, ListingCategory, Listing, PropertyCategory, User } = require('../src/models');
const mongoose = require('mongoose');

// Mock the authentication middleware to bypass auth for tests
jest.mock('../src/middleware/authMiddleware', () => ({
  authenticateToken: (req, res, next) => {
    req.user = { id: 1, role: 'user' };
    next();
  }
}));

// Mock Bull queues (so they don’t interfere during tests)
jest.mock('../src/queues', () => ({
  emailQueue: {
    add: jest.fn(),
    close: jest.fn(),
  },
  emailWorker: {
    close: jest.fn(),
  },
}));

describe('ListingCategories API', () => {
  let app;
  let server;

  beforeAll(async () => {
    app = require('../src/app');
    await sequelize.sync({ force: true });
    server = app.listen(0); // Use random free port
  });

  afterAll(async () => {
    if (server) server.close();
    await sequelize.close();
    await mongoose.connection.close();
  });

  beforeEach(async () => {
    // Clear all tables before each test
    await ListingCategory.destroy({ where: {} });
    await Listing.destroy({ where: {} });
    await PropertyCategory.destroy({ where: {} });
    await User.destroy({ where: {} });

    // Reset SQLite auto-increment sequences (if using SQLite)
    if (sequelize.getDialect() === 'sqlite') {
      await sequelize.query("DELETE FROM sqlite_sequence WHERE name='listing_categories'");
      await sequelize.query("DELETE FROM sqlite_sequence WHERE name='listings'");
      await sequelize.query("DELETE FROM sqlite_sequence WHERE name='property_categories'");
      await sequelize.query("DELETE FROM sqlite_sequence WHERE name='users'");
    } else {
      // PostgreSQL syntax
      await sequelize.query('ALTER SEQUENCE listing_categories_id_seq RESTART WITH 1');
      await sequelize.query('ALTER SEQUENCE listings_id_seq RESTART WITH 1');
      await sequelize.query('ALTER SEQUENCE property_categories_id_seq RESTART WITH 1');
      await sequelize.query('ALTER SEQUENCE users_id_seq RESTART WITH 1');
    }
  });

  // Helper function to create a listing with location
  const createListing = async (userId, title, lat, lng, address) => {
    return await Listing.create({
      user_id: userId,
      title,
      lat,
      lng,
      address,
      location: { type: 'Point', coordinates: [lng, lat] },
    });
  };

  // ===========================================================
  // GET /api/listing-categories
  // ===========================================================
  describe('GET /api/listing-categories', () => {
    it('should return empty array when no listing categories exist', async () => {
      const response = await request(app).get('/api/listing-categories').expect(200);
      expect(response.body).toHaveProperty('data');
      expect(response.body.data).toHaveLength(0);
      expect(response.body.pagination.totalItems).toBe(0);
    });

    it('should return listing categories with default pagination', async () => {
      const user = await User.create({ name: 'User', email: 'u@example.com', password: 'pass123' });
      const listing = await createListing(user.id, 'Listing', 0, 0, 'Test');

      for (let i = 1; i <= 15; i++) {
        const cat = await PropertyCategory.create({ name_en: `Cat ${i}`, name_so: `Cat So ${i}` });
        await ListingCategory.create({ listing_id: listing.id, property_category_id: cat.id });
      }

      const res = await request(app).get('/api/listing-categories').expect(200);
      expect(res.body.data).toHaveLength(10);
      expect(res.body.pagination.totalItems).toBe(15);
      expect(res.body.pagination.currentPage).toBe(1);
      expect(res.body.pagination.hasNextPage).toBe(true);
    });

    it('should support pagination', async () => {
      const user = await User.create({ name: 'User', email: 'u@example.com', password: 'pass123' });
      const listing = await createListing(user.id, 'Listing', 0, 0, 'Test');

      for (let i = 1; i <= 25; i++) {
        const cat = await PropertyCategory.create({ name_en: `Cat ${i}`, name_so: `Cat So ${i}` });
        await ListingCategory.create({ listing_id: listing.id, property_category_id: cat.id });
      }

      const res = await request(app).get('/api/listing-categories?page=2&limit=10').expect(200);
      expect(res.body.data).toHaveLength(10);
      expect(res.body.pagination.currentPage).toBe(2);
      expect(res.body.pagination.hasPrevPage).toBe(true);
    });

    it('should filter by listing_id', async () => {
      const user = await User.create({ name: 'User', email: 'u@example.com', password: 'pass123' });
      const listing1 = await createListing(user.id, 'L1', 0, 0, 'A1');
      const listing2 = await createListing(user.id, 'L2', 0, 0, 'A2');
      const cat = await PropertyCategory.create({ name_en: 'Apartment', name_so: 'So' });

      await ListingCategory.create({ listing_id: listing1.id, property_category_id: cat.id });
      await ListingCategory.create({ listing_id: listing2.id, property_category_id: cat.id });

      const res = await request(app).get(`/api/listing-categories?listing_id=${listing1.id}`).expect(200);
      expect(res.body.data).toHaveLength(1);
      expect(res.body.data[0].listing_id).toBe(listing1.id);
    });

    it('should filter by property_category_id', async () => {
      const user = await User.create({ name: 'User', email: 'u@example.com', password: 'pass123' });
      const listing = await createListing(user.id, 'Listing', 0, 0, 'Test');
      const cat1 = await PropertyCategory.create({ name_en: 'A', name_so: 'SoA' });
      const cat2 = await PropertyCategory.create({ name_en: 'B', name_so: 'SoB' });

      await ListingCategory.create({ listing_id: listing.id, property_category_id: cat1.id });
      await ListingCategory.create({ listing_id: listing.id, property_category_id: cat2.id });

      const res = await request(app).get(`/api/listing-categories?property_category_id=${cat1.id}`).expect(200);
      expect(res.body.data).toHaveLength(1);
      expect(res.body.data[0].property_category_id).toBe(cat1.id);
    });

    it('should support sorting', async () => {
      const user = await User.create({ name: 'User', email: 'u@example.com', password: 'pass123' });
      const listing = await createListing(user.id, 'Listing', 0, 0, 'Test');
      const cat1 = await PropertyCategory.create({ name_en: 'Z', name_so: 'SoZ' });
      const cat2 = await PropertyCategory.create({ name_en: 'A', name_so: 'SoA' });

      await ListingCategory.create({ listing_id: listing.id, property_category_id: cat1.id });
      await ListingCategory.create({ listing_id: listing.id, property_category_id: cat2.id });

      const res = await request(app).get('/api/listing-categories?sortBy=id&sortOrder=DESC').expect(200);
      expect(res.body.data[0].id).toBeGreaterThan(res.body.data[1].id);
    });

    it('should handle invalid page or limit', async () => {
      const res1 = await request(app).get('/api/listing-categories?page=invalid').expect(400);
      expect(res1.body.error).toBe('Invalid page number');

      const res2 = await request(app).get('/api/listing-categories?limit=200').expect(400);
      expect(res2.body.error).toBe('Invalid limit (1-100)');
    });
  });

  // ===========================================================
  // GET /api/listing-categories/:id
  // ===========================================================
  describe('GET /api/listing-categories/:id', () => {
    it('should return a single listing category by ID', async () => {
      const user = await User.create({ name: 'User', email: 'u@example.com', password: 'pass123' });
      const listing = await createListing(user.id, 'Listing', 0, 0, 'Test');
      const cat = await PropertyCategory.create({ name_en: 'Apartment', name_so: 'So' });

      const lc = await ListingCategory.create({ listing_id: listing.id, property_category_id: cat.id });

      const res = await request(app).get(`/api/listing-categories/${lc.id}`).expect(200);
      expect(res.body.id).toBe(lc.id);
      expect(res.body.listing_id).toBe(listing.id);
    });

    it('should return 404 if not found', async () => {
      const res = await request(app).get('/api/listing-categories/999').expect(404);
      expect(res.body.error).toBe('Listing category not found');
    });

    it('should handle invalid ID', async () => {
      const res = await request(app).get('/api/listing-categories/invalid').expect(400);
      expect(res.body.error).toBe('Invalid listing category ID');
    });
  });

  // ===========================================================
  // POST /api/listing-categories
  // ===========================================================
  describe('POST /api/listing-categories', () => {
        it('should create a new listing category', async () => {
      const user = await User.create({ name: 'User', email: 'u@example.com', password: 'pass123' });
      const listing = await createListing(user.id, 'Listing', 0, 0, 'Test');
      const cat = await PropertyCategory.create({ name_en: 'Apartment', name_so: 'So' });

      const res = await request(app)
        .post('/api/listing-categories')
        .send({
          listing_id: listing.id,
          property_category_id: cat.id,
        })
        .expect(201);

      expect(res.body.listingCategory).toHaveProperty('id');
      expect(res.body.listingCategory.listing_id).toBe(listing.id);
      expect(res.body.listingCategory.property_category_id).toBe(cat.id);
    });

    it('should return 400 if required fields are missing', async () => {
      const res = await request(app)
        .post('/api/listing-categories')
        .send({})
        .expect(400);

      expect(res.body.error).toBe('Valid listing_id is required');
    });
  });

  // ===========================================================
  // PUT /api/listing-categories/:id
  // ===========================================================
  describe('PUT /api/listing-categories/:id', () => {
    it('should update a listing category', async () => {
      const user = await User.create({ name: 'User', email: 'u@example.com', password: 'pass123' });
      const listing1 = await createListing(user.id, 'Listing1', 0, 0, 'Test1');
      const listing2 = await createListing(user.id, 'Listing2', 1, 1, 'Test2');
      const cat1 = await PropertyCategory.create({ name_en: 'Apartment', name_so: 'So' });
      const cat2 = await PropertyCategory.create({ name_en: 'House', name_so: 'SoH' });

      const lc = await ListingCategory.create({ listing_id: listing1.id, property_category_id: cat1.id });

      const res = await request(app)
        .put(`/api/listing-categories/${lc.id}`)
        .send({
          listing_id: listing2.id,
          property_category_id: cat2.id,
        })
        .expect(200);

      expect(res.body.listingCategory.listing_id).toBe(listing2.id);
      expect(res.body.listingCategory.property_category_id).toBe(cat2.id);
    });

    it('should return 404 if listing category not found', async () => {
      const res = await request(app)
        .put('/api/listing-categories/999')
        .send({
          listing_id: 1,
          property_category_id: 1,
        })
        .expect(404);

      expect(res.body.error).toBe('Listing category not found');
    });

    it('should return 409 if association already exists', async () => {
      const user = await User.create({ name: 'User', email: 'u@example.com', password: 'pass123' });
      const listing1 = await createListing(user.id, 'Listing1', 0, 0, 'Test1');
      const listing2 = await createListing(user.id, 'Listing2', 1, 1, 'Test2');
      const cat1 = await PropertyCategory.create({ name_en: 'Apartment', name_so: 'So' });
      const cat2 = await PropertyCategory.create({ name_en: 'House', name_so: 'SoH' });

      const lc1 = await ListingCategory.create({ listing_id: listing1.id, property_category_id: cat1.id });
      await ListingCategory.create({ listing_id: listing2.id, property_category_id: cat2.id });

      const res = await request(app)
        .put(`/api/listing-categories/${lc1.id}`)
        .send({
          listing_id: listing2.id,
          property_category_id: cat2.id,
        })
        .expect(409);

      expect(res.body.error).toBe('This listing-category association already exists');
    });
  });
});
