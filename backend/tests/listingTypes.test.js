process.env.NODE_ENV = 'test';
process.env.JWT_SECRET = 'test-secret';

const request = require('supertest');
const { sequelize, ListingType } = require('../src/models');
const jwt = require('jsonwebtoken');

describe('Listing Types API', () => {
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

    // Import and use the listingTypes routes
    const listingTypesRouter = require('../src/routes/listingTypes');
    app.use('/api/listing-types', listingTypesRouter);

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
    await ListingType.destroy({ where: {} });
  });

  describe('GET /api/listing-types', () => {
    it('should return a list of listing types', async () => {
      await ListingType.create({ name_en: 'For Sale', name_so: 'Iib' });
      await ListingType.create({ name_en: 'For Rent', name_so: 'Kiro' });

      const response = await request(app)
        .get('/api/listing-types')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.data.length).toEqual(2);
    });

    it('should support pagination', async () => {
      for (let i = 0; i < 15; i++) {
        await ListingType.create({ name_en: `Type ${i}`, name_so: `Nooc ${i}` });
      }

      const response = await request(app)
        .get('/api/listing-types?page=2&limit=5')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.data.length).toEqual(5);
      expect(response.body.pagination.page).toEqual(2);
      expect(response.body.pagination.limit).toEqual(5);
      expect(response.body.pagination.total).toEqual(15);
    });

    it('should support filtering', async () => {
      await ListingType.create({ name_en: 'For Sale', name_so: 'Iib' });
      await ListingType.create({ name_en: 'For Rent', name_so: 'Kiro' });

      const response = await request(app)
        .get('/api/listing-types?search=Sale')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.data.length).toEqual(1);
      expect(response.body.data[0].name_en).toEqual('For Sale');
    });

    it('should support sorting', async () => {
      await ListingType.create({ name_en: 'For Sale', name_so: 'Iib' });
      await ListingType.create({ name_en: 'For Rent', name_so: 'Kiro' });

      const response = await request(app)
        .get('/api/listing-types?sortBy=name_en&sortOrder=ASC')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.data.length).toEqual(2);
      expect(response.body.data[0].name_en).toEqual('For Rent');
      expect(response.body.data[1].name_en).toEqual('For Sale');
    });
  });

  describe('GET /api/listing-types/:id', () => {
    it('should return a single listing type', async () => {
      const listingType = await ListingType.create({ name_en: 'For Sale', name_so: 'Iib' });

      const response = await request(app)
        .get(`/api/listing-types/${listingType.id}`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.name_en).toEqual('For Sale');
    });

    it('should return 404 if listing type not found', async () => {
      const response = await request(app)
        .get('/api/listing-types/999')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(404);
    });
  });

  describe('POST /api/listing-types', () => {
    it('should create a new listing type', async () => {
      const response = await request(app)
        .post('/api/listing-types')
        .set('Authorization', `Bearer ${authToken}`)
        .send({ name_en: 'For Sale', name_so: 'Iib' })
        .expect(201);

      expect(response.body.name_en).toEqual('For Sale');

      const listingType = await ListingType.findOne({ where: { name_en: 'For Sale' } });
      expect(listingType).not.toBeNull();
    });

    it('should return 400 if name_en is not provided', async () => {
      const response = await request(app)
        .post('/api/listing-types')
        .set('Authorization', `Bearer ${authToken}`)
        .send({ name_so: 'Iib' })
        .expect(400);
    });

    it('should return 400 if name_so is not provided', async () => {
      const response = await request(app)
        .post('/api/listing-types')
        .set('Authorization', `Bearer ${authToken}`)
        .send({ name_en: 'For Sale' })
        .expect(400);
    });

    it('should return 400 if name_en is a duplicate', async () => {
      await ListingType.create({ name_en: 'For Sale', name_so: 'Iib' });

      const response = await request(app)
        .post('/api/listing-types')
        .set('Authorization', `Bearer ${authToken}`)
        .send({ name_en: 'For Sale', name_so: 'Iib' })
        .expect(400);
    });
  });

  describe('PUT /api/listing-types/:id', () => {
    it('should update a listing type', async () => {
      const listingType = await ListingType.create({ name_en: 'For Sale', name_so: 'Iib' });

      const response = await request(app)
        .put(`/api/listing-types/${listingType.id}`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({ name_en: 'For Rent', name_so: 'Kiro' })
        .expect(200);

      expect(response.body.name_en).toEqual('For Rent');

      const updatedListingType = await ListingType.findByPk(listingType.id);
      expect(updatedListingType.name_en).toEqual('For Rent');
    });

    it('should return 404 if listing type not found', async () => {
      const response = await request(app)
        .put('/api/listing-types/999')
        .set('Authorization', `Bearer ${authToken}`)
        .send({ name_en: 'For Rent', name_so: 'Kiro' })
        .expect(404);
    });

    it('should return 400 if name_en is not provided', async () => {
      const listingType = await ListingType.create({ name_en: 'For Sale', name_so: 'Iib' });

      const response = await request(app)
        .put(`/api/listing-types/${listingType.id}`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({ name_so: 'Kiro' })
        .expect(400);
    });

    it('should return 400 if name_so is not provided', async () => {
      const listingType = await ListingType.create({ name_en: 'For Sale', name_so: 'Iib' });

      const response = await request(app)
        .put(`/api/listing-types/${listingType.id}`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({ name_en: 'For Rent' })
        .expect(400);
    });

    it('should return 400 if name_en is a duplicate', async () => {
      await ListingType.create({ name_en: 'For Sale', name_so: 'Iib' });
      const listingTypeToUpdate = await ListingType.create({ name_en: 'For Rent', name_so: 'Kiro' });

      const response = await request(app)
        .put(`/api/listing-types/${listingTypeToUpdate.id}`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({ name_en: 'For Sale', name_so: 'Iib' })
        .expect(400);
    });
  });

  describe('DELETE /api/listing-types/:id', () => {
    it('should delete a listing type', async () => {
      const listingType = await ListingType.create({ name_en: 'For Sale', name_so: 'Iib' });

      const response = await request(app)
        .delete(`/api/listing-types/${listingType.id}`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(204);

      const deletedListingType = await ListingType.findByPk(listingType.id);
      expect(deletedListingType).toBeNull();
    });

    it('should return 404 if listing type not found', async () => {
      const response = await request(app)
        .delete('/api/listing-types/999')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(404);
    });
  });
});