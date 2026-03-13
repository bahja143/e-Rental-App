process.env.NODE_ENV = 'test';
process.env.JWT_SECRET = 'test-secret';

const request = require('supertest');
const { sequelize, NearbyPlace } = require('../src/models');
const jwt = require('jsonwebtoken');

describe('NearbyPlaces API', () => {
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

    // Import and use the nearbyPlaces routes
    const nearbyPlacesRouter = require('../src/routes/nearbyPlaces');
    app.use('/api/nearby-places', nearbyPlacesRouter);

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
    await NearbyPlace.destroy({ where: {} });
  });

  describe('GET /api/nearby-places', () => {
    it('should return empty array when no nearby places exist', async () => {
      const response = await request(app)
        .get('/api/nearby-places')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body).toHaveProperty('data');
      expect(response.body).toHaveProperty('pagination');
      expect(response.body.data).toHaveLength(0);
      expect(response.body.pagination.total).toBe(0);
    });

    it('should return nearby places with default pagination', async () => {
      // Create test nearby places
      const nearbyPlaces = [];
      for (let i = 1; i <= 15; i++) {
        nearbyPlaces.push({
          name_en: `Nearby Place ${i}`,
          name_so: `Nearby Place So ${i}`,
        });
      }
      await NearbyPlace.bulkCreate(nearbyPlaces);

      const response = await request(app)
        .get('/api/nearby-places')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.data).toHaveLength(10); // Default limit
      expect(response.body.pagination.total).toBe(15);
      expect(response.body.pagination.totalPages).toBe(2);
      expect(response.body.pagination.page).toBe(1);
      expect(response.body.pagination.limit).toBe(10);
    });

    it('should support custom pagination', async () => {
      // Create test nearby places
      const nearbyPlaces = [];
      for (let i = 1; i <= 25; i++) {
        nearbyPlaces.push({
          name_en: `Nearby Place ${i}`,
          name_so: `Nearby Place So ${i}`,
        });
      }
      await NearbyPlace.bulkCreate(nearbyPlaces);

      const response = await request(app)
        .get('/api/nearby-places?page=2&limit=5')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.data).toHaveLength(5);
      expect(response.body.pagination.total).toBe(25);
      expect(response.body.pagination.totalPages).toBe(5);
      expect(response.body.pagination.page).toBe(2);
      expect(response.body.pagination.limit).toBe(5);
    });

    it('should filter nearby places by search', async () => {
      await NearbyPlace.bulkCreate([
        { name_en: 'School', name_so: 'School So' },
        { name_en: 'Hospital', name_so: 'Hospital So' },
        { name_en: 'Park', name_so: 'Park So' },
      ]);

      const response = await request(app)
        .get('/api/nearby-places?search=School')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.data).toHaveLength(1);
      expect(response.body.data[0].name_en).toBe('School');
      expect(response.body.pagination.total).toBe(1);
    });

    it('should filter nearby places by name_en', async () => {
      await NearbyPlace.bulkCreate([
        { name_en: 'School', name_so: 'School So' },
        { name_en: 'Hospital', name_so: 'Hospital So' },
      ]);

      const response = await request(app)
        .get('/api/nearby-places?name_en=School')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.data).toHaveLength(1);
      expect(response.body.data[0].name_en).toBe('School');
    });

    it('should filter nearby places by name_so', async () => {
      await NearbyPlace.bulkCreate([
        { name_en: 'School', name_so: 'School So' },
        { name_en: 'Hospital', name_so: 'Hospital So' },
      ]);

      const response = await request(app)
        .get('/api/nearby-places?name_so=School So')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.data).toHaveLength(1);
      expect(response.body.data[0].name_so).toBe('School So');
    });

    it('should sort nearby places by createdAt DESC by default', async () => {
      const nearbyPlace1 = await NearbyPlace.create({ name_en: 'First', name_so: 'First So' });
      const nearbyPlace2 = await NearbyPlace.create({ name_en: 'Second', name_so: 'Second So' });

      const response = await request(app)
        .get('/api/nearby-places')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.data[0].name_en).toBe('Second'); // Most recent first
      expect(response.body.data[1].name_en).toBe('First');
    });

    it('should sort nearby places by name_en ASC', async () => {
      await NearbyPlace.bulkCreate([
        { name_en: 'Zoo', name_so: 'Zoo So' },
        { name_en: 'Airport', name_so: 'Airport So' },
      ]);

      const response = await request(app)
        .get('/api/nearby-places?sortBy=name_en&sortOrder=ASC')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.data[0].name_en).toBe('Airport');
      expect(response.body.data[1].name_en).toBe('Zoo');
    });
  });

  describe('GET /api/nearby-places/:id', () => {
    it('should get nearby place by ID', async () => {
      const nearbyPlace = await NearbyPlace.create({
        name_en: 'School',
        name_so: 'School So',
      });

      const response = await request(app)
        .get(`/api/nearby-places/${nearbyPlace.id}`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.id).toBe(nearbyPlace.id);
      expect(response.body.name_en).toBe('School');
      expect(response.body.name_so).toBe('School So');
    });

    it('should return 404 for non-existent nearby place', async () => {
      const response = await request(app)
        .get('/api/nearby-places/999')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(404);

      expect(response.body.error).toBe('Nearby place not found');
    });
  });

  describe('POST /api/nearby-places', () => {
    it('should create a new nearby place', async () => {
      const response = await request(app)
        .post('/api/nearby-places')
        .set('Authorization', `Bearer ${authToken}`)
        .send({ name_en: 'School', name_so: 'School So' })
        .expect(201);

      expect(response.body).toHaveProperty('id');
      expect(response.body.name_en).toBe('School');
      expect(response.body.name_so).toBe('School So');
    });

    it('should return 400 for duplicate name_en', async () => {
      await NearbyPlace.create({ name_en: 'School', name_so: 'School So' });

      const response = await request(app)
        .post('/api/nearby-places')
        .set('Authorization', `Bearer ${authToken}`)
        .send({ name_en: 'School', name_so: 'Another School So' })
        .expect(400);

      expect(response.body.error).toBe('Nearby place with this name_en already exists');
    });

    it('should return 400 for missing required fields', async () => {
      const response = await request(app)
        .post('/api/nearby-places')
        .set('Authorization', `Bearer ${authToken}`)
        .send({ name_en: 'School' })
        .expect(400);

      expect(response.body.error).toBe('name_en and name_so are required');
    });

    it('should sanitize inputs', async () => {
      const response = await request(app)
        .post('/api/nearby-places')
        .set('Authorization', `Bearer ${authToken}`)
        .send({ name_en: '  School  ', name_so: '  School So  ' })
        .expect(201);

      expect(response.body.name_en).toBe('School');
      expect(response.body.name_so).toBe('School So');
    });
  });

  describe('PUT /api/nearby-places/:id', () => {
    it('should update a nearby place', async () => {
      const nearbyPlace = await NearbyPlace.create({
        name_en: 'School',
        name_so: 'School So',
      });

      const response = await request(app)
        .put(`/api/nearby-places/${nearbyPlace.id}`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({ name_en: 'Updated School', name_so: 'Updated School So' })
        .expect(200);

      expect(response.body.name_en).toBe('Updated School');
      expect(response.body.name_so).toBe('Updated School So');
    });

    it('should return 404 for non-existent nearby place', async () => {
      const response = await request(app)
        .put('/api/nearby-places/999')
        .set('Authorization', `Bearer ${authToken}`)
        .send({ name_en: 'Updated School', name_so: 'Updated School So' })
        .expect(404);

      expect(response.body.error).toBe('Nearby place not found');
    });

    it('should return 400 for duplicate name_en on update', async () => {
      await NearbyPlace.create({ name_en: 'School 1', name_so: 'School 1 So' });
      const nearbyPlace2 = await NearbyPlace.create({ name_en: 'School 2', name_so: 'School 2 So' });

      const response = await request(app)
        .put(`/api/nearby-places/${nearbyPlace2.id}`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({ name_en: 'School 1', name_so: 'School 2 So' })
        .expect(400);

      expect(response.body.error).toBe('Nearby place with this name_en already exists');
    });
  });

  describe('DELETE /api/nearby-places/:id', () => {
    it('should delete a nearby place', async () => {
      const nearbyPlace = await NearbyPlace.create({
        name_en: 'School',
        name_so: 'School So',
      });

      const response = await request(app)
        .delete(`/api/nearby-places/${nearbyPlace.id}`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(204);

      // Verify deletion
      const deleted = await NearbyPlace.findByPk(nearbyPlace.id);
      expect(deleted).toBeNull();
    });

    it('should return 404 for non-existent nearby place', async () => {
      const response = await request(app)
        .delete('/api/nearby-places/999')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(404);

      expect(response.body.error).toBe('Nearby place not found');
    });
  });
});
