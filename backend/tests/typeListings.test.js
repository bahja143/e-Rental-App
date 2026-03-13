process.env.NODE_ENV = 'test';
process.env.JWT_SECRET = 'test-secret';

const request = require('supertest');
const { sequelize, TypeListing, Listing, ListingType, User } = require('../src/models');
const jwt = require('jsonwebtoken');

describe('Type Listings API', () => {
  let app;
  let server;
  let authToken;
  let testUser;
  let testListing;
  let testListingType;

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

    // Create test data
    testUser = await User.create({
      name: 'Test User',
      email: 'test@example.com',
      password: 'hashedpassword',
      phone: '1234567890'
    });

    testListing = await Listing.create({
      user_id: testUser.id,
      title: 'Test Listing',
      lat: 40.7128,
      lng: -74.0060,
      address: '123 Test St',
      availability: '1',
      location: { type: 'Point', coordinates: [-74.0060, 40.7128] }
    });

    testListingType = await ListingType.create({
      name_en: 'For Sale',
      name_so: 'Iib'
    });

    // Create a test JWT token
    const payload = { id: testUser.id, email: testUser.email };
    authToken = jwt.sign(payload, process.env.JWT_SECRET || 'test-secret', { expiresIn: '1h' });

    // Import and use the typeListings routes
    const typeListingsRouter = require('../src/routes/typeListings');
    app.use('/api/type-listings', typeListingsRouter);

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
    await TypeListing.destroy({ where: {} });
  });

  describe('GET /api/type-listings', () => {
    it('should return a list of type listings', async () => {
      await TypeListing.create({ listing_id: testListing.id, listing_type_id: testListingType.id });

      const response = await request(app)
        .get('/api/type-listings')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.data.length).toEqual(1);
    });

    it('should support pagination', async () => {
      for (let i = 0; i < 15; i++) {
        const listing = await Listing.create({
          user_id: testUser.id,
          title: `Test Listing ${i}`,
          lat: 40.7128,
          lng: -74.0060,
          address: `123 Test St ${i}`,
          availability: '1',
          location: { type: 'Point', coordinates: [-74.0060, 40.7128] }
        });
        await TypeListing.create({ listing_id: listing.id, listing_type_id: testListingType.id });
      }

      const response = await request(app)
        .get('/api/type-listings?page=2&limit=5')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.data.length).toEqual(5);
      expect(response.body.pagination.page).toEqual(2);
      expect(response.body.pagination.limit).toEqual(5);
      expect(response.body.pagination.total).toEqual(15);
    });

    it('should support filtering by listing_id', async () => {
      const anotherListing = await Listing.create({
        user_id: testUser.id,
        title: 'Another Listing',
        lat: 40.7128,
        lng: -74.0060,
        address: '456 Another St',
        location: { type: 'Point', coordinates: [-74.0060, 40.7128] }
      });

      await TypeListing.create({ listing_id: testListing.id, listing_type_id: testListingType.id });
      await TypeListing.create({ listing_id: anotherListing.id, listing_type_id: testListingType.id });

      const response = await request(app)
        .get(`/api/type-listings?listing_id=${testListing.id}`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.data.length).toEqual(1);
      expect(response.body.data[0].listing_id).toEqual(testListing.id);
    });

    it('should support filtering by listing_type_id', async () => {
      const anotherType = await ListingType.create({
        name_en: 'For Rent',
        name_so: 'Kiro'
      });

      await TypeListing.create({ listing_id: testListing.id, listing_type_id: testListingType.id });
      await TypeListing.create({ listing_id: testListing.id, listing_type_id: anotherType.id });

      const response = await request(app)
        .get(`/api/type-listings?listing_type_id=${testListingType.id}`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.data.length).toEqual(1);
      expect(response.body.data[0].listing_type_id).toEqual(testListingType.id);
    });

    it('should support sorting', async () => {
      const anotherListing = await Listing.create({
        user_id: testUser.id,
        title: 'Another Listing',
        lat: 40.7128,
        lng: -74.0060,
        address: '456 Another St',
        location: { type: 'Point', coordinates: [-74.0060, 40.7128] }
      });

      await TypeListing.create({ listing_id: testListing.id, listing_type_id: testListingType.id });
      await TypeListing.create({ listing_id: anotherListing.id, listing_type_id: testListingType.id });

      const response = await request(app)
        .get('/api/type-listings?sortBy=listing_id&sortOrder=ASC')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.data.length).toEqual(2);
      expect(response.body.data[0].listing_id).toBeLessThan(response.body.data[1].listing_id);
    });
  });

  describe('GET /api/type-listings/:id', () => {
    it('should return a single type listing', async () => {
      const typeListing = await TypeListing.create({ listing_id: testListing.id, listing_type_id: testListingType.id });

      const response = await request(app)
        .get(`/api/type-listings/${typeListing.id}`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.listing_id).toEqual(testListing.id);
      expect(response.body.listing_type_id).toEqual(testListingType.id);
    });

    it('should return 404 if type listing not found', async () => {
      const response = await request(app)
        .get('/api/type-listings/999')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(404);
    });
  });

  describe('POST /api/type-listings', () => {
    it('should create a new type listing', async () => {
      const response = await request(app)
        .post('/api/type-listings')
        .set('Authorization', `Bearer ${authToken}`)
        .send({ listing_id: testListing.id, listing_type_id: testListingType.id })
        .expect(201);

      expect(response.body.listing_id).toEqual(testListing.id);
      expect(response.body.listing_type_id).toEqual(testListingType.id);

      const typeListing = await TypeListing.findOne({ where: { listing_id: testListing.id, listing_type_id: testListingType.id } });
      expect(typeListing).not.toBeNull();
    });

    it('should return 400 if listing_id is not provided', async () => {
      const response = await request(app)
        .post('/api/type-listings')
        .set('Authorization', `Bearer ${authToken}`)
        .send({ listing_type_id: testListingType.id })
        .expect(400);
    });

    it('should return 400 if listing_type_id is not provided', async () => {
      const response = await request(app)
        .post('/api/type-listings')
        .set('Authorization', `Bearer ${authToken}`)
        .send({ listing_id: testListing.id })
        .expect(400);
    });

    it('should return 400 if listing does not exist', async () => {
      const response = await request(app)
        .post('/api/type-listings')
        .set('Authorization', `Bearer ${authToken}`)
        .send({ listing_id: 999, listing_type_id: testListingType.id })
        .expect(400);
    });

    it('should return 400 if listing type does not exist', async () => {
      const response = await request(app)
        .post('/api/type-listings')
        .set('Authorization', `Bearer ${authToken}`)
        .send({ listing_id: testListing.id, listing_type_id: 999 })
        .expect(400);
    });

    it('should return 400 if duplicate association', async () => {
      await TypeListing.create({ listing_id: testListing.id, listing_type_id: testListingType.id });

      const response = await request(app)
        .post('/api/type-listings')
        .set('Authorization', `Bearer ${authToken}`)
        .send({ listing_id: testListing.id, listing_type_id: testListingType.id })
        .expect(400);
    });
  });

  describe('PUT /api/type-listings/:id', () => {
    it('should update a type listing', async () => {
      const anotherType = await ListingType.create({
        name_en: 'For Rent',
        name_so: 'Kiro'
      });

      const typeListing = await TypeListing.create({ listing_id: testListing.id, listing_type_id: testListingType.id });

      const response = await request(app)
        .put(`/api/type-listings/${typeListing.id}`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({ listing_id: testListing.id, listing_type_id: anotherType.id })
        .expect(200);

      expect(response.body.listing_type_id).toEqual(anotherType.id);

      const updatedTypeListing = await TypeListing.findByPk(typeListing.id);
      expect(updatedTypeListing.listing_type_id).toEqual(anotherType.id);
    });

    it('should return 404 if type listing not found', async () => {
      const response = await request(app)
        .put('/api/type-listings/999')
        .set('Authorization', `Bearer ${authToken}`)
        .send({ listing_id: testListing.id, listing_type_id: testListingType.id })
        .expect(404);
    });

    it('should return 400 if listing does not exist', async () => {
      const typeListing = await TypeListing.create({ listing_id: testListing.id, listing_type_id: testListingType.id });

      const response = await request(app)
        .put(`/api/type-listings/${typeListing.id}`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({ listing_id: 999, listing_type_id: testListingType.id })
        .expect(400);
    });

    it('should return 400 if listing type does not exist', async () => {
      const typeListing = await TypeListing.create({ listing_id: testListing.id, listing_type_id: testListingType.id });

      const response = await request(app)
        .put(`/api/type-listings/${typeListing.id}`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({ listing_id: testListing.id, listing_type_id: 999 })
        .expect(400);
    });

    it('should return 400 if duplicate association', async () => {
      const anotherType = await ListingType.create({
        name_en: 'For Rent',
        name_so: 'Kiro'
      });

      await TypeListing.create({ listing_id: testListing.id, listing_type_id: anotherType.id });
      const typeListingToUpdate = await TypeListing.create({ listing_id: testListing.id, listing_type_id: testListingType.id });

      const response = await request(app)
        .put(`/api/type-listings/${typeListingToUpdate.id}`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({ listing_id: testListing.id, listing_type_id: anotherType.id })
        .expect(400);
    });
  });

  describe('DELETE /api/type-listings/:id', () => {
    it('should delete a type listing', async () => {
      const typeListing = await TypeListing.create({ listing_id: testListing.id, listing_type_id: testListingType.id });

      const response = await request(app)
        .delete(`/api/type-listings/${typeListing.id}`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(204);

      const deletedTypeListing = await TypeListing.findByPk(typeListing.id);
      expect(deletedTypeListing).toBeNull();
    });

    it('should return 404 if type listing not found', async () => {
      const response = await request(app)
        .delete('/api/type-listings/999')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(404);
    });
  });
});
