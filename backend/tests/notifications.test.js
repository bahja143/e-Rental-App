process.env.NODE_ENV = 'test';

const request = require('supertest');
const { sequelize, Notification, User } = require('../src/models');

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

describe('Notifications API', () => {
  let app;
  let server;
  let testUser;

  beforeAll(async () => {
    // Import app after mocking
    app = require('../src/app');

    // Sync the in-memory database
    await sequelize.sync({ force: true });

    // Create test user
    testUser = await User.create({
      name: 'Test User',
      email: 'test@example.com',
      password: 'password123',
      phone: '+252123456789',
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
    await Notification.destroy({ where: {} });
    // Reset SQLite auto-increment sequence
    await sequelize.query('DELETE FROM sqlite_sequence WHERE name = "notifications"');
  });

  describe('GET /api/notifications', () => {
    it('should return empty array when no notifications exist', async () => {
      const response = await request(app)
        .get('/api/notifications')
        .expect(200);

      expect(response.body).toHaveProperty('data');
      expect(response.body).toHaveProperty('pagination');
      expect(response.body.data).toHaveLength(0);
      expect(response.body.pagination.totalItems).toBe(0);
    });

    it('should return notifications with default pagination', async () => {
      // Create test notifications
      const notifications = [];
      for (let i = 1; i <= 15; i++) {
        notifications.push({
          user_id: testUser.id,
          type: `type${i}`,
          title: `Notification Title ${i}`,
          message: `This is notification message ${i}`,
          data: { key: `value${i}` },
          is_read: i % 2 === 0,
        });
      }
      await Notification.bulkCreate(notifications);

      const response = await request(app)
        .get('/api/notifications')
        .expect(200);

      expect(response.body.data).toHaveLength(10); // Default limit
      expect(response.body.pagination.totalItems).toBe(15);
      expect(response.body.pagination.totalPages).toBe(2);
      expect(response.body.pagination.currentPage).toBe(1);
      expect(response.body.pagination.hasNextPage).toBe(true);
      expect(response.body.pagination.hasPrevPage).toBe(false);
    });

    it('should filter notifications by user_id', async () => {
      const user2 = await User.create({
        name: 'User 2',
        email: 'user2@example.com',
        password: 'password123',
        phone: '+252987654321',
      });

      await Notification.create({
        user_id: testUser.id,
        type: 'booking',
        title: 'Booking Notification',
        message: 'Your booking is confirmed',
      });

      await Notification.create({
        user_id: user2.id,
        type: 'status_change',
        title: 'Status Change',
        message: 'Status updated',
      });

      const response = await request(app)
        .get(`/api/notifications?user_id=${testUser.id}`)
        .expect(200);

      expect(response.body.data).toHaveLength(1);
      expect(response.body.data[0].type).toBe('booking');
    });

    it('should filter notifications by type', async () => {
      await Notification.create({
        user_id: testUser.id,
        type: 'booking',
        title: 'Booking Notification',
        message: 'Your booking is confirmed',
      });

      await Notification.create({
        user_id: testUser.id,
        type: 'status_change',
        title: 'Status Change',
        message: 'Status updated',
      });

      const response = await request(app)
        .get('/api/notifications?type=booking')
        .expect(200);

      expect(response.body.data).toHaveLength(1);
      expect(response.body.data[0].type).toBe('booking');
    });

    it('should filter notifications by is_read status', async () => {
      await Notification.create({
        user_id: testUser.id,
        type: 'booking',
        title: 'Read Notification',
        message: 'Read message',
        is_read: true,
      });

      await Notification.create({
        user_id: testUser.id,
        type: 'status_change',
        title: 'Unread Notification',
        message: 'Unread message',
        is_read: false,
      });

      const response = await request(app)
        .get('/api/notifications?is_read=false')
        .expect(200);

      expect(response.body.data).toHaveLength(1);
      expect(response.body.data[0].is_read).toBe(false);
    });

    it('should search notifications by title and message', async () => {
      await Notification.create({
        user_id: testUser.id,
        type: 'booking',
        title: 'Booking Confirmed',
        message: 'Your booking is confirmed',
      });

      await Notification.create({
        user_id: testUser.id,
        type: 'status_change',
        title: 'Status Update',
        message: 'Status has changed',
      });

      const response = await request(app)
        .get('/api/notifications?search=booking')
        .expect(200);

      expect(response.body.data).toHaveLength(1);
      expect(response.body.data[0].title).toBe('Booking Confirmed');
    });

    it('should sort notifications by createdAt DESC', async () => {
      const notification1 = await Notification.create({
        user_id: testUser.id,
        type: 'booking',
        title: 'First Notification',
        message: 'First message',
        createdAt: new Date('2023-01-01'),
      });

      const notification2 = await Notification.create({
        user_id: testUser.id,
        type: 'status_change',
        title: 'Second Notification',
        message: 'Second message',
        createdAt: new Date('2023-01-02'),
      });

      const response = await request(app)
        .get('/api/notifications')
        .expect(200);

      expect(response.body.data[0].id).toBe(notification2.id);
      expect(response.body.data[1].id).toBe(notification1.id);
    });
  });

  describe('GET /api/notifications/:id', () => {
    let testNotification;

    beforeEach(async () => {
      testNotification = await Notification.create({
        user_id: testUser.id,
        type: 'booking',
        title: 'Test Notification',
        message: 'Test message',
        data: { test: 'data' },
      });
    });

    it('should return a notification', async () => {
      const response = await request(app)
        .get(`/api/notifications/${testNotification.id}`)
        .expect(200);

      expect(response.body.user_id).toBe(testUser.id);
      expect(response.body.type).toBe('booking');
      expect(response.body.title).toBe('Test Notification');
      expect(response.body.message).toBe('Test message');
      expect(response.body.data).toEqual({ test: 'data' });
      expect(response.body.is_read).toBe(false);
      expect(response.body.user).toBeDefined();
      expect(response.body.user.name).toBe('Test User');
    });

    it('should return 404 for non-existent notification', async () => {
      const response = await request(app)
        .get('/api/notifications/999')
        .expect(404);

      expect(response.body.error).toBe('Notification not found');
    });

    it('should handle invalid ID', async () => {
      const response = await request(app)
        .get('/api/notifications/invalid')
        .expect(400);

      expect(response.body.error).toBe('Invalid notification ID');
    });
  });

  describe('POST /api/notifications', () => {
    it('should create a new notification', async () => {
      const notificationData = {
        user_id: testUser.id,
        type: 'booking',
        title: 'New Booking',
        message: 'Your booking has been created',
        data: { booking_id: 123 },
      };

      const response = await request(app)
        .post('/api/notifications')
        .send(notificationData)
        .expect(201);

      expect(response.body.message).toBe('Notification created successfully');
      expect(response.body.notification).toBeDefined();
      expect(response.body.notification.type).toBe('booking');
      expect(response.body.notification.title).toBe('New Booking');
      expect(response.body.notification.message).toBe('Your booking has been created');
      expect(response.body.notification.data).toEqual({ booking_id: 123 });
      expect(response.body.notification.is_read).toBe(false);
      expect(response.body.notification.user).toBeDefined();
    });

    it('should return 404 for non-existent user', async () => {
      const response = await request(app)
        .post('/api/notifications')
        .send({
          user_id: 999,
          type: 'booking',
          title: 'Test',
          message: 'Test message',
        })
        .expect(404);

      expect(response.body.error).toBe('User not found');
    });

    it('should validate required fields', async () => {
      const response = await request(app)
        .post('/api/notifications')
        .send({})
        .expect(400);

      expect(response.body.error).toBe('Invalid user_id');
    });

    it('should validate type length', async () => {
      const response = await request(app)
        .post('/api/notifications')
        .send({
          user_id: testUser.id,
          type: 'a'.repeat(256), // Too long
          title: 'Test',
          message: 'Test message',
        })
        .expect(400);

      expect(response.body.error).toBe('Type is required and must be 1-255 characters');
    });

    it('should validate title length', async () => {
      const response = await request(app)
        .post('/api/notifications')
        .send({
          user_id: testUser.id,
          type: 'booking',
          title: 'a'.repeat(256), // Too long
          message: 'Test message',
        })
        .expect(400);

      expect(response.body.error).toBe('Title is required and must be 1-255 characters');
    });

    it('should validate message is not empty', async () => {
      const response = await request(app)
        .post('/api/notifications')
        .send({
          user_id: testUser.id,
          type: 'booking',
          title: 'Test Title',
          message: '',
        })
        .expect(400);

      expect(response.body.error).toBe('Message is required');
    });
  });

  describe('PUT /api/notifications/:id', () => {
    let testNotification;

    beforeEach(async () => {
      testNotification = await Notification.create({
        user_id: testUser.id,
        type: 'booking',
        title: 'Original Title',
        message: 'Original message',
        is_read: false,
      });
    });

    it('should update notification fields', async () => {
      const updateData = {
        type: 'status_change',
        title: 'Updated Title',
        message: 'Updated message',
        is_read: true,
        data: { updated: true },
      };

      const response = await request(app)
        .put(`/api/notifications/${testNotification.id}`)
        .send(updateData)
        .expect(200);

      expect(response.body.message).toBe('Notification updated successfully');
      expect(response.body.notification.type).toBe('status_change');
      expect(response.body.notification.title).toBe('Updated Title');
      expect(response.body.notification.message).toBe('Updated message');
      expect(response.body.notification.is_read).toBe(true);
      expect(response.body.notification.data).toEqual({ updated: true });
    });

    it('should update only provided fields', async () => {
      const response = await request(app)
        .put(`/api/notifications/${testNotification.id}`)
        .send({ is_read: true })
        .expect(200);

      expect(response.body.notification.is_read).toBe(true);
      expect(response.body.notification.type).toBe('booking'); // Unchanged
      expect(response.body.notification.title).toBe('Original Title'); // Unchanged
    });

    it('should return 404 for non-existent notification', async () => {
      const response = await request(app)
        .put('/api/notifications/999')
        .send({ is_read: true })
        .expect(404);

      expect(response.body.error).toBe('Notification not found');
    });

    it('should validate is_read boolean', async () => {
      const response = await request(app)
        .put(`/api/notifications/${testNotification.id}`)
        .send({ is_read: 'not_boolean' })
        .expect(400);

      expect(response.body.error).toBe('is_read must be a boolean');
    });

    it('should validate type length on update', async () => {
      const response = await request(app)
        .put(`/api/notifications/${testNotification.id}`)
        .send({ type: 'a'.repeat(256) })
        .expect(400);

      expect(response.body.error).toBe('Type must be 1-255 characters');
    });

    it('should handle no fields to update', async () => {
      const response = await request(app)
        .put(`/api/notifications/${testNotification.id}`)
        .send({})
        .expect(400);

      expect(response.body.error).toBe('No valid fields to update');
    });
  });

  describe('DELETE /api/notifications/:id', () => {
    let testNotification;

    beforeEach(async () => {
      testNotification = await Notification.create({
        user_id: testUser.id,
        type: 'booking',
        title: 'Test Notification',
        message: 'Test message',
      });
    });

    it('should delete a notification', async () => {
      const response = await request(app)
        .delete(`/api/notifications/${testNotification.id}`)
        .expect(200);

      expect(response.body.message).toBe('Notification deleted successfully');

      // Verify deletion
      const deleted = await Notification.findByPk(testNotification.id);
      expect(deleted).toBeNull();
    });

    it('should return 404 for non-existent notification', async () => {
      const response = await request(app)
        .delete('/api/notifications/999')
        .expect(404);

      expect(response.body.error).toBe('Notification not found');
    });

    it('should handle invalid ID', async () => {
      const response = await request(app)
        .delete('/api/notifications/invalid')
        .expect(400);

      expect(response.body.error).toBe('Invalid notification ID');
    });
  });
});
