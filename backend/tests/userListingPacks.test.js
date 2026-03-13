const request = require('supertest');
const app = require('../src/app');
const { sequelize, User, ListingPack, UserListingPack } = require('../src/models');

// Mock the auth middleware
jest.mock('../src/middleware/authMiddleware', () => ({
  authenticateToken: (req, res, next) => {
    req.user = { userId: 1, email: 'test@example.com' };
    next();
  },
}));

describe('User Listing Packs API', () => {
  let testUser;
  let testListingPack;

  beforeAll(async () => {
    // Sync database (force: true clears all data)
    await sequelize.sync({ force: true });

    // Create a test user
    testUser = await User.create({
      name: 'Test User',
      email: 'test@example.com',
      password: 'password123',
      city: 'Test City',
      looking_for: 'buy',
    });

    // Create a test listing pack with the required field
    testListingPack = await ListingPack.create({
      name_en: 'Test Pack',
      name_so: 'Test Pack SO',
      price: 100,
      duration: 30,
      features: ['feature1', 'feature2'],
      listing_amount: 10, // ✅ required field added
    });
  });

  afterAll(async () => {
    await sequelize.close();
  });

  beforeEach(async () => {
    await UserListingPack.destroy({ where: {} });
  });

  describe('GET /api/user-listing-packs', () => {
    it('should return an empty array when no user listing packs exist', async () => {
      const response = await request(app)
        .get('/api/user-listing-packs')
        .set('Authorization', `Bearer mock-token`)
        .expect(200);

      expect(response.body.data).toHaveLength(0);
    });

    it('should return user listing packs', async () => {
      await UserListingPack.create({
        user_id: testUser.id,
        listing_pack_id: testListingPack.id,
        start: new Date(),
        end: new Date(),
        status: 'active',
        total_paid: 100,
      });

      const response = await request(app)
        .get('/api/user-listing-packs')
        .set('Authorization', `Bearer mock-token`)
        .expect(200);

      expect(response.body.data).toHaveLength(1);
      expect(response.body.data[0].status).toBe('active');
    });
  });

  describe('GET /api/user-listing-packs/:id', () => {
    it('should return a single user listing pack', async () => {
      const userListingPack = await UserListingPack.create({
        user_id: testUser.id,
        listing_pack_id: testListingPack.id,
        start: new Date(),
        end: new Date(),
        status: 'active',
        total_paid: 100,
      });

      const response = await request(app)
        .get(`/api/user-listing-packs/${userListingPack.id}`)
        .set('Authorization', `Bearer mock-token`)
        .expect(200);

      expect(response.body.id).toBe(userListingPack.id);
    });

    it('should return 404 for a non-existent user listing pack', async () => {
      await request(app)
        .get('/api/user-listing-packs/999')
        .set('Authorization', `Bearer mock-token`)
        .expect(404);
    });
  });

  describe('POST /api/user-listing-packs', () => {
    it('should create a new user listing pack', async () => {
      const response = await request(app)
        .post('/api/user-listing-packs')
        .set('Authorization', `Bearer mock-token`)
        .send({
          user_id: testUser.id,
          listing_pack_id: testListingPack.id,
          start: new Date(),
          end: new Date(),
          status: 'active',
          total_paid: 100,
        })
        .expect(201);

      expect(response.body).toHaveProperty('id');
      expect(response.body.status).toBe('active');
    });

    it('should return 400 for missing required fields', async () => {
      await request(app)
        .post('/api/user-listing-packs')
        .set('Authorization', `Bearer mock-token`)
        .send({})
        .expect(400);
    });
  });

  describe('PUT /api/user-listing-packs/:id', () => {
    it('should update a user listing pack', async () => {
      const userListingPack = await UserListingPack.create({
        user_id: testUser.id,
        listing_pack_id: testListingPack.id,
        start: new Date(),
        end: new Date(),
        status: 'active',
        total_paid: 100,
      });

      const response = await request(app)
        .put(`/api/user-listing-packs/${userListingPack.id}`)
        .set('Authorization', `Bearer mock-token`)
        .send({ status: 'expired' })
        .expect(200);

      expect(response.body.status).toBe('expired');
    });
  });

  describe('DELETE /api/user-listing-packs/:id', () => {
    it('should delete a user listing pack', async () => {
      const userListingPack = await UserListingPack.create({
        user_id: testUser.id,
        listing_pack_id: testListingPack.id,
        start: new Date(),
        end: new Date(),
        status: 'active',
        total_paid: 100,
      });

      await request(app)
        .delete(`/api/user-listing-packs/${userListingPack.id}`)
        .set('Authorization', `Bearer mock-token`)
        .expect(204);
    });
  });
});
