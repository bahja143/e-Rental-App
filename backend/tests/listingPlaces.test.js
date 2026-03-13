process.env.NODE_ENV = 'test';
process.env.JWT_SECRET = 'test-secret';

const request = require('supertest');
const { sequelize, ListingPlace, Listing, NearbyPlace, User } = require('../src/models');
const jwt = require('jsonwebtoken');

describe('Listing Places API', () => {
  let app;
  let server;
  let authToken;
  let testUser;
  let testListing;
  let testNearbyPlace;

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

    // Create a test nearby place
    testNearbyPlace = await NearbyPlace.create({
      name_en: 'Central Park',
      name_so: 'Beerta Dhexe',
    });

    // Create a test JWT token
    const payload = { id: testUser.id, email: testUser.email };
    authToken = jwt.sign(payload, process.env.JWT_SECRET || 'test-secret', { expiresIn: '1h' });

    // Import and use the listing places routes
    const listingPlacesRouter = require('../src/routes/listingPlaces');
    app.use('/api/listing-places', listingPlacesRouter);

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
    await ListingPlace.destroy({ where: {} });
  });

  describe('GET /api/listing-places', () => {
    it('should return empty array when no listing places exist', async () => {
      const response = await request(app)
        .get('/api/listing-places')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body).toHaveProperty('data');
      expect(response.body).toHaveProperty('pagination');
      expect(response.body.data).toHaveLength(0);
      expect(response.body.pagination.total).toBe(0);
    });

    it('should return listing places with default pagination', async () => {
      // Create test listing places
      const places = [];
      for (let i = 1; i <= 15; i++) {
        places.push({
          listing_id: testListing.id,
          nearby_place_id: testNearbyPlace.id,
          value: `Place ${i}`,
        });
      }
      await ListingPlace.bulkCreate(places);

      const response = await request(app)
        .get('/api/listing-places')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.data).toHaveLength(10); // Default limit
      expect(response.body.pagination.total).toBe(15);
      expect(response.body.pagination.totalPages).toBe(2);
      expect(response.body.pagination.page).toBe(1);
      expect(response.body.pagination.limit).toBe(10);
    });

    it('should filter listing places by listing_id', async () => {
      const otherListing = await Listing.create({
        user_id: testUser.id,
        title: 'Other Listing',
        lat: 40.7128,
        lng: -74.0060,
        address: 'Other Address',
        availability: '1',
        location: { type: 'Point', coordinates: [-74.0060, 40.7128] }
      });

      await ListingPlace.bulkCreate([
        { listing_id: testListing.id, nearby_place_id: testNearbyPlace.id, value: 'Near Central Park' },
        { listing_id: otherListing.id, nearby_place_id: testNearbyPlace.id, value: 'Far from Central Park' },
      ]);

      const response = await request(app)
        .get(`/api/listing-places?listing_id=${testListing.id}`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.data).toHaveLength(1);
      expect(response.body.data[0].value).toBe('Near Central Park');
    });

    it('should filter listing places by nearby_place_id', async () => {
      const otherNearbyPlace = await NearbyPlace.create({
        name_en: 'Times Square',
        name_so: 'Times Square',
      });

      await ListingPlace.bulkCreate([
        { listing_id: testListing.id, nearby_place_id: testNearbyPlace.id, value: 'Near Central Park' },
        { listing_id: testListing.id, nearby_place_id: otherNearbyPlace.id, value: 'Near Times Square' },
      ]);

      const response = await request(app)
        .get(`/api/listing-places?nearby_place_id=${testNearbyPlace.id}`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.data).toHaveLength(1);
      expect(response.body.data[0].value).toBe('Near Central Park');
    });
  });

  describe('GET /api/listing-places/:id', () => {
    it('should get listing place by ID with associations', async () => {
      const place = await ListingPlace.create({
        listing_id: testListing.id,
        nearby_place_id: testNearbyPlace.id,
        value: 'Near Central Park',
      });

      const response = await request(app)
        .get(`/api/listing-places/${place.id}`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.id).toBe(place.id);
      expect(response.body.value).toBe('Near Central Park');
      expect(response.body.listing).toHaveProperty('id', testListing.id);
      expect(response.body.nearbyPlace).toHaveProperty('id', testNearbyPlace.id);
    });

    it('should return 404 for non-existent listing place', async () => {
      const response = await request(app)
        .get('/api/listing-places/999')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(404);

      expect(response.body.error).toBe('Listing place not found');
    });
  });

  describe('POST /api/listing-places', () => {
    it('should create a new listing place', async () => {
      const response = await request(app)
        .post('/api/listing-places')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          listing_id: testListing.id,
          nearby_place_id: testNearbyPlace.id,
          value: 'Near Central Park',
        })
        .expect(201);

      expect(response.body).toHaveProperty('id');
      expect(response.body.value).toBe('Near Central Park');
      expect(response.body.listing).toHaveProperty('id', testListing.id);
      expect(response.body.nearbyPlace).toHaveProperty('id', testNearbyPlace.id);
    });

    it('should return 400 for missing required fields', async () => {
      const response = await request(app)
        .post('/api/listing-places')
        .set('Authorization', `Bearer ${authToken}`)
        .send({ value: 'Near Central Park' })
        .expect(400);

      expect(response.body.error).toContain('are required');
    });

    it('should return 400 for invalid listing_id', async () => {
      const response = await request(app)
        .post('/api/listing-places')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          listing_id: 999,
          nearby_place_id: testNearbyPlace.id,
          value: 'Near Central Park',
        })
        .expect(400);

      expect(response.body.error).toContain('listing_id');
    });

    it('should return 400 for invalid nearby_place_id', async () => {
      const response = await request(app)
        .post('/api/listing-places')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          listing_id: testListing.id,
          nearby_place_id: 999,
          value: 'Near Central Park',
        })
        .expect(400);

      expect(response.body.error).toContain('nearby_place_id');
    });

    it('should prevent duplicate listing places', async () => {
      await ListingPlace.create({
        listing_id: testListing.id,
        nearby_place_id: testNearbyPlace.id,
        value: 'Near Central Park',
      });

      const response = await request(app)
        .post('/api/listing-places')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          listing_id: testListing.id,
          nearby_place_id: testNearbyPlace.id,
          value: 'Very Near Central Park',
        })
        .expect(400);

      expect(response.body.error).toContain('already assigned');
    });

    it('should sanitize inputs', async () => {
      const response = await request(app)
        .post('/api/listing-places')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          listing_id: testListing.id,
          nearby_place_id: testNearbyPlace.id,
          value: '  Near Central Park  ',
        })
        .expect(201);

      expect(response.body.value).toBe('Near Central Park');
    });
  });

  describe('PUT /api/listing-places/:id', () => {
    it('should update a listing place', async () => {
      const place = await ListingPlace.create({
        listing_id: testListing.id,
        nearby_place_id: testNearbyPlace.id,
        value: 'Near Central Park',
      });

      const response = await request(app)
        .put(`/api/listing-places/${place.id}`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          value: 'Very Near Central Park',
        })
        .expect(200);

      expect(response.body.value).toBe('Very Near Central Park');
    });

    it('should return 404 for non-existent listing place', async () => {
      const response = await request(app)
        .put('/api/listing-places/999')
        .set('Authorization', `Bearer ${authToken}`)
        .send({ value: 'Very Near Central Park' })
        .expect(404);

      expect(response.body.error).toBe('Listing place not found');
    });
  });

  describe('DELETE /api/listing-places/:id', () => {
    it('should delete a listing place', async () => {
      const place = await ListingPlace.create({
        listing_id: testListing.id,
        nearby_place_id: testNearbyPlace.id,
        value: 'Near Central Park',
      });

      const response = await request(app)
        .delete(`/api/listing-places/${place.id}`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(204);

      // Verify deletion
      const deleted = await ListingPlace.findByPk(place.id);
      expect(deleted).toBeNull();
    });

    it('should return 404 for non-existent listing place', async () => {
      const response = await request(app)
        .delete('/api/listing-places/999')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(404);

      expect(response.body.error).toBe('Listing place not found');
    });
  });
});
