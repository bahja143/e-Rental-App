process.env.NODE_ENV = 'test';

const request = require('supertest');
const { sequelize, Favourite, User, Listing } = require('../src/models');

// Mock the auth middleware to bypass authentication for tests
jest.mock('../src/middleware/authMiddleware', () => ({
  authenticateToken: (req, res, next) => {
    // Mock user for authenticated requests
    req.user = { id: 1, role: 'user' };
    next();
  }
}));

const mongoose = require('mongoose');
jest.mock('../src/queues', () => ({
  emailQueue: {
    add: jest.fn(),
    close: jest.fn(),
  },
  emailWorker: {
    close: jest.fn(),
  },
}));

describe('Favourites API', () => {
  let app;
  let server;
  let testUser;
  let testListing;

  beforeAll(async () => {
    // Import app after mocking
    app = require('../src/app');

    // Sync the in-memory database
    await sequelize.sync({ force: true });

    // Create test user and listing
    testUser = await User.create({
      name: 'Test User',
      email: 'test@example.com',
      password: 'password123',
      phone: '+252123456789',
    });

    testListing = await Listing.create({
      user_id: testUser.id,
      title: 'Test Listing',
      lat: 2.0469,
      lng: 45.3182,
      address: 'Test Address',
    });

    // Start the server
    server = app.listen(0); // Use port 0 for automatic port assignment
  });

  afterAll(async () => {
    if (server) {
      server.close();
    }
    await sequelize.close();
    await mongoose.connection.close();
  });

  beforeEach(async () => {
    // Clear the favourites table before each test
    await Favourite.destroy({ where: {} });
  });

  describe('GET /api/favourites', () => {
    it('should return empty array when no favourites exist', async () => {
      const response = await request(app)
        .get('/api/favourites')
        .expect(200);

      expect(response.body).toHaveProperty('data');
      expect(response.body).toHaveProperty('pagination');
      expect(response.body.data).toHaveLength(0);
      expect(response.body.pagination.totalItems).toBe(0);
    });

    it('should return favourites with default pagination', async () => {
      // Create test favourites
      const favourites = [];
      for (let i = 1; i <= 15; i++) {
        const user = await User.create({
          name: `User ${i}`,
          email: `user${i}@example.com`,
          password: 'password123',
        });
        const listing = await Listing.create({
          user_id: user.id,
          title: `Listing ${i}`,
          lat: 2.0469,
          lng: 45.3182,
          address: `Address ${i}`,
        });
        favourites.push({
          user_id: user.id,
          listing_id: listing.id,
          add_date: new Date(),
        });
      }
      await Favourite.bulkCreate(favourites);

      const response = await request(app)
        .get('/api/favourites')
        .expect(200);

      expect(response.body.data).toHaveLength(10); // Default limit
      expect(response.body.pagination.totalItems).toBe(15);
      expect(response.body.pagination.totalPages).toBe(2);
      expect(response.body.pagination.hasNextPage).toBe(true);
      expect(response.body.pagination.hasPrevPage).toBe(false);
    });

    it('should filter favourites by user_id', async () => {
      const user2 = await User.create({
        name: 'User 2',
        email: 'user2@example.com',
        password: 'password123',
        phone: '+252123456790',
      });

      await Favourite.create({
        user_id: testUser.id,
        listing_id: testListing.id,
      });

      await Favourite.create({
        user_id: user2.id,
        listing_id: testListing.id,
      });

      const response = await request(app)
        .get(`/api/favourites?user_id=${testUser.id}`)
        .expect(200);

      expect(response.body.data).toHaveLength(1);
      expect(response.body.data[0].user_id).toBe(testUser.id);
    });

    it('should filter favourites by listing_id', async () => {
      const listing2 = await Listing.create({
        user_id: testUser.id,
        title: 'Listing 2',
        lat: 2.0469,
        lng: 45.3182,
        address: 'Address 2',
      });

      await Favourite.create({
        user_id: testUser.id,
        listing_id: testListing.id,
      });

      await Favourite.create({
        user_id: testUser.id,
        listing_id: listing2.id,
      });

      const response = await request(app)
        .get(`/api/favourites?listing_id=${testListing.id}`)
        .expect(200);

      expect(response.body.data).toHaveLength(1);
      expect(response.body.data[0].listing_id).toBe(testListing.id);
    });

    it('should sort favourites by add_date', async () => {
      const oldDate = new Date('2023-01-01');
      const newDate = new Date('2023-12-31');

      await Favourite.create({
        user_id: testUser.id,
        listing_id: testListing.id,
        add_date: oldDate,
      });

      const user2 = await User.create({
        name: 'User 2',
        email: 'user2@example.com',
        password: 'password123',
        phone: '+252123456791',
      });
      const listing2 = await Listing.create({
        user_id: user2.id,
        title: 'Listing 2',
        lat: 2.0469,
        lng: 45.3182,
        address: 'Address 2',
      });

      await Favourite.create({
        user_id: user2.id,
        listing_id: listing2.id,
        add_date: newDate,
      });

      const response = await request(app)
        .get('/api/favourites?sortBy=add_date&sortOrder=DESC')
        .expect(200);

      expect(response.body.data).toHaveLength(2);
      expect(new Date(response.body.data[0].add_date).getTime()).toBeGreaterThan(
        new Date(response.body.data[1].add_date).getTime()
      );
    });
  });

  describe('GET /api/favourites/:user_id/:listing_id', () => {
    it('should return a favourite', async () => {
      const favourite = await Favourite.create({
        user_id: testUser.id,
        listing_id: testListing.id,
      });

      const response = await request(app)
        .get(`/api/favourites/${testUser.id}/${testListing.id}`)
        .expect(200);

      expect(response.body.user_id).toBe(testUser.id);
      expect(response.body.listing_id).toBe(testListing.id);
      expect(response.body.user).toHaveProperty('name');
      expect(response.body.listing).toHaveProperty('title');
    });

    it('should return 404 for non-existent favourite', async () => {
      const response = await request(app)
        .get('/api/favourites/999/999')
        .expect(404);

      expect(response.body.error).toBe('Favourite not found');
    });

    it('should handle invalid user_id', async () => {
      const response = await request(app)
        .get('/api/favourites/invalid/1')
        .expect(400);

      expect(response.body.error).toBe('Invalid user_id');
    });

    it('should handle invalid listing_id', async () => {
      const response = await request(app)
        .get('/api/favourites/1/invalid')
        .expect(400);

      expect(response.body.error).toBe('Invalid listing_id');
    });
  });

  describe('POST /api/favourites', () => {
    it('should create a new favourite', async () => {
      const response = await request(app)
        .post('/api/favourites')
        .send({
          user_id: testUser.id,
          listing_id: testListing.id,
        })
        .expect(201);

      expect(response.body.message).toBe('Favourite created successfully');
      expect(response.body.favourite.user_id).toBe(testUser.id);
      expect(response.body.favourite.listing_id).toBe(testListing.id);
      expect(response.body.favourite.user).toHaveProperty('name');
      expect(response.body.favourite.listing).toHaveProperty('title');
    });

    it('should create favourite with custom add_date', async () => {
      const customDate = '2023-06-15T10:30:00Z';

      const response = await request(app)
        .post('/api/favourites')
        .send({
          user_id: testUser.id,
          listing_id: testListing.id,
          add_date: customDate,
        })
        .expect(201);

      expect(response.body.favourite.add_date).toBe(customDate);
    });

    it('should return 404 for non-existent user', async () => {
      const response = await request(app)
        .post('/api/favourites')
        .send({
          user_id: 999,
          listing_id: testListing.id,
        })
        .expect(404);

      expect(response.body.error).toBe('User not found');
    });

    it('should return 404 for non-existent listing', async () => {
      const response = await request(app)
        .post('/api/favourites')
        .send({
          user_id: testUser.id,
          listing_id: 999,
        })
        .expect(404);

      expect(response.body.error).toBe('Listing not found');
    });

    it('should return 409 for duplicate favourite', async () => {
      await Favourite.create({
        user_id: testUser.id,
        listing_id: testListing.id,
      });

      const response = await request(app)
        .post('/api/favourites')
        .send({
          user_id: testUser.id,
          listing_id: testListing.id,
        })
        .expect(409);

      expect(response.body.error).toBe('Favourite already exists');
    });

    it('should validate user_id', async () => {
      const response = await request(app)
        .post('/api/favourites')
        .send({
          user_id: 'invalid',
          listing_id: testListing.id,
        })
        .expect(400);

      expect(response.body.error).toBe('Invalid user_id');
    });

    it('should validate listing_id', async () => {
      const response = await request(app)
        .post('/api/favourites')
        .send({
          user_id: testUser.id,
          listing_id: 'invalid',
        })
        .expect(400);

      expect(response.body.error).toBe('Invalid listing_id');
    });

    it('should validate add_date format', async () => {
      const response = await request(app)
        .post('/api/favourites')
        .send({
          user_id: testUser.id,
          listing_id: testListing.id,
          add_date: 'invalid-date',
        })
        .expect(400);

      expect(response.body.error).toBe('Invalid add_date format');
    });
  });

  describe('PUT /api/favourites/:user_id/:listing_id', () => {
    let testFavourite;

    beforeEach(async () => {
      testFavourite = await Favourite.create({
        user_id: testUser.id,
        listing_id: testListing.id,
      });
    });

    it('should update favourite add_date', async () => {
      const newDate = '2023-12-25T00:00:00Z';

      const response = await request(app)
        .put(`/api/favourites/${testUser.id}/${testListing.id}`)
        .send({ add_date: newDate })
        .expect(200);

      expect(response.body.message).toBe('Favourite updated successfully');
      expect(response.body.favourite.add_date).toBe(newDate);
    });

    it('should return 404 for non-existent favourite', async () => {
      const response = await request(app)
        .put('/api/favourites/999/999')
        .send({ add_date: '2023-01-01T00:00:00Z' })
        .expect(404);

      expect(response.body.error).toBe('Favourite not found');
    });

    it('should validate add_date format on update', async () => {
      const response = await request(app)
        .put(`/api/favourites/${testUser.id}/${testListing.id}`)
        .send({ add_date: 'invalid-date' })
        .expect(400);

      expect(response.body.error).toBe('Invalid add_date format');
    });

    it('should handle no fields to update', async () => {
      const response = await request(app)
        .put(`/api/favourites/${testUser.id}/${testListing.id}`)
        .send({})
        .expect(400);

      expect(response.body.error).toBe('No valid fields to update');
    });
  });

  describe('DELETE /api/favourites/:user_id/:listing_id', () => {
    let testFavourite;

    beforeEach(async () => {
      testFavourite = await Favourite.create({
        user_id: testUser.id,
        listing_id: testListing.id,
      });
    });

    it('should delete a favourite', async () => {
      const response = await request(app)
        .delete(`/api/favourites/${testUser.id}/${testListing.id}`)
        .expect(200);

      expect(response.body.message).toBe('Favourite deleted successfully');

      // Verify deletion
      const deleted = await Favourite.findOne({
        where: { user_id: testUser.id, listing_id: testListing.id },
      });
      expect(deleted).toBeNull();
    });

    it('should return 404 for non-existent favourite', async () => {
      const response = await request(app)
        .delete('/api/favourites/999/999')
        .expect(404);

      expect(response.body.error).toBe('Favourite not found');
    });

    it('should handle invalid user_id', async () => {
      const response = await request(app)
        .delete('/api/favourites/invalid/1')
        .expect(400);

      expect(response.body.error).toBe('Invalid user_id');
    });

    it('should handle invalid listing_id', async () => {
      const response = await request(app)
        .delete('/api/favourites/1/invalid')
        .expect(400);

      expect(response.body.error).toBe('Invalid listing_id');
    });
  });
});
