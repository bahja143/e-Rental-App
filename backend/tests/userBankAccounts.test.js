process.env.NODE_ENV = 'test';

const request = require('supertest');
const { User, UserBankAccount, sequelize } = require('../src/models');

jest.mock('../src/middleware/authMiddleware', () => ({
  authenticateToken: (req, res, next) => {
    req.user = { id: 1, role: 'admin' };
    next();
  },
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

jest.setTimeout(20000);

describe('User Bank Accounts API', () => {
  let app;
  let testUser;
  let testUserBankAccount;

  beforeAll(async () => {
    app = require('../src/app');

    // Sync database
    await sequelize.sync({ force: true });

    // Create test user
    testUser = await User.create({
      name: 'Test User',
      email: 'test@example.com',
      phone: '+1234567890',
      password: 'password123',
      city: 'Test City',
      looking_for: 'buy',
      user_type: 'buyer',
    });
  });

  afterAll(async () => {
    await sequelize.close();
    await mongoose.connection.close();
  });

  describe('POST /api/user-bank-accounts', () => {
    it('should create a new user bank account', async () => {
      const response = await request(app)
        .post('/api/user-bank-accounts')
        .send({
          user_id: testUser.id,
          bank_name: 'Test Bank',
          branch: 'Main Branch',
          account_no: '123456789012',
          account_holder_name: 'Test User',
          swift_code: 'TESTUS33',
          is_default: true,
        });

      expect(response.status).toBe(201);
      expect(response.body.message).toBe('User bank account created successfully');
      expect(response.body.data).toHaveProperty('id');
      expect(response.body.data.bank_name).toBe('Test Bank');
      expect(response.body.data.account_no).toBe('123456789012');
      expect(response.body.data.is_default).toBe(true);

      testUserBankAccount = response.body.data;
    });

    it('should return 409 for duplicate account number', async () => {
      const response = await request(app)
        .post('/api/user-bank-accounts')
        .send({
          user_id: testUser.id,
          bank_name: 'Another Bank',
          branch: 'Another Branch',
          account_no: '123456789012', // Same account number
          account_holder_name: 'Test User',
        });

      expect(response.status).toBe(409);
      expect(response.body.error).toBe('Account number already exists');
    });

    it('should return 400 for invalid user_id', async () => {
      const response = await request(app)
        .post('/api/user-bank-accounts')
        .send({
          user_id: 'invalid',
          bank_name: 'Test Bank',
          branch: 'Main Branch',
          account_no: '987654321098',
          account_holder_name: 'Test User',
        });

      expect(response.status).toBe(400);
      expect(response.body.error).toBe('Valid user_id is required');
    });

    it('should return 400 for invalid bank_name', async () => {
      const response = await request(app)
        .post('/api/user-bank-accounts')
        .send({
          user_id: testUser.id,
          bank_name: 'A', // Too short
          branch: 'Main Branch',
          account_no: '987654321098',
          account_holder_name: 'Test User',
        });

      expect(response.status).toBe(400);
      expect(response.body.error).toBe('Valid bank_name is required (2-100 characters)');
    });

    it('should return 400 for invalid account_no', async () => {
      const response = await request(app)
        .post('/api/user-bank-accounts')
        .send({
          user_id: testUser.id,
          bank_name: 'Test Bank',
          branch: 'Main Branch',
          account_no: '12', // Too short
          account_holder_name: 'Test User',
        });

      expect(response.status).toBe(400);
      expect(response.body.error).toBe('Valid account_no is required (3-120 characters, letters, numbers, @ . _ - only)');
    });

    it('should return 400 for invalid SWIFT code', async () => {
      const response = await request(app)
        .post('/api/user-bank-accounts')
        .send({
          user_id: testUser.id,
          bank_name: 'Test Bank',
          branch: 'Main Branch',
          account_no: '987654321098',
          account_holder_name: 'Test User',
          swift_code: 'INVALID',
        });

      expect(response.status).toBe(400);
      expect(response.body.error).toBe('Invalid SWIFT code format');
    });

    it('should return 404 for non-existent user', async () => {
      const response = await request(app)
        .post('/api/user-bank-accounts')
        .send({
          user_id: 999,
          bank_name: 'Test Bank',
          branch: 'Main Branch',
          account_no: '987654321098',
          account_holder_name: 'Test User',
        });

      expect(response.status).toBe(404);
      expect(response.body.error).toBe('User not found');
    });
  });

  describe('GET /api/user-bank-accounts', () => {
    beforeAll(async () => {
      // Create additional test data
      await UserBankAccount.create({
        user_id: testUser.id,
        bank_name: 'Second Bank',
        branch: 'Second Branch',
        account_no: '987654321098',
        account_holder_name: 'Test User',
        is_default: false,
      });
    });

    it('should get all user bank accounts with pagination', async () => {
      const response = await request(app)
        .get('/api/user-bank-accounts')
        .query({ page: 1, limit: 10 });

      expect(response.status).toBe(200);
      expect(response.body.data).toBeInstanceOf(Array);
      expect(response.body.data.length).toBeGreaterThan(0);
      expect(response.body.pagination).toHaveProperty('currentPage', 1);
      expect(response.body.pagination).toHaveProperty('totalItems');
      expect(response.body.pagination).toHaveProperty('totalPages');
    });

    it('should filter by user_id', async () => {
      const response = await request(app)
        .get('/api/user-bank-accounts')
        .query({ user_id: testUser.id });

      expect(response.status).toBe(200);
      expect(response.body.data).toBeInstanceOf(Array);
      expect(response.body.data.every(account => account.user_id === testUser.id)).toBe(true);
    });

    it('should filter by bank_name', async () => {
      const response = await request(app)
        .get('/api/user-bank-accounts')
        .query({ bank_name: 'Test Bank' });

      expect(response.status).toBe(200);
      expect(response.body.data).toBeInstanceOf(Array);
      expect(response.body.data.some(account => account.bank_name === 'Test Bank')).toBe(true);
    });

    it('should filter by is_default', async () => {
      const response = await request(app)
        .get('/api/user-bank-accounts')
        .query({ is_default: 'true' });

      expect(response.status).toBe(200);
      expect(response.body.data).toBeInstanceOf(Array);
      expect(response.body.data.every(account => account.is_default === true)).toBe(true);
    });
  });

  describe('GET /api/user-bank-accounts/:id', () => {
    it('should get single user bank account by ID', async () => {
      const response = await request(app)
        .get(`/api/user-bank-accounts/${testUserBankAccount.id}`);

      expect(response.status).toBe(200);
      expect(response.body.id).toBe(testUserBankAccount.id);
      expect(response.body.bank_name).toBe('Test Bank');
      expect(response.body.account_no).toBe('123456789012');
    });

    it('should return 404 for non-existent account', async () => {
      const response = await request(app)
        .get('/api/user-bank-accounts/999');

      expect(response.status).toBe(404);
      expect(response.body.error).toBe('User bank account not found');
    });

    it('should return 400 for invalid ID', async () => {
      const response = await request(app)
        .get('/api/user-bank-accounts/invalid');

      expect(response.status).toBe(400);
      expect(response.body.error).toBe('Invalid user bank account ID');
    });
  });

  describe('PUT /api/user-bank-accounts/:id', () => {
    it('should update user bank account', async () => {
      const response = await request(app)
        .put(`/api/user-bank-accounts/${testUserBankAccount.id}`)
        .send({
          bank_name: 'Updated Bank Name',
          branch: 'Updated Branch',
        });

      expect(response.status).toBe(200);
      expect(response.body.message).toBe('User bank account updated successfully');
      expect(response.body.data.bank_name).toBe('Updated Bank Name');
      expect(response.body.data.branch).toBe('Updated Branch');
    });

    it('should return 409 when updating to existing account number', async () => {
      const response = await request(app)
        .put(`/api/user-bank-accounts/${testUserBankAccount.id}`)
        .send({
          account_no: '987654321098', // Existing account number
        });

      expect(response.status).toBe(409);
      expect(response.body.error).toBe('Account number already exists');
    });

    it('should return 404 for non-existent account', async () => {
      const response = await request(app)
        .put('/api/user-bank-accounts/999')
        .send({
          bank_name: 'Updated Bank',
        });

      expect(response.status).toBe(404);
      expect(response.body.error).toBe('User bank account not found');
    });

    it('should return 400 for invalid update data', async () => {
      const response = await request(app)
        .put(`/api/user-bank-accounts/${testUserBankAccount.id}`)
        .send({
          bank_name: '', // Invalid empty name
        });

      expect(response.status).toBe(400);
      expect(response.body.error).toBe('Invalid bank_name (2-100 characters)');
    });
  });

  describe('DELETE /api/user-bank-accounts/:id', () => {
    it('should delete user bank account', async () => {
      const response = await request(app)
        .delete(`/api/user-bank-accounts/${testUserBankAccount.id}`);

      expect(response.status).toBe(200);
      expect(response.body.message).toBe('User bank account deleted successfully');

      // Verify deletion
      const checkResponse = await request(app)
        .get(`/api/user-bank-accounts/${testUserBankAccount.id}`);

      expect(checkResponse.status).toBe(404);
    });

    it('should return 404 for non-existent account', async () => {
      const response = await request(app)
        .delete('/api/user-bank-accounts/999');

      expect(response.status).toBe(404);
      expect(response.body.error).toBe('User bank account not found');
    });
  });
});
