process.env.NODE_ENV = 'test';
process.env.JWT_SECRET = 'test-secret';

const request = require('supertest');
const { sequelize, ListingFacility, Listing, Facility, User } = require('../src/models');
const jwt = require('jsonwebtoken');

describe('Listing Facilities API', () => {
  let app;
  let server;
  let authToken;
  let testUser;
  let testListing;
  let testFacility;

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

    // Create a test facility
    testFacility = await Facility.create({
      name_en: 'Parking',
      name_so: 'Baabuurta',
    });

    // Create a test JWT token
    const payload = { id: testUser.id, email: testUser.email };
    authToken = jwt.sign(payload, process.env.JWT_SECRET || 'test-secret', { expiresIn: '1h' });

    // Import and use the listing facilities routes
    const listingFacilitiesRouter = require('../src/routes/listingFacilities');
    app.use('/api/listing-facilities', listingFacilitiesRouter);

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
    await ListingFacility.destroy({ where: {} });
  });

  describe('GET /api/listing-facilities', () => {
    it('should return empty array when no listing facilities exist', async () => {
      const response = await request(app)
        .get('/api/listing-facilities')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body).toHaveProperty('data');
      expect(response.body).toHaveProperty('pagination');
      expect(response.body.data).toHaveLength(0);
      expect(response.body.pagination.total).toBe(0);
    });

    it('should return listing facilities with default pagination', async () => {
      // Create test listing facilities
      const facilities = [];
      for (let i = 1; i <= 15; i++) {
        facilities.push({
          listing_id: testListing.id,
          facility_id: testFacility.id,
          value: `Facility ${i}`,
        });
      }
      await ListingFacility.bulkCreate(facilities);

      const response = await request(app)
        .get('/api/listing-facilities')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.data).toHaveLength(10); // Default limit
      expect(response.body.pagination.total).toBe(15);
      expect(response.body.pagination.totalPages).toBe(2);
      expect(response.body.pagination.page).toBe(1);
      expect(response.body.pagination.limit).toBe(10);
    });

    it('should filter listing facilities by listing_id', async () => {
      const otherListing = await Listing.create({
        user_id: testUser.id,
        title: 'Other Listing',
        lat: 40.7128,
        lng: -74.0060,
        address: 'Other Address',
        availability: '1',
        location: { type: 'Point', coordinates: [-74.0060, 40.7128] }
      });

      await ListingFacility.bulkCreate([
        { listing_id: testListing.id, facility_id: testFacility.id, value: 'Parking Available' },
        { listing_id: otherListing.id, facility_id: testFacility.id, value: 'No Parking' },
      ]);

      const response = await request(app)
        .get(`/api/listing-facilities?listing_id=${testListing.id}`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.data).toHaveLength(1);
      expect(response.body.data[0].value).toBe('Parking Available');
    });

    it('should filter listing facilities by facility_id', async () => {
      const otherFacility = await Facility.create({
        name_en: 'Gym',
        name_so: 'Jimicsi',
      });

      await ListingFacility.bulkCreate([
        { listing_id: testListing.id, facility_id: testFacility.id, value: 'Parking Available' },
        { listing_id: testListing.id, facility_id: otherFacility.id, value: 'Gym Available' },
      ]);

      const response = await request(app)
        .get(`/api/listing-facilities?facility_id=${testFacility.id}`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.data).toHaveLength(1);
      expect(response.body.data[0].value).toBe('Parking Available');
    });
  });

  describe('GET /api/listing-facilities/:id', () => {
    it('should get listing facility by ID with associations', async () => {
      const facility = await ListingFacility.create({
        listing_id: testListing.id,
        facility_id: testFacility.id,
        value: 'Parking Available',
      });

      const response = await request(app)
        .get(`/api/listing-facilities/${facility.id}`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.id).toBe(facility.id);
      expect(response.body.value).toBe('Parking Available');
      expect(response.body.listing).toHaveProperty('id', testListing.id);
      expect(response.body.facility).toHaveProperty('id', testFacility.id);
    });

    it('should return 404 for non-existent listing facility', async () => {
      const response = await request(app)
        .get('/api/listing-facilities/999')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(404);

      expect(response.body.error).toBe('Listing facility not found');
    });
  });

  describe('POST /api/listing-facilities', () => {
    it('should create a new listing facility', async () => {
      const response = await request(app)
        .post('/api/listing-facilities')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          listing_id: testListing.id,
          facility_id: testFacility.id,
          value: 'Parking Available',
        })
        .expect(201);

      expect(response.body).toHaveProperty('id');
      expect(response.body.value).toBe('Parking Available');
      expect(response.body.listing).toHaveProperty('id', testListing.id);
      expect(response.body.facility).toHaveProperty('id', testFacility.id);
    });

    it('should return 400 for missing required fields', async () => {
      const response = await request(app)
        .post('/api/listing-facilities')
        .set('Authorization', `Bearer ${authToken}`)
        .send({ value: 'Parking Available' })
        .expect(400);

      expect(response.body.error).toContain('are required');
    });

    it('should return 400 for invalid listing_id', async () => {
      const response = await request(app)
        .post('/api/listing-facilities')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          listing_id: 999,
          facility_id: testFacility.id,
          value: 'Parking Available',
        })
        .expect(400);

      expect(response.body.error).toContain('listing_id');
    });

    it('should return 400 for invalid facility_id', async () => {
      const response = await request(app)
        .post('/api/listing-facilities')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          listing_id: testListing.id,
          facility_id: 999,
          value: 'Parking Available',
        })
        .expect(400);

      expect(response.body.error).toContain('facility_id');
    });

    it('should prevent duplicate listing facilities', async () => {
      await ListingFacility.create({
        listing_id: testListing.id,
        facility_id: testFacility.id,
        value: 'Parking Available',
      });

      const response = await request(app)
        .post('/api/listing-facilities')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          listing_id: testListing.id,
          facility_id: testFacility.id,
          value: 'No Parking',
        })
        .expect(400);

      expect(response.body.error).toContain('already assigned');
    });

    it('should sanitize inputs', async () => {
      const response = await request(app)
        .post('/api/listing-facilities')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          listing_id: testListing.id,
          facility_id: testFacility.id,
          value: '  Parking Available  ',
        })
        .expect(201);

      expect(response.body.value).toBe('Parking Available');
    });
  });

  describe('PUT /api/listing-facilities/:id', () => {
    it('should update a listing facility', async () => {
      const facility = await ListingFacility.create({
        listing_id: testListing.id,
        facility_id: testFacility.id,
        value: 'Parking Available',
      });

      const response = await request(app)
        .put(`/api/listing-facilities/${facility.id}`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          value: 'No Parking',
        })
        .expect(200);

      expect(response.body.value).toBe('No Parking');
    });

    it('should return 404 for non-existent listing facility', async () => {
      const response = await request(app)
        .put('/api/listing-facilities/999')
        .set('Authorization', `Bearer ${authToken}`)
        .send({ value: 'No Parking' })
        .expect(404);

      expect(response.body.error).toBe('Listing facility not found');
    });
  });

  describe('DELETE /api/listing-facilities/:id', () => {
    it('should delete a listing facility', async () => {
      const facility = await ListingFacility.create({
        listing_id: testListing.id,
        facility_id: testFacility.id,
        value: 'Parking Available',
      });

      const response = await request(app)
        .delete(`/api/listing-facilities/${facility.id}`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(204);

      // Verify deletion
      const deleted = await ListingFacility.findByPk(facility.id);
      expect(deleted).toBeNull();
    });

    it('should return 404 for non-existent listing facility', async () => {
      const response = await request(app)
        .delete('/api/listing-facilities/999')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(404);

      expect(response.body.error).toBe('Listing facility not found');
    });
  });
});
