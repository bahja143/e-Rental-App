process.env.NODE_ENV = 'test';
process.env.JWT_SECRET = 'test-secret';

const request = require('supertest');
const { sequelize, ListingReview, User, Listing } = require('../src/models');
const jwt = require('jsonwebtoken');

describe('Listing Reviews API', () => {
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

    // Import and use the listing reviews routes
    const listingReviewsRouter = require('../src/routes/listingReviews');
    app.use('/api/listing-reviews', listingReviewsRouter);

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
    await ListingReview.destroy({ where: {} });
  });

  describe('GET /api/listing-reviews', () => {
    it('should return empty array when no reviews exist', async () => {
      const response = await request(app)
        .get('/api/listing-reviews')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body).toHaveProperty('data');
      expect(response.body).toHaveProperty('pagination');
      expect(response.body.data).toHaveLength(0);
      expect(response.body.pagination.total).toBe(0);
    });

    it('should return reviews with default pagination', async () => {
      // Create test reviews
      const reviews = [];
      for (let i = 1; i <= 15; i++) {
        reviews.push({
          listing_id: testListing.id,
          user_id: testUser.id,
          rating: (i % 5) + 1,
          comment: `Review comment ${i}`,
        });
      }
      await ListingReview.bulkCreate(reviews);

      const response = await request(app)
        .get('/api/listing-reviews')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.data).toHaveLength(10); // Default limit
      expect(response.body.pagination.total).toBe(15);
      expect(response.body.pagination.totalPages).toBe(2);
      expect(response.body.pagination.page).toBe(1);
      expect(response.body.pagination.limit).toBe(10);
    });

    it('should filter reviews by listing_id', async () => {
      const otherListing = await Listing.create({
        user_id: testUser.id,
        title: 'Other Listing',
        lat: 40.7128,
        lng: -74.0060,
        address: 'Other Address',
        availability: '1',
        location: { type: 'Point', coordinates: [-74.0060, 40.7128] }
      });

      await ListingReview.bulkCreate([
        { listing_id: testListing.id, user_id: testUser.id, rating: 5, comment: 'Great listing' },
        { listing_id: otherListing.id, user_id: testUser.id, rating: 4, comment: 'Good listing' },
      ]);

      const response = await request(app)
        .get(`/api/listing-reviews?listing_id=${testListing.id}`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.data).toHaveLength(1);
      expect(response.body.data[0].comment).toBe('Great listing');
    });

    it('should filter reviews by rating range', async () => {
      await ListingReview.bulkCreate([
        { listing_id: testListing.id, user_id: testUser.id, rating: 3, comment: 'Average' },
        { listing_id: testListing.id, user_id: testUser.id, rating: 5, comment: 'Excellent' },
        { listing_id: testListing.id, user_id: testUser.id, rating: 1, comment: 'Poor' },
      ]);

      const response = await request(app)
        .get('/api/listing-reviews?rating_min=4&rating_max=5')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.data).toHaveLength(1);
      expect(response.body.data[0].comment).toBe('Excellent');
    });
  });

  describe('GET /api/listing-reviews/:id', () => {
    it('should get review by ID with user and listing data', async () => {
      const review = await ListingReview.create({
        listing_id: testListing.id,
        user_id: testUser.id,
        rating: 5,
        comment: 'Excellent property!',
      });

      const response = await request(app)
        .get(`/api/listing-reviews/${review.id}`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.id).toBe(review.id);
      expect(response.body.rating).toBe(5);
      expect(response.body.comment).toBe('Excellent property!');
      expect(response.body.user).toHaveProperty('id', testUser.id);
      expect(response.body.listing).toHaveProperty('id', testListing.id);
    });

    it('should return 404 for non-existent review', async () => {
      const response = await request(app)
        .get('/api/listing-reviews/999')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(404);

      expect(response.body.error).toBe('Listing review not found');
    });
  });

  describe('POST /api/listing-reviews', () => {
    it('should create a new review', async () => {
      const response = await request(app)
        .post('/api/listing-reviews')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          listing_id: testListing.id,
          user_id: testUser.id,
          rating: 4,
          comment: 'Great place to stay!',
          images: ['image1.jpg', 'image2.jpg'],
        })
        .expect(201);

      expect(response.body).toHaveProperty('id');
      expect(response.body.rating).toBe(4);
      expect(response.body.comment).toBe('Great place to stay!');
      expect(response.body.images).toEqual(['image1.jpg', 'image2.jpg']);
    });

    it('should return 400 for missing required fields', async () => {
      const response = await request(app)
        .post('/api/listing-reviews')
        .set('Authorization', `Bearer ${authToken}`)
        .send({ rating: 5 })
        .expect(400);

      expect(response.body.error).toContain('are required');
    });

    it('should return 400 for invalid rating', async () => {
      const response = await request(app)
        .post('/api/listing-reviews')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          listing_id: testListing.id,
          user_id: testUser.id,
          rating: 6, // Invalid rating
          comment: 'Test comment',
        })
        .expect(400);

      expect(response.body.error).toContain('between 1 and 5');
    });

    it('should prevent duplicate reviews from same user for same listing', async () => {
      await ListingReview.create({
        listing_id: testListing.id,
        user_id: testUser.id,
        rating: 5,
        comment: 'First review',
      });

      const response = await request(app)
        .post('/api/listing-reviews')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          listing_id: testListing.id,
          user_id: testUser.id,
          rating: 4,
          comment: 'Second review',
        })
        .expect(400);

      expect(response.body.error).toContain('already reviewed');
    });

    it('should sanitize comment input', async () => {
      const response = await request(app)
        .post('/api/listing-reviews')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          listing_id: testListing.id,
          user_id: testUser.id,
          rating: 5,
          comment: '  Comment with spaces  ',
        })
        .expect(201);

      expect(response.body.comment).toBe('Comment with spaces');
    });
  });

  describe('PUT /api/listing-reviews/:id', () => {
    it('should update a review', async () => {
      const review = await ListingReview.create({
        listing_id: testListing.id,
        user_id: testUser.id,
        rating: 3,
        comment: 'Original comment',
      });

      const response = await request(app)
        .put(`/api/listing-reviews/${review.id}`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          rating: 5,
          comment: 'Updated comment',
        })
        .expect(200);

      expect(response.body.rating).toBe(5);
      expect(response.body.comment).toBe('Updated comment');
    });

    it('should return 404 for non-existent review', async () => {
      const response = await request(app)
        .put('/api/listing-reviews/999')
        .set('Authorization', `Bearer ${authToken}`)
        .send({ rating: 4 })
        .expect(404);

      expect(response.body.error).toBe('Listing review not found');
    });

    it('should validate rating on update', async () => {
      const review = await ListingReview.create({
        listing_id: testListing.id,
        user_id: testUser.id,
        rating: 4,
        comment: 'Test comment',
      });

      const response = await request(app)
        .put(`/api/listing-reviews/${review.id}`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({ rating: 0 }) // Invalid rating
        .expect(400);

      expect(response.body.error).toContain('between 1 and 5');
    });
  });

  describe('DELETE /api/listing-reviews/:id', () => {
    it('should delete a review', async () => {
      const review = await ListingReview.create({
        listing_id: testListing.id,
        user_id: testUser.id,
        rating: 5,
        comment: 'To delete',
      });

      const response = await request(app)
        .delete(`/api/listing-reviews/${review.id}`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(204);

      // Verify deletion
      const deleted = await ListingReview.findByPk(review.id);
      expect(deleted).toBeNull();
    });

    it('should return 404 for non-existent review', async () => {
      const response = await request(app)
        .delete('/api/listing-reviews/999')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(404);

      expect(response.body.error).toBe('Listing review not found');
    });
  });
});
