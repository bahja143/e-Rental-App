process.env.NODE_ENV = 'test';

const request = require('supertest');
const { sequelize, UserListingPackTransaction, User, ListingPack, Coupon } = require('../src/models');

// Mock the authentication middleware to bypass auth for tests
jest.mock('../src/middleware/authMiddleware', () => ({
  authenticateToken: (req, res, next) => {
    req.user = { id: 1, role: 'user' };
    next();
  }
}));

// Mock Bull queues (so they don't interfere during tests)
jest.mock('../src/queues', () => ({
  emailQueue: {
    add: jest.fn(),
    close: jest.fn(),
  },
  emailWorker: {
    close: jest.fn(),
  },
}));

describe('User Listing Pack Transactions API', () => {
  let app;
  let server;

  beforeAll(async () => {
    app = require('../src/app');
    await sequelize.sync({ force: true });
    server = app.listen(0); // Use random free port
  });

  afterAll(async () => {
    if (server) server.close();
    await sequelize.close();
  });

  beforeEach(async () => {
    // Clear all tables before each test
    await UserListingPackTransaction.destroy({ where: {} });
    await User.destroy({ where: {} });
    await ListingPack.destroy({ where: {} });
    await Coupon.destroy({ where: {} });


  });

  // Helper function to create a user
  const createUser = async (name, email, password) => {
    return await User.create({
      name,
      email,
      password,
      city: 'Test City',
      looking_for: 'buy',
    });
  };

  // Helper function to create a listing pack
  const createListingPack = async (name_en, name_so, price, duration_days) => {
    return await ListingPack.create({
      name_en,
      name_so,
      price,
      duration: duration_days,
      features: ['feature1', 'feature2'],
      listing_amount: 10,
    });
  };

  // Helper function to create a coupon
  const createCoupon = async (code, discount_percentage) => {
    return await Coupon.create({
      code,
      type: 'percentage',
      value: discount_percentage,
      use_case: 'listing_package',
      start_date: new Date(),
      expire_date: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000), // 30 days from now
    });
  };

  // ===========================================================
  // GET /api/user-listing-pack-transactions
  // ===========================================================
  describe('GET /api/user-listing-pack-transactions', () => {
    it('should return empty array when no transactions exist', async () => {
      const response = await request(app).get('/api/user-listing-pack-transactions').expect(200);
      expect(response.body).toHaveProperty('data');
      expect(response.body.data).toHaveLength(0);
      expect(response.body.pagination.totalItems).toBe(0);
    });

    it('should return transactions with pagination', async () => {
      const user = await createUser('User1', 'user1@example.com', 'pass123');
      const pack = await createListingPack('Pack1', 'Pack1 SO', 100, 30);

      await UserListingPackTransaction.create({
        user_id: user.id,
        listing_pack_id: pack.id,
        type: 'buy',
        subtotal: 100,
        total: 100,
        payment_method: 'card',
        transaction_ref: 'TXN001',
        status: 'success',
      });

      const response = await request(app)
        .get('/api/user-listing-pack-transactions?page=1&limit=10')
        .expect(200);

      expect(response.body.data).toHaveLength(1);
      expect(response.body.pagination).toHaveProperty('currentPage', 1);
      expect(response.body.pagination).toHaveProperty('totalItems', 1);
    });

    it('should filter transactions by user_id', async () => {
      const user1 = await createUser('User1', 'user1@example.com', 'pass123');
      const user2 = await createUser('User2', 'user2@example.com', 'pass123');
      const pack = await createListingPack('Pack1', 'Pack1 SO', 100, 30);

      await UserListingPackTransaction.create({
        user_id: user1.id,
        listing_pack_id: pack.id,
        type: 'buy',
        subtotal: 100,
        total: 100,
        payment_method: 'card',
        transaction_ref: 'TXN001',
        status: 'success',
      });

      await UserListingPackTransaction.create({
        user_id: user2.id,
        listing_pack_id: pack.id,
        type: 'buy',
        subtotal: 100,
        total: 100,
        payment_method: 'card',
        transaction_ref: 'TXN002',
        status: 'success',
      });

      const response = await request(app)
        .get(`/api/user-listing-pack-transactions?user_id=${user1.id}`)
        .expect(200);

      expect(response.body.data).toHaveLength(1);
      expect(response.body.data[0].user_id).toBe(user1.id);
    });

    it('should filter transactions by type', async () => {
      const user = await createUser('User1', 'user1@example.com', 'pass123');
      const pack = await createListingPack('Pack1', 'Pack1 SO', 100, 30);

      await UserListingPackTransaction.create({
        user_id: user.id,
        listing_pack_id: pack.id,
        type: 'buy',
        subtotal: 100,
        total: 100,
        payment_method: 'card',
        transaction_ref: 'TXN001',
        status: 'success',
      });

      await UserListingPackTransaction.create({
        user_id: user.id,
        listing_pack_id: pack.id,
        type: 'upgrade',
        subtotal: 50,
        total: 50,
        payment_method: 'card',
        transaction_ref: 'TXN002',
        status: 'success',
      });

      const response = await request(app)
        .get('/api/user-listing-pack-transactions?type=buy')
        .expect(200);

      expect(response.body.data).toHaveLength(1);
      expect(response.body.data[0].type).toBe('buy');
    });

    it('should filter transactions by status', async () => {
      const user = await createUser('User1', 'user1@example.com', 'pass123');
      const pack = await createListingPack('Pack1', 'Pack1 SO', 100, 30);

      await UserListingPackTransaction.create({
        user_id: user.id,
        listing_pack_id: pack.id,
        type: 'buy',
        subtotal: 100,
        total: 100,
        payment_method: 'card',
        transaction_ref: 'TXN001',
        status: 'success',
      });

      await UserListingPackTransaction.create({
        user_id: user.id,
        listing_pack_id: pack.id,
        type: 'buy',
        subtotal: 100,
        total: 100,
        payment_method: 'card',
        transaction_ref: 'TXN002',
        status: 'pending',
      });

      const response = await request(app)
        .get('/api/user-listing-pack-transactions?status=success')
        .expect(200);

      expect(response.body.data).toHaveLength(1);
      expect(response.body.data[0].status).toBe('success');
    });
  });

  // ===========================================================
  // GET /api/user-listing-pack-transactions/:id
  // ===========================================================
  describe('GET /api/user-listing-pack-transactions/:id', () => {
    it('should return a single transaction', async () => {
      const user = await createUser('User1', 'user1@example.com', 'pass123');
      const pack = await createListingPack('Pack1', 'Pack1 SO', 100, 30);

      const transaction = await UserListingPackTransaction.create({
        user_id: user.id,
        listing_pack_id: pack.id,
        type: 'buy',
        subtotal: 100,
        total: 100,
        payment_method: 'card',
        transaction_ref: 'TXN001',
        status: 'success',
      });

      const response = await request(app)
        .get(`/api/user-listing-pack-transactions/${transaction.id}`)
        .expect(200);

      expect(response.body.id).toBe(transaction.id);
      expect(response.body.transaction_ref).toBe('TXN001');
    });

    it('should return 404 for non-existent transaction', async () => {
      const response = await request(app)
        .get('/api/user-listing-pack-transactions/999')
        .expect(404);

      expect(response.body.error).toBe('Transaction not found');
    });
  });

  // ===========================================================
  // POST /api/user-listing-pack-transactions
  // ===========================================================
  describe('POST /api/user-listing-pack-transactions', () => {
    it('should create a new transaction', async () => {
      const user = await createUser('User1', 'user1@example.com', 'pass123');
      const pack = await createListingPack('Pack1', 'Pack1 SO', 100, 30);

      const response = await request(app)
        .post('/api/user-listing-pack-transactions')
        .send({
          user_id: user.id,
          listing_pack_id: pack.id,
          type: 'buy',
          subtotal: 100,
          total: 100,
          payment_method: 'card',
          transaction_ref: 'TXN001',
          status: 'success',
        })
        .expect(201);

      expect(response.body.transaction.transaction_ref).toBe('TXN001');
      expect(response.body.transaction.type).toBe('buy');
    });

    it('should create transaction with coupon', async () => {
      const user = await createUser('User1', 'user1@example.com', 'pass123');
      const pack = await createListingPack('Pack1', 'Pack1 SO', 100, 30);
      const coupon = await createCoupon('DISCOUNT10', 10);

      const response = await request(app)
        .post('/api/user-listing-pack-transactions')
        .send({
          user_id: user.id,
          listing_pack_id: pack.id,
          type: 'buy',
          subtotal: 100,
          coupon_id: coupon.id,
          discount: 10,
          total: 90,
          coupon_code: 'DISCOUNT10',
          payment_method: 'card',
          transaction_ref: 'TXN002',
          status: 'success',
        })
        .expect(201);

      expect(response.body.transaction.coupon_code).toBe('DISCOUNT10');
      expect(response.body.transaction.discount).toBe(10);
    });

    it('should return 400 for invalid user_id', async () => {
      const response = await request(app)
        .post('/api/user-listing-pack-transactions')
        .send({
          user_id: 999,
          listing_pack_id: 1,
          type: 'buy',
          subtotal: 100,
          payment_method: 'card',
          transaction_ref: 'TXN001',
        })
        .expect(400);

      expect(response.body.error).toBe('User not found');
    });

    it('should return 400 for invalid listing_pack_id', async () => {
      const user = await createUser('User1', 'user1@example.com', 'pass123');

      const response = await request(app)
        .post('/api/user-listing-pack-transactions')
        .send({
          user_id: user.id,
          listing_pack_id: 999,
          type: 'buy',
          subtotal: 100,
          payment_method: 'card',
          transaction_ref: 'TXN001',
        })
        .expect(400);

      expect(response.body.error).toBe('Listing pack not found');
    });

    it('should return 400 for invalid type', async () => {
      const user = await createUser('User1', 'user1@example.com', 'pass123');
      const pack = await createListingPack('Pack1', 'Pack1 SO', 100, 30);

      const response = await request(app)
        .post('/api/user-listing-pack-transactions')
        .send({
          user_id: user.id,
          listing_pack_id: pack.id,
          type: 'invalid_type',
          subtotal: 100,
          payment_method: 'card',
          transaction_ref: 'TXN001',
        })
        .expect(400);

      expect(response.body.error).toBe('Valid type is required');
    });

    it('should return 400 for duplicate transaction_ref', async () => {
      const user = await createUser('User1', 'user1@example.com', 'pass123');
      const pack = await createListingPack('Pack1', 'Pack1 SO', 100, 30);

      await UserListingPackTransaction.create({
        user_id: user.id,
        listing_pack_id: pack.id,
        type: 'buy',
        subtotal: 100,
        total: 100,
        payment_method: 'card',
        transaction_ref: 'TXN001',
        status: 'success',
      });

      const response = await request(app)
        .post('/api/user-listing-pack-transactions')
        .send({
          user_id: user.id,
          listing_pack_id: pack.id,
          type: 'buy',
          subtotal: 100,
          total: 100,
          payment_method: 'card',
          transaction_ref: 'TXN001',
          status: 'success',
        })
        .expect(409);

      expect(response.body.error).toBe('Transaction reference already exists');
    });
  });

  // ===========================================================
  // PUT /api/user-listing-pack-transactions/:id
  // ===========================================================
  describe('PUT /api/user-listing-pack-transactions/:id', () => {
    it('should update a transaction', async () => {
      const user = await createUser('User1', 'user1@example.com', 'pass123');
      const pack = await createListingPack('Pack1', 'Pack1 SO', 100, 30);

      const transaction = await UserListingPackTransaction.create({
        user_id: user.id,
        listing_pack_id: pack.id,
        type: 'buy',
        subtotal: 100,
        total: 100,
        payment_method: 'card',
        transaction_ref: 'TXN001',
        status: 'pending',
      });

      const response = await request(app)
        .put(`/api/user-listing-pack-transactions/${transaction.id}`)
        .send({
          status: 'success',
          note: 'Payment completed',
        })
        .expect(200);

      expect(response.body.transaction.status).toBe('success');
      expect(response.body.transaction.note).toBe('Payment completed');
    });

    it('should update transaction with bank details', async () => {
      const user = await createUser('User1', 'user1@example.com', 'pass123');
      const pack = await createListingPack('Pack1', 'Pack1 SO', 100, 30);

      const transaction = await UserListingPackTransaction.create({
        user_id: user.id,
        listing_pack_id: pack.id,
        type: 'buy',
        subtotal: 100,
        total: 100,
        payment_method: 'bank',
        transaction_ref: 'TXN001',
        status: 'pending',
      });

      const response = await request(app)
        .put(`/api/user-listing-pack-transactions/${transaction.id}`)
        .send({
          bank_name: 'Test Bank',
          branch: 'Main Branch',
          bank_account: '123456789',
          account_holder_name: 'John Doe',
          swift: 'TESTSWFT',
        })
        .expect(200);

      expect(response.body.transaction.bank_name).toBe('Test Bank');
      expect(response.body.transaction.account_holder_name).toBe('John Doe');
    });

    it('should return 404 for non-existent transaction', async () => {
      const response = await request(app)
        .put('/api/user-listing-pack-transactions/999')
        .send({ status: 'success' })
        .expect(404);

      expect(response.body.error).toBe('Transaction not found');
    });
  });

  // ===========================================================
  // DELETE /api/user-listing-pack-transactions/:id
  // ===========================================================
  describe('DELETE /api/user-listing-pack-transactions/:id', () => {
    it('should delete a transaction', async () => {
      const user = await createUser('User1', 'user1@example.com', 'pass123');
      const pack = await createListingPack('Pack1', 'Pack1 SO', 100, 30);

      const transaction = await UserListingPackTransaction.create({
        user_id: user.id,
        listing_pack_id: pack.id,
        type: 'buy',
        subtotal: 100,
        total: 100,
        payment_method: 'card',
        transaction_ref: 'TXN001',
        status: 'success',
      });

      await request(app)
        .delete(`/api/user-listing-pack-transactions/${transaction.id}`)
        .expect(200);

      expect(await UserListingPackTransaction.findByPk(transaction.id)).toBeNull();
    });

    it('should return 404 for non-existent transaction', async () => {
      const response = await request(app)
        .delete('/api/user-listing-pack-transactions/999')
        .expect(404);

      expect(response.body.error).toBe('Transaction not found');
    });
  });
});
