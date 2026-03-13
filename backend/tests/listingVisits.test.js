process.env.NODE_ENV = 'test';
process.env.JWT_SECRET = 'test-secret';

const request = require('supertest');
const { sequelize, ListingVisit, User, Listing } = require('../src/models');
const jwt = require('jsonwebtoken');

describe('Listing Visits API', () => {
  let app;
  let server;
  let authToken;
  let testUser;
  let testListing;

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

    // Create a test JWT token
    const payload = { id: testUser.id, email: testUser.email };
    authToken = jwt.sign(payload, process.env.JWT_SECRET || 'test-secret', { expiresIn: '1h' });

    // Import and use the listing visits routes
    const listingVisitsRouter = require('../src/routes/listingVisits');
    app.use('/api/listing-visits', listingVisitsRouter);

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
    await ListingVisit.destroy({ where: {} });
  });

  describe('GET /api/listing-visits', () => {
    it('should return empty array when no visits exist', async () => {
      const response = await request(app)
        .get('/api/listing-visits')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body).toHaveProperty('data');
      expect(response.body).toHaveProperty('pagination');
      expect(response.body.data).toHaveLength(0);
      expect(response.body.pagination.total).toBe(0);
    });

    it('should return visits with default pagination', async () => {
      // Create test visits
      const visits = [];
      for (let i = 1; i <= 15; i++) {
        visits.push({
          listing_id: testListing.id,
          date: `2023-10-${String(i).padStart(2, '0')}`,
          total_impression: i * 10,
          total_visit: i * 2,
        });
      }
      await ListingVisit.bulkCreate(visits);

      const response = await request(app)
        .get('/api/listing-visits')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.data).toHaveLength(10); // Default limit
      expect(response.body.pagination.total).toBe(15);
      expect(response.body.pagination.totalPages).toBe(2);
      expect(response.body.pagination.page).toBe(1);
      expect(response.body.pagination.limit).toBe(10);
    });

    it('should filter visits by listing_id', async () => {
      const otherListing = await Listing.create({
        user_id: testUser.id,
        title: 'Other Listing',
        lat: 40.7128,
        lng: -74.0060,
        address: 'Other Address',
        availability: '1',
        location: { type: 'Point', coordinates: [-74.0060, 40.7128] }
      });

      await ListingVisit.bulkCreate([
        { listing_id: testListing.id, date: '2023-10-01', total_impression: 100, total_visit: 20 },
        { listing_id: otherListing.id, date: '2023-10-01', total_impression: 50, total_visit: 10 },
      ]);

      const response = await request(app)
        .get(`/api/listing-visits?listing_id=${testListing.id}`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.data).toHaveLength(1);
      expect(response.body.data[0].total_impression).toBe(100);
    });

    it('should filter visits by date range', async () => {
      await ListingVisit.bulkCreate([
        { listing_id: testListing.id, date: '2023-10-01', total_impression: 100 },
        { listing_id: testListing.id, date: '2023-10-15', total_impression: 200 },
        { listing_id: testListing.id, date: '2023-10-30', total_impression: 300 },
      ]);

      const response = await request(app)
        .get('/api/listing-visits?date_from=2023-10-10&date_to=2023-10-20')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.data).toHaveLength(1);
      expect(response.body.data[0].total_impression).toBe(200);
    });

    it('should filter visits by total_visit range', async () => {
      await ListingVisit.bulkCreate([
        { listing_id: testListing.id, date: '2023-10-01', total_visit: 5 },
        { listing_id: testListing.id, date: '2023-10-02', total_visit: 15 },
        { listing_id: testListing.id, date: '2023-10-03', total_visit: 25 },
      ]);

      const response = await request(app)
        .get('/api/listing-visits?min_total_visit=10&max_total_visit=20')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.data).toHaveLength(1);
      expect(response.body.data[0].total_visit).toBe(15);
    });
  });

  describe('GET /api/listing-visits/:id', () => {
    it('should get visit by ID with listing data', async () => {
      const visit = await ListingVisit.create({
        listing_id: testListing.id,
        date: '2023-10-01',
        total_impression: 100,
        total_visit: 20,
        conversion: 5,
      });

      const response = await request(app)
        .get(`/api/listing-visits/${visit.id}`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.id).toBe(visit.id);
      expect(response.body.total_impression).toBe(100);
      expect(response.body.total_visit).toBe(20);
      expect(response.body.conversion).toBe(5);
      expect(response.body.listing).toHaveProperty('id', testListing.id);
    });

    it('should return 404 for non-existent visit', async () => {
      const response = await request(app)
        .get('/api/listing-visits/999')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(404);

      expect(response.body.error).toBe('Listing visit not found');
    });
  });

  describe('POST /api/listing-visits', () => {
    it('should create a new visit', async () => {
      const response = await request(app)
        .post('/api/listing-visits')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          listing_id: testListing.id,
          date: '2023-10-01',
          total_impression: 100,
          app_impression: 50,
          ad_impression: 25,
          total_visit: 20,
          app_visit: 15,
          ad_visit: 3,
          share_visit: 2,
          conversion: 5,
        })
        .expect(201);

      expect(response.body).toHaveProperty('id');
      expect(response.body.total_impression).toBe(100);
      expect(response.body.total_visit).toBe(20);
      expect(response.body.conversion).toBe(5);
    });

    it('should return 400 for missing required fields', async () => {
      const response = await request(app)
        .post('/api/listing-visits')
        .set('Authorization', `Bearer ${authToken}`)
        .send({ total_impression: 100 })
        .expect(400);

      expect(response.body.error).toContain('are required');
    });

    it('should return 400 for invalid date', async () => {
      const response = await request(app)
        .post('/api/listing-visits')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          listing_id: testListing.id,
          date: 'invalid-date',
          total_impression: 100,
        })
        .expect(400);

      expect(response.body.error).toContain('Invalid date format');
    });

    it('should return 400 for negative values', async () => {
      const response = await request(app)
        .post('/api/listing-visits')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          listing_id: testListing.id,
          date: '2023-10-01',
          total_impression: -10,
        })
        .expect(400);

      expect(response.body.error).toContain('must be a non-negative integer');
    });

    it('should prevent duplicate visits for same listing and date', async () => {
      await ListingVisit.create({
        listing_id: testListing.id,
        date: '2023-10-01',
        total_impression: 100,
      });

      const response = await request(app)
        .post('/api/listing-visits')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          listing_id: testListing.id,
          date: '2023-10-01',
          total_impression: 200,
        })
        .expect(400);

      expect(response.body.error).toContain('already exists for this listing and date');
    });
  });

  describe('PUT /api/listing-visits/:id', () => {
    it('should update a visit', async () => {
      const visit = await ListingVisit.create({
        listing_id: testListing.id,
        date: '2023-10-01',
        total_impression: 100,
        total_visit: 10,
      });

      const response = await request(app)
        .put(`/api/listing-visits/${visit.id}`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          total_impression: 200,
          total_visit: 25,
          conversion: 8,
        })
        .expect(200);

      expect(response.body.total_impression).toBe(200);
      expect(response.body.total_visit).toBe(25);
      expect(response.body.conversion).toBe(8);
    });

    it('should return 404 for non-existent visit', async () => {
      const response = await request(app)
        .put('/api/listing-visits/999')
        .set('Authorization', `Bearer ${authToken}`)
        .send({ total_impression: 200 })
        .expect(404);

      expect(response.body.error).toBe('Listing visit not found');
    });

    it('should validate date on update', async () => {
      const visit = await ListingVisit.create({
        listing_id: testListing.id,
        date: '2023-10-01',
        total_impression: 100,
      });

      const response = await request(app)
        .put(`/api/listing-visits/${visit.id}`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({ date: 'invalid-date' })
        .expect(400);

      expect(response.body.error).toContain('Invalid date format');
    });

    it('should validate numeric fields on update', async () => {
      const visit = await ListingVisit.create({
        listing_id: testListing.id,
        date: '2023-10-01',
        total_impression: 100,
      });

      const response = await request(app)
        .put(`/api/listing-visits/${visit.id}`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({ total_impression: -50 })
        .expect(400);

      expect(response.body.error).toContain('must be a non-negative integer');
    });
  });

  describe('DELETE /api/listing-visits/:id', () => {
    it('should delete a visit', async () => {
      const visit = await ListingVisit.create({
        listing_id: testListing.id,
        date: '2023-10-01',
        total_impression: 100,
      });

      const response = await request(app)
        .delete(`/api/listing-visits/${visit.id}`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(204);

      // Verify deletion
      const deleted = await ListingVisit.findByPk(visit.id);
      expect(deleted).toBeNull();
    });

    it('should return 404 for non-existent visit', async () => {
      const response = await request(app)
        .delete('/api/listing-visits/999')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(404);

      expect(response.body.error).toBe('Listing visit not found');
    });
  });
});
