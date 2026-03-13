process.env.NODE_ENV = 'test';

const request = require('supertest');
const { sequelize, UserDevice, User } = require('../src/models');

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

describe('UserDevices API', () => {
  let app;
  let server;
  let testUser;

  beforeAll(async () => {
    // Import app after mocking
    app = require('../src/app');

    // Sync the in-memory database
    await sequelize.sync({ force: true });

    // Create a test user
    testUser = await User.create({
      name: 'Test User',
      email: 'test@example.com',
      password: 'password123',
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
    // Clear the table before each test
    await UserDevice.destroy({ where: {} });
    // Reset SQLite auto-increment sequence
    await sequelize.query('DELETE FROM sqlite_sequence WHERE name = "user_devices"');
  });

  describe('GET /api/user-devices', () => {
    it('should return empty array when no user devices exist', async () => {
      const response = await request(app)
        .get('/api/user-devices')
        .expect(200);

      expect(response.body).toHaveProperty('data');
      expect(response.body).toHaveProperty('pagination');
      expect(response.body.data).toHaveLength(0);
      expect(response.body.pagination.totalItems).toBe(0);
    });

    it('should return user devices with default pagination', async () => {
      // Create test user devices
      const devices = [];
      for (let i = 1; i <= 15; i++) {
        devices.push({
          user_id: testUser.id,
          device_type: `android${i}`,
          fcm_token: `fcm_token_${i}_abcdefghijklmnopqrstuvwxyz123456789`,
        });
      }
      await UserDevice.bulkCreate(devices);

      const response = await request(app)
        .get('/api/user-devices')
        .expect(200);

      expect(response.body.data).toHaveLength(10); // Default limit
      expect(response.body.pagination.totalItems).toBe(15);
      expect(response.body.pagination.totalPages).toBe(2);
      expect(response.body.data[0]).toHaveProperty('user');
      expect(response.body.data[0].user).toHaveProperty('name', 'Test User');
    });

    it('should filter user devices by user_id', async () => {
      await UserDevice.create({
        user_id: testUser.id,
        device_type: 'android',
        fcm_token: 'fcm_token_123',
      });

      const response = await request(app)
        .get(`/api/user-devices?user_id=${testUser.id}`)
        .expect(200);

      expect(response.body.data).toHaveLength(1);
      expect(response.body.data[0].user_id).toBe(testUser.id);
    });

    it('should filter user devices by device_type', async () => {
      await UserDevice.create({
        user_id: testUser.id,
        device_type: 'ios',
        fcm_token: 'fcm_token_ios',
      });

      const response = await request(app)
        .get('/api/user-devices?device_type=ios')
        .expect(200);

      expect(response.body.data).toHaveLength(1);
      expect(response.body.data[0].device_type).toBe('ios');
    });

    it('should search user devices by fcm_token', async () => {
      await UserDevice.create({
        user_id: testUser.id,
        device_type: 'android',
        fcm_token: 'unique_fcm_token_123',
      });

      const response = await request(app)
        .get('/api/user-devices?search=unique_fcm_token_123')
        .expect(200);

      expect(response.body.data).toHaveLength(1);
      expect(response.body.data[0].fcm_token).toBe('unique_fcm_token_123');
    });

    it('should sort user devices by createdAt DESC', async () => {
      const device1 = await UserDevice.create({
        user_id: testUser.id,
        device_type: 'android1',
        fcm_token: 'token1',
      });

      // Small delay to ensure different timestamps
      await new Promise(resolve => setTimeout(resolve, 10));

      const device2 = await UserDevice.create({
        user_id: testUser.id,
        device_type: 'android2',
        fcm_token: 'token2',
      });

      const response = await request(app)
        .get('/api/user-devices')
        .expect(200);

      expect(response.body.data).toHaveLength(2);
      expect(response.body.data[0].id).toBe(device2.id); // Most recent first
      expect(response.body.data[1].id).toBe(device1.id);
    });
  });

  describe('GET /api/user-devices/:id', () => {
    let testDevice;

    beforeEach(async () => {
      testDevice = await UserDevice.create({
        user_id: testUser.id,
        device_type: 'android',
        fcm_token: 'test_fcm_token',
      });
    });

    it('should return a user device', async () => {
      const response = await request(app)
        .get(`/api/user-devices/${testDevice.id}`)
        .expect(200);

      expect(response.body.id).toBe(testDevice.id);
      expect(response.body.device_type).toBe('android');
      expect(response.body.fcm_token).toBe('test_fcm_token');
      expect(response.body.user).toHaveProperty('name', 'Test User');
    });

    it('should return 404 for non-existent user device', async () => {
      const response = await request(app)
        .get('/api/user-devices/999')
        .expect(404);

      expect(response.body.error).toBe('User device not found');
    });

    it('should handle invalid ID', async () => {
      const response = await request(app)
        .get('/api/user-devices/invalid')
        .expect(400);

      expect(response.body.error).toBe('Invalid device ID');
    });
  });

  describe('POST /api/user-devices', () => {
    it('should create a new user device', async () => {
      const response = await request(app)
        .post('/api/user-devices')
        .send({
          user_id: testUser.id,
          device_type: 'ios',
          fcm_token: 'new_fcm_token_12345',
        })
        .expect(201);

      expect(response.body.message).toBe('User device created successfully');
      expect(response.body.userDevice).toHaveProperty('id');
      expect(response.body.userDevice.device_type).toBe('ios');
      expect(response.body.userDevice.fcm_token).toBe('new_fcm_token_12345');
      expect(response.body.userDevice.user).toHaveProperty('name', 'Test User');
    });

    it('should return 404 for non-existent user', async () => {
      const response = await request(app)
        .post('/api/user-devices')
        .send({
          user_id: 999,
          device_type: 'android',
          fcm_token: 'fcm_token',
        })
        .expect(404);

      expect(response.body.error).toBe('User not found');
    });

    it('should validate required fields', async () => {
      const response = await request(app)
        .post('/api/user-devices')
        .send({})
        .expect(400);

      expect(response.body.error).toBe('user_id, device_type, and fcm_token are required');
    });

    it('should validate device_type length', async () => {
      const response = await request(app)
        .post('/api/user-devices')
        .send({
          user_id: testUser.id,
          device_type: 'a'.repeat(21), // Too long
          fcm_token: 'fcm_token',
        })
        .expect(400);

      expect(response.body.error).toBe('device_type must be a string between 1-20 characters');
    });

    it('should validate fcm_token is not empty', async () => {
      const response = await request(app)
        .post('/api/user-devices')
        .send({
          user_id: testUser.id,
          device_type: 'android',
          fcm_token: '',
        })
        .expect(400);

      expect(response.body.error).toBe('user_id, device_type, and fcm_token are required');
    });
  });

  describe('PUT /api/user-devices/:id', () => {
    let testDevice;

    beforeEach(async () => {
      testDevice = await UserDevice.create({
        user_id: testUser.id,
        device_type: 'android',
        fcm_token: 'original_token',
      });
    });

    it('should update user device fields', async () => {
      const response = await request(app)
        .put(`/api/user-devices/${testDevice.id}`)
        .send({
          device_type: 'ios',
          fcm_token: 'updated_token',
        })
        .expect(200);

      expect(response.body.message).toBe('User device updated successfully');
      expect(response.body.userDevice.device_type).toBe('ios');
      expect(response.body.userDevice.fcm_token).toBe('updated_token');
    });

    it('should update only provided fields', async () => {
      const response = await request(app)
        .put(`/api/user-devices/${testDevice.id}`)
        .send({
          fcm_token: 'only_token_updated',
        })
        .expect(200);

      expect(response.body.userDevice.device_type).toBe('android'); // Unchanged
      expect(response.body.userDevice.fcm_token).toBe('only_token_updated');
    });

    it('should return 404 for non-existent user device', async () => {
      const response = await request(app)
        .put('/api/user-devices/999')
        .send({ device_type: 'ios' })
        .expect(404);

      expect(response.body.error).toBe('User device not found');
    });

    it('should validate device_type length on update', async () => {
      const response = await request(app)
        .put(`/api/user-devices/${testDevice.id}`)
        .send({ device_type: 'a'.repeat(21) })
        .expect(400);

      expect(response.body.error).toBe('device_type must be a string between 1-20 characters');
    });

    it('should handle no fields to update', async () => {
      const response = await request(app)
        .put(`/api/user-devices/${testDevice.id}`)
        .send({})
        .expect(400);

      expect(response.body.error).toBe('No valid fields to update');
    });
  });

  describe('DELETE /api/user-devices/:id', () => {
    let testDevice;

    beforeEach(async () => {
      testDevice = await UserDevice.create({
        user_id: testUser.id,
        device_type: 'android',
        fcm_token: 'test_token',
      });
    });

    it('should delete a user device', async () => {
      const response = await request(app)
        .delete(`/api/user-devices/${testDevice.id}`)
        .expect(200);

      expect(response.body.message).toBe('User device deleted successfully');

      // Verify deletion
      const deleted = await UserDevice.findByPk(testDevice.id);
      expect(deleted).toBeNull();
    });

    it('should return 404 for non-existent user device', async () => {
      const response = await request(app)
        .delete('/api/user-devices/999')
        .expect(404);

      expect(response.body.error).toBe('User device not found');
    });

    it('should handle invalid ID', async () => {
      const response = await request(app)
        .delete('/api/user-devices/invalid')
        .expect(400);

      expect(response.body.error).toBe('Invalid device ID');
    });
  });
});
