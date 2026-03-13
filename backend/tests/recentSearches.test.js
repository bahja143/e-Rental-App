process.env.NODE_ENV = 'test';

const request = require('supertest');
const sequelize = require('../src/config/database').sequelize;
const { RecentSearch, User, PropertyCategory } = require('../src/models');

// Mock the auth middleware to bypass authentication for tests
jest.mock('../src/middleware/authMiddleware', () => ({
  authenticateToken: (req, res, next) => {
    // Mock user for authenticated requests - use the actual user ID from the test
    req.user = { id: req.params?.id ? parseInt(req.params.id) : 1, role: 'user' };
    next();
  }
}));

describe('RecentSearches API', () => {
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
  });

  beforeEach(async () => {
    // Clear the table before each test
    await RecentSearch.destroy({ where: {} });
    await User.destroy({ where: {} });
    await PropertyCategory.destroy({ where: {} });
    // Reset SQLite auto-increment sequence
    await sequelize.query('DELETE FROM sqlite_sequence WHERE name = "recent_searches"');
    await sequelize.query('DELETE FROM sqlite_sequence WHERE name = "users"');
    await sequelize.query('DELETE FROM sqlite_sequence WHERE name = "property_categories"');
  });

  describe('POST /api/recent-searches', () => {
    it('should create a new recent search', async () => {
      const newSearch = {
        search_text: 'apartment in New York',
        latitude: 40.7128,
        longitude: -74.0060,
        radius: 10,
      };

      const response = await request(app)
        .post('/api/recent-searches')
        .send(newSearch)
        .expect(201);

      expect(response.body.search_text).toBe(newSearch.search_text);
      expect(response.body.latitude).toBe(newSearch.latitude);
      expect(response.body.longitude).toBe(newSearch.longitude);
      expect(response.body.radius).toBe(newSearch.radius);
    });

    it('should create search with user_id', async () => {
      const user = await User.create({
        name: 'Test User',
        email: 'test@example.com',
        password: 'password123',
      });

      const newSearch = {
        user_id: user.id,
        search_text: 'house for sale',
        latitude: 34.0522,
        longitude: -118.2437,
        radius: 5,
      };

      const response = await request(app)
        .post('/api/recent-searches')
        .send(newSearch)
        .expect(201);

      expect(response.body.user_id).toBe(user.id);
      expect(response.body.search_text).toBe(newSearch.search_text);
    });

    it('should create search with device_id', async () => {
      const newSearch = {
        device_id: '550e8400-e29b-41d4-a716-446655440000',
        search_text: 'condo rental',
        latitude: 41.8781,
        longitude: -87.6298,
        radius: 15,
      };

      const response = await request(app)
        .post('/api/recent-searches')
        .send(newSearch)
        .expect(201);

      expect(response.body.device_id).toBe(newSearch.device_id);
    });

    it('should create search with category_id', async () => {
      const category = await PropertyCategory.create({
        name_en: 'Apartment',
        name_so: 'Apartment',
      });

      const newSearch = {
        search_text: 'luxury apartment',
        category_id: category.id,
        latitude: 40.7128,
        longitude: -74.0060,
        radius: 20,
      };

      const response = await request(app)
        .post('/api/recent-searches')
        .send(newSearch)
        .expect(201);

      expect(response.body.category_id).toBe(category.id);
    });

    it('should validate required fields', async () => {
      const response = await request(app)
        .post('/api/recent-searches')
        .send({})
        .expect(400);

      expect(response.body.errors).toContain('search_text must be a non-empty string with max 255 characters');
      expect(response.body.errors).toContain('latitude must be a number between -90 and 90');
      expect(response.body.errors).toContain('longitude must be a number between -180 and 180');
    });

    it('should validate search_text length', async () => {
      const longText = 'a'.repeat(256);
      const response = await request(app)
        .post('/api/recent-searches')
        .send({
          search_text: longText,
          latitude: 0,
          longitude: 0,
        })
        .expect(400);

      expect(response.body.errors).toContain('search_text must be a non-empty string with max 255 characters');
    });

    it('should validate latitude range', async () => {
      const response = await request(app)
        .post('/api/recent-searches')
        .send({
          search_text: 'test',
          latitude: 100,
          longitude: 0,
        })
        .expect(400);

      expect(response.body.errors).toContain('latitude must be a number between -90 and 90');
    });

    it('should validate longitude range', async () => {
      const response = await request(app)
        .post('/api/recent-searches')
        .send({
          search_text: 'test',
          latitude: 0,
          longitude: 200,
        })
        .expect(400);

      expect(response.body.errors).toContain('longitude must be a number between -180 and 180');
    });

    it('should validate radius is non-negative', async () => {
      const response = await request(app)
        .post('/api/recent-searches')
        .send({
          search_text: 'test',
          latitude: 0,
          longitude: 0,
          radius: -5,
        })
        .expect(400);

      expect(response.body.errors).toContain('radius must be a non-negative number');
    });

    it('should validate user_id is positive integer', async () => {
      const response = await request(app)
        .post('/api/recent-searches')
        .send({
          user_id: -1,
          search_text: 'test',
          latitude: 0,
          longitude: 0,
        })
        .expect(400);

      expect(response.body.errors).toContain('user_id must be a positive integer or null');
    });

    it('should validate category_id is positive integer', async () => {
      const response = await request(app)
        .post('/api/recent-searches')
        .send({
          category_id: 0,
          search_text: 'test',
          latitude: 0,
          longitude: 0,
        })
        .expect(400);

      expect(response.body.errors).toContain('category_id must be a positive integer or null');
    });

    it('should sanitize search_text by trimming', async () => {
      const response = await request(app)
        .post('/api/recent-searches')
        .send({
          search_text: '  test search  ',
          latitude: 0,
          longitude: 0,
        })
        .expect(201);

      expect(response.body.search_text).toBe('test search');
    });
  });

  describe('GET /api/recent-searches', () => {
    beforeEach(async () => {
      // Create test data
      const user = await User.create({
        name: 'Test User',
        email: 'test@example.com',
        password: 'password123',
      });

      const category = await ListingCategory.create({
        name: 'House',
        description: 'Residential houses',
      });

      await RecentSearch.bulkCreate([
        {
          user_id: user.id,
          search_text: 'house in NYC',
          latitude: 40.7128,
          longitude: -74.0060,
          radius: 10,
          created_at: new Date('2023-01-01'),
        },
        {
          device_id: '550e8400-e29b-41d4-a716-446655440000',
          search_text: 'apartment rental',
          category_id: category.id,
          latitude: 34.0522,
          longitude: -118.2437,
          radius: 5,
          created_at: new Date('2023-01-02'),
        },
        {
          search_text: 'condo for sale',
          latitude: 41.8781,
          longitude: -87.6298,
          radius: 15,
          created_at: new Date('2023-01-03'),
        },
      ]);
    });

    it('should return recent searches with pagination', async () => {
      const response = await request(app)
        .get('/api/recent-searches')
        .expect(200);

      expect(response.body.data).toHaveLength(3);
      expect(response.body.pagination.total).toBe(3);
      expect(response.body.pagination.page).toBe(1);
      expect(response.body.pagination.limit).toBe(10);
    });

    it('should support pagination', async () => {
      // Create more searches
      const searches = [];
      for (let i = 0; i < 15; i++) {
        searches.push({
          search_text: `search ${i}`,
          latitude: 0,
          longitude: 0,
          radius: 10,
        });
      }
      await RecentSearch.bulkCreate(searches);

      const response = await request(app)
        .get('/api/recent-searches?page=2&limit=10')
        .expect(200);

      expect(response.body.data).toHaveLength(9); // 18 total - 10 on page 1 = 8 on page 2? Wait, let's check
      expect(response.body.pagination.total).toBe(18);
      expect(response.body.pagination.page).toBe(2);
    });

    it('should filter by user_id', async () => {
      const user = await User.findOne({ where: { email: 'test@example.com' } });

      const response = await request(app)
        .get(`/api/recent-searches?user_id=${user.id}`)
        .expect(200);

      expect(response.body.data).toHaveLength(1);
      expect(response.body.data[0].user_id).toBe(user.id);
    });

    it('should filter by device_id', async () => {
      const response = await request(app)
        .get('/api/recent-searches?device_id=550e8400-e29b-41d4-a716-446655440000')
        .expect(200);

      expect(response.body.data).toHaveLength(1);
      expect(response.body.data[0].device_id).toBe('550e8400-e29b-41d4-a716-446655440000');
    });

    it('should filter by category_id', async () => {
      const category = await ListingCategory.findOne({ where: { name: 'House' } });

      const response = await request(app)
        .get(`/api/recent-searches?category_id=${category.id}`)
        .expect(200);

      expect(response.body.data).toHaveLength(1);
      expect(response.body.data[0].category_id).toBe(category.id);
    });

    it('should search by search_text', async () => {
      const response = await request(app)
        .get('/api/recent-searches?search_text=house')
        .expect(200);

      expect(response.body.data).toHaveLength(1);
      expect(response.body.data[0].search_text).toBe('house in NYC');
    });

    it('should sort by created_at DESC by default', async () => {
      const response = await request(app)
        .get('/api/recent-searches')
        .expect(200);

      expect(response.body.data[0].search_text).toBe('condo for sale');
      expect(response.body.data[1].search_text).toBe('apartment rental');
      expect(response.body.data[2].search_text).toBe('house in NYC');
    });

    it('should support custom sorting', async () => {
      const response = await request(app)
        .get('/api/recent-searches?sortBy=search_text&sortOrder=ASC')
        .expect(200);

      expect(response.body.data[0].search_text).toBe('apartment rental');
      expect(response.body.data[1].search_text).toBe('condo for sale');
      expect(response.body.data[2].search_text).toBe('house in NYC');
    });

    it('should include user and category associations', async () => {
      const response = await request(app)
        .get('/api/recent-searches')
        .expect(200);

      const userSearch = response.body.data.find(s => s.user_id);
      expect(userSearch.user).toBeDefined();
      expect(userSearch.user.name).toBe('Test User');

      const categorySearch = response.body.data.find(s => s.category_id);
      expect(categorySearch.category).toBeDefined();
      expect(categorySearch.category.name).toBe('House');
    });
  });

  describe('GET /api/recent-searches/:id', () => {
    it('should return a recent search by ID', async () => {
      const search = await RecentSearch.create({
        search_text: 'test search',
        latitude: 0,
        longitude: 0,
        radius: 10,
      });

      const response = await request(app)
        .get(`/api/recent-searches/${search.id}`)
        .expect(200);

      expect(response.body.id).toBe(search.id);
      expect(response.body.search_text).toBe('test search');
    });

    it('should return 404 for non-existent search', async () => {
      const response = await request(app)
        .get('/api/recent-searches/999')
        .expect(404);

      expect(response.body.error).toBe('Recent search not found');
    });
  });

  describe('PUT /api/recent-searches/:id', () => {
    let testSearch;

    beforeEach(async () => {
      testSearch = await RecentSearch.create({
        search_text: 'original search',
        latitude: 0,
        longitude: 0,
        radius: 10,
      });
    });

    it('should update a recent search', async () => {
      const updates = {
        search_text: 'updated search',
        latitude: 10,
        longitude: 20,
        radius: 15,
      };

      const response = await request(app)
        .put(`/api/recent-searches/${testSearch.id}`)
        .send(updates)
        .expect(200);

      expect(response.body.search_text).toBe(updates.search_text);
      expect(response.body.latitude).toBe(updates.latitude);
      expect(response.body.longitude).toBe(updates.longitude);
      expect(response.body.radius).toBe(updates.radius);
    });

    it('should validate update data', async () => {
      const response = await request(app)
        .put(`/api/recent-searches/${testSearch.id}`)
        .send({ latitude: 100 })
        .expect(400);

      expect(response.body.errors).toContain('latitude must be a number between -90 and 90');
    });

    it('should return 404 for non-existent search', async () => {
      const response = await request(app)
        .put('/api/recent-searches/999')
        .send({ search_text: 'updated' })
        .expect(404);

      expect(response.body.error).toBe('Recent search not found');
    });
  });

  describe('DELETE /api/recent-searches/:id', () => {
    it('should delete a recent search', async () => {
      const search = await RecentSearch.create({
        search_text: 'test search',
        latitude: 0,
        longitude: 0,
        radius: 10,
      });

      const response = await request(app)
        .delete(`/api/recent-searches/${search.id}`)
        .expect(204);

      // Verify deletion
      const deleted = await RecentSearch.findByPk(search.id);
      expect(deleted).toBeNull();
    });

    it('should return 404 for non-existent search', async () => {
      const response = await request(app)
        .delete('/api/recent-searches/999')
        .expect(404);

      expect(response.body.error).toBe('Recent search not found');
    });
  });
});
