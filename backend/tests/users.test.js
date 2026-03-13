process.env.NODE_ENV = 'test';

const request = require('supertest');
const { sequelize, User } = require('../src/models');

// Mock the auth middleware to bypass authentication for tests
jest.mock('../src/middleware/authMiddleware', () => ({
  authenticateToken: (req, res, next) => {
    // Mock user for authenticated requests - use the actual user ID from the test
    req.user = { id: req.params?.id ? parseInt(req.params.id) : 1, role: 'user' };
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


describe('Users API', () => {
  let app;
  let server;

  beforeAll(async () => {
    // Import app after mocking
    app = require('../src/app');

    // Sync the in-memory database
    await sequelize.sync({ force: true });

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
    // Clear the table before each test
    await User.destroy({ where: {} });
    // Reset SQLite auto-increment sequence
    await sequelize.query('DELETE FROM sqlite_sequence WHERE name = "users"');
  });

  describe('GET /api/users', () => {
    it('should return empty array when no users exist', async () => {
      const response = await request(app)
        .get('/api/users')
        .expect(200);

      expect(response.body).toHaveProperty('data');
      expect(response.body).toHaveProperty('pagination');
      expect(response.body.data).toHaveLength(0);
      expect(response.body.pagination.totalItems).toBe(0);
    });

    it('should return users with default pagination', async () => {
      // Create test users
      const users = [];
      for (let i = 1; i <= 15; i++) {
        users.push({
          name: `User ${i}`,
          email: `user${i}@example.com`,
          password: 'password123',
          city: `City ${i}`,
          looking_for: 'buy',
          lat: 40.7128 + i * 0.01,
          lng: -74.0060 + i * 0.01,
        });
      }
      await User.bulkCreate(users);

      const response = await request(app)
        .get('/api/users')
        .expect(200);

      expect(response.body.data).toHaveLength(10); // Default limit
      expect(response.body.pagination.totalItems).toBe(15);
      expect(response.body.pagination.totalPages).toBe(2);
      expect(response.body.pagination.currentPage).toBe(1);
      expect(response.body.pagination.hasNextPage).toBe(true);
      expect(response.body.pagination.hasPrevPage).toBe(false);
    });

    it('should support pagination', async () => {
      // Create test users
      const users = [];
      for (let i = 1; i <= 25; i++) {
        users.push({
          name: `User ${i}`,
          email: `user${i}@example.com`,
          password: 'password123',
          city: `City ${i}`,
          looking_for: 'buy',
        });
      }
      await User.bulkCreate(users);

      const response = await request(app)
        .get('/api/users?page=2&limit=10')
        .expect(200);

      expect(response.body.data).toHaveLength(10);
      expect(response.body.pagination.totalItems).toBe(25);
      expect(response.body.pagination.currentPage).toBe(2);
      expect(response.body.pagination.hasNextPage).toBe(true);
      expect(response.body.pagination.hasPrevPage).toBe(true);
    });

    it('should support search functionality', async () => {
      await User.create({
        name: 'John Doe',
        email: 'john@example.com',
        password: 'password123',
        city: 'New York',
        looking_for: 'buy',
      });
      await User.create({
        name: 'Jane Smith',
        email: 'jane@example.com',
        password: 'password123',
        city: 'Los Angeles',
        looking_for: 'sale',
      });
      await User.create({
        name: 'Bob Johnson',
        email: 'bob@example.com',
        password: 'password123',
        city: 'Chicago',
        looking_for: 'rent',
      });

      const response = await request(app)
        .get('/api/users?search=john')
        .expect(200);

      expect(response.body.data).toHaveLength(2);
      expect(response.body.data.some(user => user.name === 'John Doe')).toBe(true);
      expect(response.body.data.some(user => user.email === 'bob@example.com')).toBe(true);
    });

    it('should support city filtering', async () => {
      await User.create({
        name: 'User 1',
        email: 'user1@example.com',
        password: 'password123',
        city: 'New York',
        looking_for: 'buy',
      });
      await User.create({
        name: 'User 2',
        email: 'user2@example.com',
        password: 'password123',
        city: 'Los Angeles',
        looking_for: 'buy',
      });
      await User.create({
        name: 'User 3',
        email: 'user3@example.com',
        password: 'password123',
        city: 'New York',
        looking_for: 'sale',
      });

      const response = await request(app)
        .get('/api/users?city=new york')
        .expect(200);

      expect(response.body.data).toHaveLength(2);
      expect(response.body.data.every(user => user.city === 'New York')).toBe(true);
    });

    it('should support looking_for filtering', async () => {
      await User.create({
        name: 'Buyer',
        email: 'buyer@example.com',
        password: 'password123',
        city: 'New York',
        looking_for: 'buy',
      });
      await User.create({
        name: 'Seller',
        email: 'seller@example.com',
        password: 'password123',
        city: 'Los Angeles',
        looking_for: 'sale',
      });

      const response = await request(app)
        .get('/api/users?looking_for=buy')
        .expect(200);

      expect(response.body.data).toHaveLength(1);
      expect(response.body.data[0].looking_for).toBe('buy');
    });

    it('should support sorting', async () => {
      await User.create({
        name: 'Zoe',
        email: 'zoe@example.com',
        password: 'password123',
        city: 'New York',
        looking_for: 'buy',
      });
      await User.create({
        name: 'Alice',
        email: 'alice@example.com',
        password: 'password123',
        city: 'Los Angeles',
        looking_for: 'buy',
      });

      const response = await request(app)
        .get('/api/users?sortBy=name&sortOrder=ASC')
        .expect(200);

      expect(response.body.data[0].name).toBe('Alice');
      expect(response.body.data[1].name).toBe('Zoe');
    });

    it('should handle invalid page number', async () => {
      const response = await request(app)
        .get('/api/users?page=invalid')
        .expect(400);

      expect(response.body.error).toBe('Invalid page number');
    });

    it('should handle invalid limit', async () => {
      const response = await request(app)
        .get('/api/users?limit=200')
        .expect(400);

      expect(response.body.error).toBe('Invalid limit (1-100)');
    });

    it('should exclude sensitive fields from response', async () => {
      await User.create({
        name: 'Test User',
        email: 'test@example.com',
        password: 'password123',
        city: 'Test City',
        looking_for: 'buy',
      });

      const response = await request(app)
        .get('/api/users')
        .expect(200);

      expect(response.body.data[0]).not.toHaveProperty('password');
      expect(response.body.data[0]).not.toHaveProperty('two_factor_code');
      expect(response.body.data[0]).not.toHaveProperty('two_factor_expire');
    });
  });

  describe('GET /api/users/:id', () => {
    it('should return a user by ID', async () => {
      const user = await User.create({
        name: 'Test User',
        email: 'test@example.com',
        password: 'password123',
        city: 'Test City',
        looking_for: 'buy',
      });

      const response = await request(app)
        .get(`/api/users/${user.id}`)
        .expect(200);

      expect(response.body.id).toBe(user.id);
      expect(response.body.name).toBe('Test User');
      expect(response.body.email).toBe('test@example.com');
    });

    it('should return 404 for non-existent user', async () => {
      const response = await request(app)
        .get('/api/users/999')
        .expect(404);

      expect(response.body.error).toBe('User not found');
    });

    it('should handle invalid ID', async () => {
      const response = await request(app)
        .get('/api/users/invalid')
        .expect(400);

      expect(response.body.error).toBe('Invalid user ID');
    });

    it('should exclude sensitive fields from response', async () => {
      const user = await User.create({
        name: 'Test User',
        email: 'test@example.com',
        password: 'password123',
        city: 'Test City',
        looking_for: 'buy',
      });

      const response = await request(app)
        .get(`/api/users/${user.id}`)
        .expect(200);

      expect(response.body).not.toHaveProperty('password');
      expect(response.body).not.toHaveProperty('two_factor_code');
      expect(response.body).not.toHaveProperty('two_factor_expire');
    });
  });

  describe('POST /api/users', () => {
    it('should create a new user', async () => {
      const newUser = {
        name: 'New User',
        email: 'newuser@example.com',
        password: 'password123',
        phone: '+1234567890',
        city: 'New City',
        lat: 40.7128,
        lng: -74.0060,
        looking_for: 'buy',
        profile_picture_url: 'https://example.com/profile.jpg',
        pending_balance: 100,
        available_balance: 200,
        looking_for_set: true,
        category_set: false,
      };

      const response = await request(app)
        .post('/api/users')
        .send(newUser)
        .expect(201);

      expect(response.body.message).toBe('User created successfully');
      expect(response.body.user.name).toBe(newUser.name);
      expect(response.body.user.email).toBe(newUser.email);
      expect(response.body.user.city).toBe(newUser.city);
      expect(response.body.user.looking_for).toBe(newUser.looking_for);
      expect(response.body.user.pending_balance).toBe(newUser.pending_balance);
      expect(response.body.user.available_balance).toBe(newUser.available_balance);
    });

    it('should create user with minimal required fields', async () => {
      const newUser = {
        name: 'Minimal User',
        email: 'minimal@example.com',
        password: 'password123',
      };

      const response = await request(app)
        .post('/api/users')
        .send(newUser)
        .expect(201);

      expect(response.body.user.name).toBe(newUser.name);
      expect(response.body.user.email).toBe(newUser.email);
      expect(response.body.user.looking_for).toBe('just_look_around'); // default value
      expect(response.body.user.pending_balance).toBe(0);
      expect(response.body.user.available_balance).toBe(0);
    });

    it('should validate required fields', async () => {
      const response = await request(app)
        .post('/api/users')
        .send({})
        .expect(400);

      expect(response.body.error).toBe('Name must be 2-100 characters');
    });

    it('should validate name length', async () => {
      const response = await request(app)
        .post('/api/users')
        .send({
          name: 'A',
          email: 'test@example.com',
          password: 'password123',
        })
        .expect(400);

      expect(response.body.error).toBe('Name must be 2-100 characters');
    });

    it('should validate email format', async () => {
      const response = await request(app)
        .post('/api/users')
        .send({
          name: 'Test User',
          email: 'invalid-email',
          password: 'password123',
        })
        .expect(400);

      expect(response.body.error).toBe('Valid email is required');
    });

    it('should validate password length', async () => {
      const response = await request(app)
        .post('/api/users')
        .send({
          name: 'Test User',
          email: 'test@example.com',
          password: '123',
        })
        .expect(400);

      expect(response.body.error).toBe('Password must be at least 6 characters');
    });

    it('should validate phone format', async () => {
      const response = await request(app)
        .post('/api/users')
        .send({
          name: 'Test User',
          email: 'test@example.com',
          password: 'password123',
          phone: 'invalid-phone',
        })
        .expect(400);

      expect(response.body.error).toBe('Invalid phone number format');
    });

    it('should validate profile picture URL format', async () => {
      const response = await request(app)
        .post('/api/users')
        .send({
          name: 'Test User',
          email: 'test@example.com',
          password: 'password123',
          profile_picture_url: 'invalid-url',
        })
        .expect(400);

      expect(response.body.error).toBe('Invalid profile picture URL');
    });

    it('should validate latitude range', async () => {
      const response = await request(app)
        .post('/api/users')
        .send({
          name: 'Test User',
          email: 'test@example.com',
          password: 'password123',
          lat: 100,
          lng: 0,
        })
        .expect(400);

      expect(response.body.error).toBe('Invalid latitude (-90 to 90)');
    });

    it('should validate longitude range', async () => {
      const response = await request(app)
        .post('/api/users')
        .send({
          name: 'Test User',
          email: 'test@example.com',
          password: 'password123',
          lat: 0,
          lng: 200,
        })
        .expect(400);

      expect(response.body.error).toBe('Invalid longitude (-180 to 180)');
    });

    it('should validate balance values', async () => {
      const response = await request(app)
        .post('/api/users')
        .send({
          name: 'Test User',
          email: 'test@example.com',
          password: 'password123',
          pending_balance: -100,
        })
        .expect(400);

      expect(response.body.error).toBe('Invalid pending balance (must be non-negative integer)');
    });

    it('should handle duplicate email', async () => {
      await User.create({
        name: 'Existing User',
        email: 'existing@example.com',
        password: 'password123',
      });

      const response = await request(app)
        .post('/api/users')
        .send({
          name: 'New User',
          email: 'existing@example.com',
          password: 'password123',
        })
        .expect(409);

      expect(response.body.error).toBe('email already exists');
    });

    it('should handle duplicate phone', async () => {
      await User.create({
        name: 'Existing User',
        email: 'existing@example.com',
        password: 'password123',
        phone: '+1234567890',
      });

      const response = await request(app)
        .post('/api/users')
        .send({
          name: 'New User',
          email: 'new@example.com',
          password: 'password123',
          phone: '+1234567890',
        })
        .expect(409);

      expect(response.body.error).toBe('phone already exists');
    });
  });

  describe('PUT /api/users/:id', () => {
    let testUser;
    let authToken;

    beforeEach(async () => {
      testUser = await User.create({
        name: 'Test User',
        email: 'test@example.com',
        password: 'password123',
        city: 'Test City',
        looking_for: 'buy',
      });

      // Mock authentication - in a real scenario, you'd get this from login
      authToken = 'mock-jwt-token';
    });

    it('should update a user', async () => {
      const updates = {
        name: 'Updated Name',
        city: 'Updated City',
        looking_for: 'sale',
        pending_balance: 150,
        available_balance: 250,
      };

      const response = await request(app)
        .put(`/api/users/${testUser.id}`)
        .set('Authorization', `Bearer ${authToken}`)
        .send(updates)
        .expect(200);

      expect(response.body.message).toBe('User updated successfully');
      expect(response.body.user.name).toBe(updates.name);
      expect(response.body.user.city).toBe(updates.city);
      expect(response.body.user.looking_for).toBe(updates.looking_for);
      expect(response.body.user.pending_balance).toBe(updates.pending_balance);
      expect(response.body.user.available_balance).toBe(updates.available_balance);
    });

    it('should update location coordinates', async () => {
      const updates = {
        lat: 41.8781,
        lng: -87.6298,
      };

      const response = await request(app)
        .put(`/api/users/${testUser.id}`)
        .set('Authorization', `Bearer ${authToken}`)
        .send(updates)
        .expect(200);

      expect(response.body.user.lat).toBe(41.8781);
      expect(response.body.user.lng).toBe(-87.6298);
    });

    it('should return 404 for non-existent user', async () => {
      const response = await request(app)
        .put('/api/users/999')
        .set('Authorization', `Bearer ${authToken}`)
        .send({ name: 'Updated' })
        .expect(404);

      expect(response.body.error).toBe('User not found');
    });

    it('should validate update data', async () => {
      const response = await request(app)
        .put(`/api/users/${testUser.id}`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({ name: 'A' })
        .expect(400);

      expect(response.body.error).toBe('Name must be 2-100 characters');
    });

    it('should validate phone format on update', async () => {
      const response = await request(app)
        .put(`/api/users/${testUser.id}`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({ phone: 'invalid-phone' })
        .expect(400);

      expect(response.body.error).toBe('Invalid phone number format');
    });

    it('should validate profile picture URL on update', async () => {
      const response = await request(app)
        .put(`/api/users/${testUser.id}`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({ profile_picture_url: 'invalid-url' })
        .expect(400);

      expect(response.body.error).toBe('Invalid profile picture URL');
    });

    it('should validate latitude on update', async () => {
      const response = await request(app)
        .put(`/api/users/${testUser.id}`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({ lat: 100, lng: 0 })
        .expect(400);

      expect(response.body.error).toBe('Invalid latitude (-90 to 90)');
    });

    it('should validate longitude on update', async () => {
      const response = await request(app)
        .put(`/api/users/${testUser.id}`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({ lat: 0, lng: 200 })
        .expect(400);

      expect(response.body.error).toBe('Invalid longitude (-180 to 180)');
    });

    it('should require both lat and lng when updating location', async () => {
      const response = await request(app)
        .put(`/api/users/${testUser.id}`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({ lat: 40.7128 })
        .expect(400);

      expect(response.body.error).toBe('Both lat and lng must be provided together');
    });

    it('should validate balance values on update', async () => {
      const response = await request(app)
        .put(`/api/users/${testUser.id}`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({ pending_balance: -50 })
        .expect(400);

      expect(response.body.error).toBe('Invalid pending balance (must be non-negative integer)');
    });

    it('should allow setting fields to null', async () => {
      const response = await request(app)
        .put(`/api/users/${testUser.id}`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({ city: null, phone: null, profile_picture_url: null })
        .expect(200);

      expect(response.body.user.city).toBeNull();
      expect(response.body.user.phone).toBeNull();
      expect(response.body.user.profile_picture_url).toBeNull();
    });
  });

  describe('DELETE /api/users/:id', () => {
    let testUser;
    let authToken;

    beforeEach(async () => {
      testUser = await User.create({
        name: 'Test User',
        email: 'test@example.com',
        password: 'password123',
        city: 'Test City',
        looking_for: 'buy',
      });

      // Mock authentication
      authToken = 'mock-jwt-token';
    });

    it('should delete a user', async () => {
      const response = await request(app)
        .delete(`/api/users/${testUser.id}`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.message).toBe('User deleted successfully');

      // Verify deletion
      const deleted = await User.findByPk(testUser.id);
      expect(deleted).toBeNull();
    });

    it('should return 404 for non-existent user', async () => {
      const response = await request(app)
        .delete('/api/users/999')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(404);

      expect(response.body.error).toBe('User not found');
    });

    it('should handle invalid ID', async () => {
      const response = await request(app)
        .delete('/api/users/invalid')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(400);

      expect(response.body.error).toBe('Invalid user ID');
    });
  });
});
