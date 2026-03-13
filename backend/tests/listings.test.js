process.env.NODE_ENV = 'test';
process.env.JWT_SECRET = 'test-secret';

const request = require('supertest');
const { sequelize, Listing, User } = require('../src/models');
const jwt = require('jsonwebtoken');

describe('Listings API', () => {
  let app;
  let server;
  let authToken;
  let testUser;

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

    // Create a test JWT token
    const payload = { id: testUser.id, email: testUser.email };
    authToken = jwt.sign(payload, process.env.JWT_SECRET || 'test-secret', { expiresIn: '1h' });

    // Import and use the listings routes
    const listingsRouter = require('../src/routes/listings');
    app.use('/api/listings', listingsRouter);

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
    await Listing.destroy({ where: {} });
  });

  describe('GET /api/listings', () => {
    it('should return empty array when no listings exist', async () => {
      const response = await request(app)
        .get('/api/listings')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body).toHaveProperty('data');
      expect(response.body).toHaveProperty('pagination');
      expect(response.body.data).toHaveLength(0);
      expect(response.body.pagination.total).toBe(0);
    });

    it('should return listings with default pagination', async () => {
      // Create test listings
      const listings = [];
      for (let i = 1; i <= 15; i++) {
        listings.push({
          user_id: testUser.id,
          title: `Listing ${i}`,
          lat: 40.7128 + i * 0.01,
          lng: -74.0060 + i * 0.01,
          address: `Address ${i}`,
          sell_price: 100000 + i * 10000,
          availability: '1',
          location: { type: 'Point', coordinates: [-74.0060 + i * 0.01, 40.7128 + i * 0.01] }
        });
      }
      await Listing.bulkCreate(listings.map(listing => ({
        ...listing,
        location: { type: 'Point', coordinates: [listing.lng, listing.lat] }
      })));

      const response = await request(app)
        .get('/api/listings')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.data).toHaveLength(10); // Default limit
      expect(response.body.pagination.total).toBe(15);
      expect(response.body.pagination.totalPages).toBe(2);
      expect(response.body.pagination.page).toBe(1);
      expect(response.body.pagination.limit).toBe(10);
    });

    it('should support custom pagination', async () => {
      // Create test listings
      const listings = [];
      for (let i = 1; i <= 25; i++) {
        listings.push({
          user_id: testUser.id,
          title: `Listing ${i}`,
          lat: 40.7128 + i * 0.01,
          lng: -74.0060 + i * 0.01,
          address: `Address ${i}`,
          sell_price: 100000 + i * 10000,
          availability: '1',
          location: { type: 'Point', coordinates: [-74.0060 + i * 0.01, 40.7128 + i * 0.01] }
        });
      }
      await Listing.bulkCreate(listings.map(listing => ({
        ...listing,
        location: { type: 'Point', coordinates: [listing.lng, listing.lat] }
      })));

      const response = await request(app)
        .get('/api/listings?page=2&limit=5')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.data).toHaveLength(5);
      expect(response.body.pagination.total).toBe(25);
      expect(response.body.pagination.totalPages).toBe(5);
      expect(response.body.pagination.page).toBe(2);
      expect(response.body.pagination.limit).toBe(5);
    });

    it('should filter listings by user_id', async () => {
      const otherUser = await User.create({
        name: 'Other User',
        email: 'other@example.com',
        password: 'password123',
      });

      await Listing.bulkCreate([
        { user_id: testUser.id, title: 'My Listing', lat: 40.7128, lng: -74.0060, address: 'Address 1', availability: '1', location: { type: 'Point', coordinates: [-74.0060, 40.7128] } },
        { user_id: otherUser.id, title: 'Other Listing', lat: 40.7128, lng: -74.0060, address: 'Address 2', availability: '1', location: { type: 'Point', coordinates: [-74.0060, 40.7128] } },
      ].map(listing => ({
        ...listing,
        location: { type: 'Point', coordinates: [listing.lng, listing.lat] }
      })));

      const response = await request(app)
        .get(`/api/listings?user_id=${testUser.id}`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.data).toHaveLength(1);
      expect(response.body.data[0].title).toBe('My Listing');
    });

    it('should filter listings by sell_price range', async () => {
      await Listing.bulkCreate([
        { user_id: testUser.id, title: 'Cheap', lat: 40.7128, lng: -74.0060, address: 'Address 1', sell_price: 50000, availability: '1', location: { type: 'Point', coordinates: [-74.0060, 40.7128] } },
        { user_id: testUser.id, title: 'Medium', lat: 40.7128, lng: -74.0060, address: 'Address 2', sell_price: 150000, availability: '1', location: { type: 'Point', coordinates: [-74.0060, 40.7128] } },
        { user_id: testUser.id, title: 'Expensive', lat: 40.7128, lng: -74.0060, address: 'Address 3', sell_price: 300000, availability: '1', location: { type: 'Point', coordinates: [-74.0060, 40.7128] } },
      ].map(listing => ({
        ...listing,
        location: { type: 'Point', coordinates: [listing.lng, listing.lat] }
      })));

      const response = await request(app)
        .get('/api/listings?sell_price_min=100000&sell_price_max=200000')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.data).toHaveLength(1);
      expect(response.body.data[0].title).toBe('Medium');
    });

    it('should filter listings by rent_type', async () => {
      await Listing.bulkCreate([
        { user_id: testUser.id, title: 'Daily', lat: 40.7128, lng: -74.0060, address: 'Address 1', rent_type: 'daily', availability: '1', location: { type: 'Point', coordinates: [-74.0060, 40.7128] } },
        { user_id: testUser.id, title: 'Monthly', lat: 40.7128, lng: -74.0060, address: 'Address 2', rent_type: 'monthly', availability: '1', location: { type: 'Point', coordinates: [-74.0060, 40.7128] } },
      ].map(listing => ({
        ...listing,
        location: { type: 'Point', coordinates: [listing.lng, listing.lat] }
      })));

      const response = await request(app)
        .get('/api/listings?rent_type=daily')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.data).toHaveLength(1);
      expect(response.body.data[0].title).toBe('Daily');
    });

    it('should filter listings by availability', async () => {
      await Listing.bulkCreate([
        { user_id: testUser.id, title: 'Available', lat: 40.7128, lng: -74.0060, address: 'Address 1', availability: '1', location: { type: 'Point', coordinates: [-74.0060, 40.7128] } },
        { user_id: testUser.id, title: 'Unavailable', lat: 40.7128, lng: -74.0060, address: 'Address 2', availability: '2', location: { type: 'Point', coordinates: [-74.0060, 40.7128] } },
      ].map(listing => ({
        ...listing,
        location: { type: 'Point', coordinates: [listing.lng, listing.lat] }
      })));

      const response = await request(app)
        .get('/api/listings?availability=1')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.data).toHaveLength(1);
      expect(response.body.data[0].title).toBe('Available');
    });

    it('should sort listings by createdAt DESC by default', async () => {
      const listing1 = await Listing.create({
        user_id: testUser.id,
        title: 'First',
        lat: 40.7128,
        lng: -74.0060,
        address: 'Address 1',
        availability: '1',
        location: { type: 'Point', coordinates: [-74.0060, 40.7128] }
      });
      const listing2 = await Listing.create({
        user_id: testUser.id,
        title: 'Second',
        lat: 40.7128,
        lng: -74.0060,
        address: 'Address 2',
        availability: '1',
        location: { type: 'Point', coordinates: [-74.0060, 40.7128] }
      });

      const response = await request(app)
        .get('/api/listings')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.data[0].title).toBe('Second'); // Most recent first
      expect(response.body.data[1].title).toBe('First');
    });
  });

  describe('GET /api/listings/:id', () => {
    it('should get listing by ID with user data', async () => {
      const listing = await Listing.create({
        user_id: testUser.id,
        title: 'Test Listing',
        lat: 40.7128,
        lng: -74.0060,
        address: 'Test Address',
        availability: '1',
        location: { type: 'Point', coordinates: [-74.0060, 40.7128] }
      });

      const response = await request(app)
        .get(`/api/listings/${listing.id}`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.id).toBe(listing.id);
      expect(response.body.title).toBe('Test Listing');
      expect(response.body.user).toHaveProperty('id', testUser.id);
      expect(response.body.user).toHaveProperty('name', testUser.name);
    });

    it('should return 404 for non-existent listing', async () => {
      const response = await request(app)
        .get('/api/listings/999')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(404);

      expect(response.body.error).toBe('Listing not found');
    });
  });

  describe('POST /api/listings', () => {
    it('should create a new listing', async () => {
      const response = await request(app)
        .post('/api/listings')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          user_id: testUser.id,
          title: 'New Listing',
          lat: 40.7128,
          lng: -74.0060,
          address: 'New Address',
          sell_price: 200000,
          availability: '1',
          location: { type: 'Point', coordinates: [-74.0060, 40.7128] }
        })
        .expect(201);

      expect(response.body).toHaveProperty('id');
      expect(response.body.title).toBe('New Listing');
      expect(response.body.sell_price).toBe(200000);
    });

    it('should create listing with rent details', async () => {
      const response = await request(app)
        .post('/api/listings')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          user_id: testUser.id,
          title: 'Rent Listing',
          lat: 40.7128,
          lng: -74.0060,
          address: 'Rent Address',
          rent_price: 1500,
          rent_type: 'monthly',
          availability: '1',
          location: { type: 'Point', coordinates: [-74.0060, 40.7128] }
        })
        .expect(201);

      expect(response.body.rent_price).toBe(1500);
      expect(response.body.rent_type).toBe('monthly');
    });

    it('should create listing with images array', async () => {
      const images = ['image1.jpg', 'image2.jpg'];
      const response = await request(app)
        .post('/api/listings')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          user_id: testUser.id,
          title: 'Image Listing',
          lat: 40.7128,
          lng: -74.0060,
          address: 'Image Address',
          images,
          availability: '1',
          location: { type: 'Point', coordinates: [-74.0060, 40.7128] }
        })
        .expect(201);

      expect(response.body.images).toEqual(images);
    });

    it('should return 400 for missing required fields', async () => {
      const response = await request(app)
        .post('/api/listings')
        .set('Authorization', `Bearer ${authToken}`)
        .send({ title: 'Incomplete Listing' })
        .expect(400);

      expect(response.body.error).toContain('are required');
    });

    it('should return 400 for invalid coordinates', async () => {
      const response = await request(app)
        .post('/api/listings')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          user_id: testUser.id,
          title: 'Invalid Coords',
          lat: 100, // Invalid latitude
          lng: -74.0060,
          address: 'Address',
          availability: '1'
        })
        .expect(400);

      expect(response.body.error).toContain('latitude');
    });

    it('should return 400 for invalid user_id', async () => {
      const response = await request(app)
        .post('/api/listings')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          user_id: 999, // Non-existent user
          title: 'Invalid User',
          lat: 40.7128,
          lng: -74.0060,
          address: 'Address',
          availability: '1'
        })
        .expect(400);

      expect(response.body.error).toContain('user_id');
    });

    it('should sanitize inputs', async () => {
      const response = await request(app)
        .post('/api/listings')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          user_id: testUser.id,
          title: '  Title with spaces  ',
          lat: 40.7128,
          lng: -74.0060,
          address: '  Address with spaces  ',
          description: '  Description with spaces  ',
          availability: '1',
          location: { type: 'Point', coordinates: [-74.0060, 40.7128] }
        })
        .expect(201);

      expect(response.body.title).toBe('Title with spaces');
      expect(response.body.address).toBe('Address with spaces');
      expect(response.body.description).toBe('Description with spaces');
    });
  });

  describe('PUT /api/listings/:id', () => {
    it('should update a listing', async () => {
      const listing = await Listing.create({
        user_id: testUser.id,
        title: 'Original Title',
        lat: 40.7128,
        lng: -74.0060,
        address: 'Original Address',
        availability: '1',
        location: { type: 'Point', coordinates: [-74.0060, 40.7128] }
      });

      const response = await request(app)
        .put(`/api/listings/${listing.id}`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          title: 'Updated Title',
          sell_price: 250000
        })
        .expect(200);

      expect(response.body.title).toBe('Updated Title');
      expect(response.body.sell_price).toBe(250000);
    });

    it('should return 404 for non-existent listing', async () => {
      const response = await request(app)
        .put('/api/listings/999')
        .set('Authorization', `Bearer ${authToken}`)
        .send({ title: 'Updated Title' })
        .expect(404);

      expect(response.body.error).toBe('Listing not found');
    });

    it('should validate coordinates on update', async () => {
      const listing = await Listing.create({
        user_id: testUser.id,
        title: 'Test',
        lat: 40.7128,
        lng: -74.0060,
        address: 'Address',
        availability: '1',
        location: { type: 'Point', coordinates: [-74.0060, 40.7128] }
      });

      const response = await request(app)
        .put(`/api/listings/${listing.id}`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({ lat: 200 }) // Invalid latitude
        .expect(400);

      expect(response.body.error).toContain('latitude');
    });
  });

  describe('DELETE /api/listings/:id', () => {
    it('should delete a listing', async () => {
      const listing = await Listing.create({
        user_id: testUser.id,
        title: 'To Delete',
        lat: 40.7128,
        lng: -74.0060,
        address: 'Address',
        availability: '1',
        location: { type: 'Point', coordinates: [-74.0060, 40.7128] }
      });

      const response = await request(app)
        .delete(`/api/listings/${listing.id}`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(204);

      // Verify deletion
      const deleted = await Listing.findByPk(listing.id);
      expect(deleted).toBeNull();
    });

    it('should return 404 for non-existent listing', async () => {
      const response = await request(app)
        .delete('/api/listings/999')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(404);

      expect(response.body.error).toBe('Listing not found');
    });
  });
});
