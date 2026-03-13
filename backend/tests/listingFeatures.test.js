process.env.NODE_ENV = 'test';
process.env.JWT_SECRET = 'test-secret';

const request = require('supertest');
const { sequelize, ListingFeature, Listing, PropertyFeatures, User } = require('../src/models');
const jwt = require('jsonwebtoken');

describe('Listing Features API', () => {
  let app;
  let server;
  let authToken;
  let testUser;
  let testListing;
  let testPropertyFeature;

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

    // Create a test user
    testUser = await User.create({
      name: 'Test User',
      email: 'test@example.com',
      password: 'password123',
      city: 'Test City',
      looking_for: 'buy',
    });

    // Create a test listing
    testListing = await Listing.create({
      user_id: testUser.id,
      title: 'Test Listing',
      lat: 40.7128,
      lng: -74.0060,
      address: 'Test Address',
      availability: '1',
      location: { type: 'Point', coordinates: [-74.0060, 40.7128] }
    });

    // Create a test property feature
    testPropertyFeature = await PropertyFeatures.create({
      name_en: 'Bedrooms',
      name_so: 'Qol',
      type: 'number',
    });

    // Create a test JWT token
    const payload = { id: testUser.id, email: testUser.email };
    authToken = jwt.sign(payload, process.env.JWT_SECRET || 'test-secret', { expiresIn: '1h' });

    // Import and use the listing features routes
    const listingFeaturesRouter = require('../src/routes/listingFeatures');
    app.use('/api/listing-features', listingFeaturesRouter);

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
    await ListingFeature.destroy({ where: {} });
  });

  describe('GET /api/listing-features', () => {
    it('should return empty array when no listing features exist', async () => {
      const response = await request(app)
        .get('/api/listing-features')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body).toHaveProperty('data');
      expect(response.body).toHaveProperty('pagination');
      expect(response.body.data).toHaveLength(0);
      expect(response.body.pagination.total).toBe(0);
    });

    it('should return listing features with default pagination', async () => {
      // Create test listing features
      const features = [];
      for (let i = 1; i <= 15; i++) {
        features.push({
          listing_id: testListing.id,
          property_feature_id: testPropertyFeature.id,
          value: `${i}`,
        });
      }
      await ListingFeature.bulkCreate(features);

      const response = await request(app)
        .get('/api/listing-features')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.data).toHaveLength(10); // Default limit
      expect(response.body.pagination.total).toBe(15);
      expect(response.body.pagination.totalPages).toBe(2);
      expect(response.body.pagination.page).toBe(1);
      expect(response.body.pagination.limit).toBe(10);
    });

    it('should filter listing features by listing_id', async () => {
      const otherListing = await Listing.create({
        user_id: testUser.id,
        title: 'Other Listing',
        lat: 40.7128,
        lng: -74.0060,
        address: 'Other Address',
        availability: '1',
        location: { type: 'Point', coordinates: [-74.0060, 40.7128] }
      });

      await ListingFeature.bulkCreate([
        { listing_id: testListing.id, property_feature_id: testPropertyFeature.id, value: '3' },
        { listing_id: otherListing.id, property_feature_id: testPropertyFeature.id, value: '4' },
      ]);

      const response = await request(app)
        .get(`/api/listing-features?listing_id=${testListing.id}`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.data).toHaveLength(1);
      expect(response.body.data[0].value).toBe('3');
    });

    it('should filter listing features by property_feature_id', async () => {
      const otherPropertyFeature = await PropertyFeatures.create({
        name_en: 'Bathrooms',
        name_so: 'Musqulaha',
        type: 'number',
      });

      await ListingFeature.bulkCreate([
        { listing_id: testListing.id, property_feature_id: testPropertyFeature.id, value: '3' },
        { listing_id: testListing.id, property_feature_id: otherPropertyFeature.id, value: '2' },
      ]);

      const response = await request(app)
        .get(`/api/listing-features?property_feature_id=${testPropertyFeature.id}`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.data).toHaveLength(1);
      expect(response.body.data[0].value).toBe('3');
    });
  });

  describe('GET /api/listing-features/:id', () => {
    it('should get listing feature by ID with associations', async () => {
      const feature = await ListingFeature.create({
        listing_id: testListing.id,
        property_feature_id: testPropertyFeature.id,
        value: '3',
      });

      const response = await request(app)
        .get(`/api/listing-features/${feature.id}`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.id).toBe(feature.id);
      expect(response.body.value).toBe('3');
      expect(response.body.listing).toHaveProperty('id', testListing.id);
      expect(response.body.propertyFeature).toHaveProperty('id', testPropertyFeature.id);
    });

    it('should return 404 for non-existent listing feature', async () => {
      const response = await request(app)
        .get('/api/listing-features/999')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(404);

      expect(response.body.error).toBe('Listing feature not found');
    });
  });

  describe('POST /api/listing-features', () => {
    it('should create a new listing feature', async () => {
      const response = await request(app)
        .post('/api/listing-features')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          listing_id: testListing.id,
          property_feature_id: testPropertyFeature.id,
          value: '4',
        })
        .expect(201);

      expect(response.body).toHaveProperty('id');
      expect(response.body.value).toBe('4');
      expect(response.body.listing).toHaveProperty('id', testListing.id);
      expect(response.body.propertyFeature).toHaveProperty('id', testPropertyFeature.id);
    });

    it('should validate value type for number property features', async () => {
      const response = await request(app)
        .post('/api/listing-features')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          listing_id: testListing.id,
          property_feature_id: testPropertyFeature.id,
          value: 'not-a-number',
        })
        .expect(400);

      expect(response.body.error).toContain('must be a valid number');
    });

    it('should return 400 for missing required fields', async () => {
      const response = await request(app)
        .post('/api/listing-features')
        .set('Authorization', `Bearer ${authToken}`)
        .send({ value: '3' })
        .expect(400);

      expect(response.body.error).toContain('are required');
    });

    it('should return 400 for invalid listing_id', async () => {
      const response = await request(app)
        .post('/api/listing-features')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          listing_id: 999,
          property_feature_id: testPropertyFeature.id,
          value: '3',
        })
        .expect(400);

      expect(response.body.error).toContain('listing_id');
    });

    it('should return 400 for invalid property_feature_id', async () => {
      const response = await request(app)
        .post('/api/listing-features')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          listing_id: testListing.id,
          property_feature_id: 999,
          value: '3',
        })
        .expect(400);

      expect(response.body.error).toContain('property_feature_id');
    });

    it('should prevent duplicate listing features', async () => {
      await ListingFeature.create({
        listing_id: testListing.id,
        property_feature_id: testPropertyFeature.id,
        value: '3',
      });

      const response = await request(app)
        .post('/api/listing-features')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          listing_id: testListing.id,
          property_feature_id: testPropertyFeature.id,
          value: '4',
        })
        .expect(400);

      expect(response.body.error).toContain('already assigned');
    });

    it('should sanitize inputs', async () => {
      const response = await request(app)
        .post('/api/listing-features')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          listing_id: testListing.id,
          property_feature_id: testPropertyFeature.id,
          value: '  3  ',
        })
        .expect(201);

      expect(response.body.value).toBe('3');
    });
  });

  describe('PUT /api/listing-features/:id', () => {
    it('should update a listing feature', async () => {
      const feature = await ListingFeature.create({
        listing_id: testListing.id,
        property_feature_id: testPropertyFeature.id,
        value: '3',
      });

      const response = await request(app)
        .put(`/api/listing-features/${feature.id}`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          value: '5',
        })
        .expect(200);

      expect(response.body.value).toBe('5');
    });

    it('should return 404 for non-existent listing feature', async () => {
      const response = await request(app)
        .put('/api/listing-features/999')
        .set('Authorization', `Bearer ${authToken}`)
        .send({ value: '5' })
        .expect(404);

      expect(response.body.error).toBe('Listing feature not found');
    });

    it('should validate value type on update', async () => {
      const feature = await ListingFeature.create({
        listing_id: testListing.id,
        property_feature_id: testPropertyFeature.id,
        value: '3',
      });

      const response = await request(app)
        .put(`/api/listing-features/${feature.id}`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({ value: 'not-a-number' })
        .expect(400);

      expect(response.body.error).toContain('must be a valid number');
    });
  });

  describe('DELETE /api/listing-features/:id', () => {
    it('should delete a listing feature', async () => {
      const feature = await ListingFeature.create({
        listing_id: testListing.id,
        property_feature_id: testPropertyFeature.id,
        value: '3',
      });

      const response = await request(app)
        .delete(`/api/listing-features/${feature.id}`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(204);

      // Verify deletion
      const deleted = await ListingFeature.findByPk(feature.id);
      expect(deleted).toBeNull();
    });

    it('should return 404 for non-existent listing feature', async () => {
      const response = await request(app)
        .delete('/api/listing-features/999')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(404);

      expect(response.body.error).toBe('Listing feature not found');
    });
  });
});
