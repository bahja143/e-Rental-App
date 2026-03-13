process.env.NODE_ENV = 'test';
process.env.JWT_SECRET = 'test-secret';

const request = require('supertest');
const { sequelize, StateCategory } = require('../src/models');
const jwt = require('jsonwebtoken');



describe('State Categories API', () => {
  let app;
  let server;
  let authToken;

  beforeAll(async () => {
    // Create a test app with in-memory database
    const express = require('express');
    const cors = require('cors');
    const helmet = require('helmet');
    const morgan = require('morgan');
    const rateLimit = require('express-rate-limit');

    app = express();

    // Middleware
    app.use(helmet());
    app.use(cors());
    app.use(morgan('combined'));
    app.use(express.json());
    app.use(express.urlencoded({ extended: true }));

    // Rate limiting (disabled for tests)
    const limiter = rateLimit({
      windowMs: 15 * 60 * 1000,
      max: 100,
      message: 'Too many requests from this IP, please try again later.',
      standardHeaders: true,
      legacyHeaders: false,
      skip: () => true, // Skip rate limiting for tests
    });
    app.use(limiter);

    // Sync the in-memory database
    await sequelize.sync({ force: true });

    // Create a test JWT token
    const payload = { id: 1, email: 'test@example.com' };
    authToken = jwt.sign(payload, process.env.JWT_SECRET || 'test-secret', { expiresIn: '1h' });

    // Import and use the stateCategories routes
    const stateCategoriesRouter = require('../src/routes/stateCategories');
    app.use('/api/state-categories', stateCategoriesRouter);

    // Basic route
    app.get('/', (req, res) => {
      res.json({ message: 'Welcome to Hantario API' });
    });

    server = app.listen(0); // Use random available port
  });

  afterAll(async () => {
    if (server) {
      server.close();
    }
    await sequelize.close();
  });

  beforeEach(async () => {
    // Clear the table before each test
    await StateCategory.destroy({ where: {} });
  });

  describe('GET /api/state-categories', () => {
    it('should return empty array when no categories exist', async () => {
      const response = await request(app)
        .get('/api/state-categories')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body).toHaveProperty('data');
      expect(response.body).toHaveProperty('pagination');
      expect(response.body.data).toEqual([]);
      expect(response.body.pagination.totalItems).toBe(0);
    });

    it('should return categories with default pagination', async () => {
      // Create test data
      await StateCategory.bulkCreate([
        { name_en: 'Category 1', name_so: 'Qaybta 1' },
        { name_en: 'Category 2', name_so: 'Qaybta 2' },
        { name_en: 'Category 3', name_so: 'Qaybta 3' },
      ]);

      const response = await request(app)
        .get('/api/state-categories')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.data).toHaveLength(3);
      expect(response.body.pagination.totalItems).toBe(3);
      expect(response.body.pagination.currentPage).toBe(1);
      expect(response.body.pagination.totalPages).toBe(1);
    });

    it('should support pagination', async () => {
      // Create 15 categories
      const categories = [];
      for (let i = 1; i <= 15; i++) {
        categories.push({
          name_en: `Category ${i}`,
          name_so: `Qaybta ${i}`
        });
      }
      await StateCategory.bulkCreate(categories);

      // Test page 1 with limit 5
      const response = await request(app)
        .get('/api/state-categories?page=1&limit=5')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.data).toHaveLength(5);
      expect(response.body.pagination.totalItems).toBe(15);
      expect(response.body.pagination.currentPage).toBe(1);
      expect(response.body.pagination.totalPages).toBe(3);
      expect(response.body.pagination.hasNextPage).toBe(true);
      expect(response.body.pagination.hasPrevPage).toBe(false);

      // Test page 2
      const response2 = await request(app)
        .get('/api/state-categories?page=2&limit=5')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response2.body.data).toHaveLength(5);
      expect(response2.body.pagination.currentPage).toBe(2);
      expect(response2.body.pagination.hasNextPage).toBe(true);
      expect(response2.body.pagination.hasPrevPage).toBe(true);
    });

    it('should support search functionality', async () => {
      await StateCategory.bulkCreate([
        { name_en: 'Apple', name_so: 'Tufaax' },
        { name_en: 'Banana', name_so: 'Moos' },
        { name_en: 'Orange', name_so: 'Liin' },
      ]);

      const response = await request(app)
        .get('/api/state-categories?search=apple')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.data).toHaveLength(1);
      expect(response.body.data[0].name_en).toBe('Apple');
    });

    it('should support sorting', async () => {
      await StateCategory.bulkCreate([
        { name_en: 'Zebra', name_so: 'Zebra' },
        { name_en: 'Apple', name_so: 'Apple' },
        { name_en: 'Banana', name_so: 'Banana' },
      ]);

      const response = await request(app)
        .get('/api/state-categories?sortBy=name_en&sortOrder=ASC')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.data[0].name_en).toBe('Apple');
      expect(response.body.data[1].name_en).toBe('Banana');
      expect(response.body.data[2].name_en).toBe('Zebra');
    });

    it('should handle invalid page number', async () => {
      const response = await request(app)
        .get('/api/state-categories?page=invalid')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(400);

      expect(response.body.error).toBe('Invalid page number');
    });

    it('should handle invalid limit', async () => {
      const response = await request(app)
        .get('/api/state-categories?limit=200')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(400);

      expect(response.body.error).toBe('Invalid limit (1-100)');
    });
  });

  describe('GET /api/state-categories/:id', () => {
    it('should return a category by ID', async () => {
      const category = await StateCategory.create({
        name_en: 'Test Category',
        name_so: 'Qaybta Tijaabo'
      });

      const response = await request(app)
        .get(`/api/state-categories/${category.id}`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.id).toBe(category.id);
      expect(response.body.name_en).toBe('Test Category');
    });

    it('should return 404 for non-existent category', async () => {
      const response = await request(app)
        .get('/api/state-categories/999')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(404);

      expect(response.body.error).toBe('State category not found');
    });

    it('should handle invalid ID', async () => {
      const response = await request(app)
        .get('/api/state-categories/invalid')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(400);

      expect(response.body.error).toBe('Invalid category ID');
    });
  });

  describe('POST /api/state-categories', () => {
    it('should create a new category', async () => {
      const newCategory = {
        name_en: 'New Category',
        name_so: 'Qaybta Cusub',
        thumb_url: 'https://example.com/thumb.jpg'
      };

      const response = await request(app)
        .post('/api/state-categories')
        .send(newCategory)
        .expect(201);

      expect(response.body.name_en).toBe(newCategory.name_en);
      expect(response.body.name_so).toBe(newCategory.name_so);
      expect(response.body.thumb_url).toBe(newCategory.thumb_url);
    });

    it('should create category without thumb_url', async () => {
      const newCategory = {
        name_en: 'Category without thumb',
        name_so: 'Qaybta aan lahayn sawir'
      };

      const response = await request(app)
        .post('/api/state-categories')
        .send(newCategory)
        .expect(201);

      expect(response.body.thumb_url).toBeNull();
    });

    it('should validate required fields', async () => {
      const response = await request(app)
        .post('/api/state-categories')
        .send({})
        .expect(400);

      expect(response.body.error).toBe('name_en must be 1-255 characters');
    });

    it('should validate name_en length', async () => {
      const response = await request(app)
        .post('/api/state-categories')
        .send({
          name_en: '',
          name_so: 'Valid'
        })
        .expect(400);

      expect(response.body.error).toBe('name_en must be 1-255 characters');
    });

    it('should validate thumb_url format', async () => {
      const response = await request(app)
        .post('/api/state-categories')
        .send({
          name_en: 'Valid',
          name_so: 'Valid',
          thumb_url: 'invalid-url'
        })
        .expect(400);

      expect(response.body.error).toBe('Invalid thumb_url format');
    });
  });

  describe('PUT /api/state-categories/:id', () => {
    let category;

    beforeEach(async () => {
      category = await StateCategory.create({
        name_en: 'Original Name',
        name_so: 'Magaca Asalka ah',
        thumb_url: 'https://example.com/old.jpg'
      });
    });

    it('should update a category', async () => {
      const updates = {
        name_en: 'Updated Name',
        name_so: 'Magaca Cusub'
      };

      const response = await request(app)
        .put(`/api/state-categories/${category.id}`)
        .send(updates)
        .expect(200);

      expect(response.body.name_en).toBe(updates.name_en);
      expect(response.body.name_so).toBe(updates.name_so);
    });

    it('should update thumb_url to null', async () => {
      const response = await request(app)
        .put(`/api/state-categories/${category.id}`)
        .send({ thumb_url: null })
        .expect(200);

      expect(response.body.thumb_url).toBeNull();
    });

    it('should return 404 for non-existent category', async () => {
      const response = await request(app)
        .put('/api/state-categories/999')
        .send({ name_en: 'Updated' })
        .expect(404);

      expect(response.body.error).toBe('State category not found');
    });

    it('should validate update data', async () => {
      const response = await request(app)
        .put(`/api/state-categories/${category.id}`)
        .send({ name_en: '' })
        .expect(400);

      expect(response.body.error).toBe('name_en must be 1-255 characters');
    });
  });

  describe('DELETE /api/state-categories/:id', () => {
    it('should delete a category', async () => {
      const category = await StateCategory.create({
        name_en: 'To Delete',
        name_so: 'In la tirtiro'
      });

      await request(app)
        .delete(`/api/state-categories/${category.id}`)
        .expect(204);

      // Verify deletion
      const deleted = await StateCategory.findByPk(category.id);
      expect(deleted).toBeNull();
    });

    it('should return 404 for non-existent category', async () => {
      const response = await request(app)
        .delete('/api/state-categories/999')
        .expect(404);

      expect(response.body.error).toBe('State category not found');
    });

    it('should handle invalid ID', async () => {
      const response = await request(app)
        .delete('/api/state-categories/invalid')
        .expect(400);

      expect(response.body.error).toBe('Invalid category ID');
    });
  });
});
