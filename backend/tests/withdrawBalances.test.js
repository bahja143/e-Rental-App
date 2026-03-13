process.env.NODE_ENV = 'test';

const request = require('supertest');
const { sequelize, WithdrawBalance, User } = require('../src/models');

// Mock the auth middleware to bypass authentication for tests
jest.mock('../src/middleware/authMiddleware', () => ({
  authenticateToken: (req, res, next) => {
    // Mock user for authenticated requests
    req.user = { id: 1, role: 'admin' };
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

describe('Withdraw Balances API', () => {
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
      available_balance: 1000,
      pending_balance: 0,
    });

    // Start the server
    server = app.listen(0);
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
    await WithdrawBalance.destroy({ where: {} });
    // Reset SQLite auto-increment sequence
    await sequelize.query('DELETE FROM sqlite_sequence WHERE name = "withdraw_balances"');
  });

  describe('GET /api/withdraw-balances', () => {
    it('should return empty array when no withdraw balances exist', async () => {
      const response = await request(app)
        .get('/api/withdraw-balances')
        .expect(200);

      expect(response.body).toHaveProperty('data');
      expect(response.body).toHaveProperty('pagination');
      expect(response.body.data).toHaveLength(0);
      expect(response.body.pagination.totalItems).toBe(0);
    });

    it('should return withdraw balances with user data', async () => {
      const withdraw = await WithdrawBalance.create({
        user_id: testUser.id,
        amount: 100.50,
        status: 'requested',
        before_balance: 1000.00,
        after_balance: 899.50,
        bank_name: 'Test Bank',
        account_holder_name: 'Test User',
      });

      const response = await request(app)
        .get('/api/withdraw-balances')
        .expect(200);

      expect(response.body.data).toHaveLength(1);
      expect(response.body.data[0].id).toBe(withdraw.id);
      expect(response.body.data[0].amount).toBe(100.50);
      expect(response.body.data[0].status).toBe('requested');
      expect(response.body.data[0].user).toHaveProperty('id', testUser.id);
      expect(response.body.data[0].user).toHaveProperty('name', testUser.name);
      expect(response.body.data[0].user).toHaveProperty('email', testUser.email);
    });

    it('should support pagination', async () => {
      // Create multiple withdraw records
      const withdraws = [];
      for (let i = 1; i <= 25; i++) {
        withdraws.push({
          user_id: testUser.id,
          amount: 10.00 + i,
          status: 'requested',
          before_balance: 1000.00,
          after_balance: 1000.00 - (10.00 + i),
        });
      }
      await WithdrawBalance.bulkCreate(withdraws);

      const response = await request(app)
        .get('/api/withdraw-balances?page=2&limit=10')
        .expect(200);

      expect(response.body.data).toHaveLength(10);
      expect(response.body.pagination.totalItems).toBe(25);
      expect(response.body.pagination.currentPage).toBe(2);
      expect(response.body.pagination.hasNextPage).toBe(true);
    });

    it('should support status filtering', async () => {
      await WithdrawBalance.create({
        user_id: testUser.id,
        amount: 50.00,
        status: 'success',
        before_balance: 1000.00,
        after_balance: 950.00,
      });
      await WithdrawBalance.create({
        user_id: testUser.id,
        amount: 30.00,
        status: 'failed',
        before_balance: 950.00,
        after_balance: 920.00,
      });

      const response = await request(app)
        .get('/api/withdraw-balances?status=success')
        .expect(200);

      expect(response.body.data).toHaveLength(1);
      expect(response.body.data[0].status).toBe('success');
    });

    it('should support user_id filtering', async () => {
      const anotherUser = await User.create({
        name: 'Another User',
        email: 'another@example.com',
        password: 'password123',
      });

      await WithdrawBalance.create({
        user_id: testUser.id,
        amount: 50.00,
        status: 'requested',
        before_balance: 1000.00,
        after_balance: 950.00,
      });
      await WithdrawBalance.create({
        user_id: anotherUser.id,
        amount: 30.00,
        status: 'requested',
        before_balance: 500.00,
        after_balance: 470.00,
      });

      const response = await request(app)
        .get(`/api/withdraw-balances?user_id=${testUser.id}`)
        .expect(200);

      expect(response.body.data).toHaveLength(1);
      expect(response.body.data[0].user_id).toBe(testUser.id);
    });

    it('should support date range filtering', async () => {
      const pastDate = new Date('2023-01-01');
      const futureDate = new Date('2023-12-31');

      await WithdrawBalance.create({
        user_id: testUser.id,
        amount: 50.00,
        status: 'requested',
        date: new Date('2023-06-15'),
        before_balance: 1000.00,
        after_balance: 950.00,
      });

      const response = await request(app)
        .get(`/api/withdraw-balances?start_date=${pastDate.toISOString()}&end_date=${futureDate.toISOString()}`)
        .expect(200);

      expect(response.body.data).toHaveLength(1);
    });

    it('should handle invalid page number', async () => {
      const response = await request(app)
        .get('/api/withdraw-balances?page=invalid')
        .expect(400);

      expect(response.body.error).toBe('Invalid page number');
    });

    it('should handle invalid limit', async () => {
      const response = await request(app)
        .get('/api/withdraw-balances?limit=200')
        .expect(400);

      expect(response.body.error).toBe('Invalid limit (1-100)');
    });
  });

  describe('GET /api/withdraw-balances/:id', () => {
    it('should return a withdraw balance by ID with user data', async () => {
      const withdraw = await WithdrawBalance.create({
        user_id: testUser.id,
        amount: 75.25,
        status: 'requested',
        before_balance: 1000.00,
        after_balance: 924.75,
        bank_name: 'Test Bank',
        account_holder_name: 'Test User',
      });

      const response = await request(app)
        .get(`/api/withdraw-balances/${withdraw.id}`)
        .expect(200);

      expect(response.body.id).toBe(withdraw.id);
      expect(response.body.amount).toBe(75.25);
      expect(response.body.status).toBe('requested');
      expect(response.body.user).toHaveProperty('id', testUser.id);
      expect(response.body.user).toHaveProperty('name', testUser.name);
    });

    it('should return 404 for non-existent withdraw balance', async () => {
      const response = await request(app)
        .get('/api/withdraw-balances/999')
        .expect(404);

      expect(response.body.error).toBe('Withdraw balance not found');
    });

    it('should handle invalid ID', async () => {
      const response = await request(app)
        .get('/api/withdraw-balances/invalid')
        .expect(400);

      expect(response.body.error).toBe('Invalid withdraw balance ID');
    });
  });

  describe('POST /api/withdraw-balances', () => {
    it('should create a new withdraw balance', async () => {
      const newWithdraw = {
        user_id: testUser.id,
        amount: 200.00,
        status: 'requested',
        before_balance: 1000.00,
        after_balance: 800.00,
        bank_name: 'New Bank',
        branch: 'Main Branch',
        bank_account: '123456789',
        account_holder_name: 'Test User',
        swift: 'TESTSWFT',
      };

      const response = await request(app)
        .post('/api/withdraw-balances')
        .send(newWithdraw)
        .expect(201);

      expect(response.body.message).toBe('Withdraw balance created successfully');
      expect(response.body.withdrawBalance.amount).toBe(200.00);
      expect(response.body.withdrawBalance.status).toBe('requested');
      expect(response.body.withdrawBalance.user).toHaveProperty('id', testUser.id);
    });

    it('should create withdraw balance with minimal required fields', async () => {
      const minimalWithdraw = {
        user_id: testUser.id,
        amount: 50.00,
        before_balance: 1000.00,
        after_balance: 950.00,
      };

      const response = await request(app)
        .post('/api/withdraw-balances')
        .send(minimalWithdraw)
        .expect(201);

      expect(response.body.withdrawBalance.amount).toBe(50.00);
      expect(response.body.withdrawBalance.status).toBe('requested'); // default value
    });

    it('should validate required fields', async () => {
      const response = await request(app)
        .post('/api/withdraw-balances')
        .send({})
        .expect(400);

      expect(response.body.error).toBe('Valid user ID is required');
    });

    it('should validate amount', async () => {
      const response = await request(app)
        .post('/api/withdraw-balances')
        .send({
          user_id: testUser.id,
          amount: -50,
          before_balance: 1000.00,
          after_balance: 950.00,
        })
        .expect(400);

      expect(response.body.error).toBe('Amount must be a positive number');
    });

    it('should validate status enum', async () => {
      const response = await request(app)
        .post('/api/withdraw-balances')
        .send({
          user_id: testUser.id,
          amount: 50.00,
          status: 'invalid_status',
          before_balance: 1000.00,
          after_balance: 950.00,
        })
        .expect(400);

      expect(response.body.error).toBe('Invalid status value');
    });

    it('should validate balance values', async () => {
      const response = await request(app)
        .post('/api/withdraw-balances')
        .send({
          user_id: testUser.id,
          amount: 50.00,
          before_balance: -100,
          after_balance: 950.00,
        })
        .expect(400);

      expect(response.body.error).toBe('Invalid before_balance (must be non-negative number)');
    });

    it('should handle non-existent user', async () => {
      const response = await request(app)
        .post('/api/withdraw-balances')
        .send({
          user_id: 999,
          amount: 50.00,
          before_balance: 1000.00,
          after_balance: 950.00,
        })
        .expect(404);

      expect(response.body.error).toBe('User not found');
    });
  });

  describe('PUT /api/withdraw-balances/:id', () => {
    let testWithdraw;

    beforeEach(async () => {
      testWithdraw = await WithdrawBalance.create({
        user_id: testUser.id,
        amount: 100.00,
        status: 'requested',
        before_balance: 1000.00,
        after_balance: 900.00,
        bank_name: 'Test Bank',
      });
    });

    it('should update a withdraw balance', async () => {
      const updates = {
        status: 'success',
        bank_name: 'Updated Bank',
        account_holder_name: 'Updated Name',
      };

      const response = await request(app)
        .put(`/api/withdraw-balances/${testWithdraw.id}`)
        .send(updates)
        .expect(200);

      expect(response.body.message).toBe('Withdraw balance updated successfully');
      expect(response.body.withdrawBalance.status).toBe('success');
      expect(response.body.withdrawBalance.bank_name).toBe('Updated Bank');
      expect(response.body.withdrawBalance.account_holder_name).toBe('Updated Name');
    });

    it('should validate status on update', async () => {
      const response = await request(app)
        .put(`/api/withdraw-balances/${testWithdraw.id}`)
        .send({ status: 'invalid' })
        .expect(400);

      expect(response.body.error).toBe('Invalid status value');
    });

    it('should validate balance values on update', async () => {
      const response = await request(app)
        .put(`/api/withdraw-balances/${testWithdraw.id}`)
        .send({ before_balance: -50 })
        .expect(400);

      expect(response.body.error).toBe('Invalid before_balance (must be non-negative number)');
    });

    it('should return 404 for non-existent withdraw balance', async () => {
      const response = await request(app)
        .put('/api/withdraw-balances/999')
        .send({ status: 'success' })
        .expect(404);

      expect(response.body.error).toBe('Withdraw balance not found');
    });

    it('should allow setting optional fields to null', async () => {
      const response = await request(app)
        .put(`/api/withdraw-balances/${testWithdraw.id}`)
        .send({
          bank_name: null,
          branch: null,
          swift: null,
        })
        .expect(200);

      expect(response.body.withdrawBalance.bank_name).toBeNull();
      expect(response.body.withdrawBalance.branch).toBeNull();
      expect(response.body.withdrawBalance.swift).toBeNull();
    });
  });

  describe('DELETE /api/withdraw-balances/:id', () => {
    let testWithdraw;

    beforeEach(async () => {
      testWithdraw = await WithdrawBalance.create({
        user_id: testUser.id,
        amount: 75.00,
        status: 'requested',
        before_balance: 1000.00,
        after_balance: 925.00,
      });
    });

    it('should delete a withdraw balance', async () => {
      const response = await request(app)
        .delete(`/api/withdraw-balances/${testWithdraw.id}`)
        .expect(200);

      expect(response.body.message).toBe('Withdraw balance deleted successfully');

      // Verify deletion
      const deleted = await WithdrawBalance.findByPk(testWithdraw.id);
      expect(deleted).toBeNull();
    });

    it('should return 404 for non-existent withdraw balance', async () => {
      const response = await request(app)
        .delete('/api/withdraw-balances/999')
        .expect(404);

      expect(response.body.error).toBe('Withdraw balance not found');
    });

    it('should handle invalid ID', async () => {
      const response = await request(app)
        .delete('/api/withdraw-balances/invalid')
        .expect(400);

      expect(response.body.error).toBe('Invalid withdraw balance ID');
    });
  });
});
