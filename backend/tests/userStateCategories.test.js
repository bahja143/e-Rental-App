const request = require('supertest');
const app = require('../src/app');
const { sequelize } = require('../src/models');
const { User, StateCategory, UserStateCategory } = require('../src/models');

// Mock the auth middleware
jest.mock('../src/middleware/authMiddleware', () => ({
  authenticateToken: (req, res, next) => {
    req.user = { userId: 1, email: 'test@example.com' };
    next();
  },
}));

describe('User State Categories API', () => {
  let testUser;
  let testStateCategory;

  beforeAll(async () => {
    // Sync database
    await sequelize.sync({ force: true });

    // Create test user
    testUser = await User.create({
      name: 'Test User',
      email: 'test@example.com',
      password: 'password123',
      role: 'user',
      user_type: 'buyer',
    });

    // Create test state category
    testStateCategory = await StateCategory.create({
      name_en: 'Test Category EN',
      name_so: 'Test Category SO',
    });
  });

  afterAll(async () => {
    await sequelize.close();
  });

  describe('POST /api/user-state-categories', () => {
    it('should create a new user state category association', async () => {
      const response = await request(app)
        .post('/api/user-state-categories')
        .set('Authorization', `Bearer mock-token`)
        .send({
          user_id: testUser.id,
          state_categories_id: testStateCategory.id,
        });

      expect(response.status).toBe(201);
      expect(response.body.message).toBe('User state category association created successfully');
      expect(response.body.data.user_id).toBe(testUser.id);
      expect(response.body.data.state_categories_id).toBe(testStateCategory.id);
    });

    it('should return 409 for duplicate association', async () => {
      const response = await request(app)
        .post('/api/user-state-categories')
        .set('Authorization', `Bearer mock-token`)
        .send({
          user_id: testUser.id,
          state_categories_id: testStateCategory.id,
        });

      expect(response.status).toBe(409);
      expect(response.body.error).toBe('User is already associated with this state category');
    });

    it('should return 400 for invalid user_id', async () => {
      const response = await request(app)
        .post('/api/user-state-categories')
        .set('Authorization', `Bearer mock-token`)
        .send({
          user_id: 'invalid',
          state_categories_id: testStateCategory.id,
        });

      expect(response.status).toBe(400);
      expect(response.body.error).toBe('Valid user_id is required');
    });

    it('should return 400 for invalid state_categories_id', async () => {
      const response = await request(app)
        .post('/api/user-state-categories')
        .set('Authorization', `Bearer mock-token`)
        .send({
          user_id: testUser.id,
          state_categories_id: 'invalid',
        });

      expect(response.status).toBe(400);
      expect(response.body.error).toBe('Valid state_categories_id is required');
    });

    it('should return 404 for non-existent user', async () => {
      const response = await request(app)
        .post('/api/user-state-categories')
        .set('Authorization', `Bearer mock-token`)
        .send({
          user_id: 999,
          state_categories_id: testStateCategory.id,
        });

      expect(response.status).toBe(404);
      expect(response.body.error).toBe('User not found');
    });

    it('should return 404 for non-existent state category', async () => {
      const response = await request(app)
        .post('/api/user-state-categories')
        .set('Authorization', `Bearer mock-token`)
        .send({
          user_id: testUser.id,
          state_categories_id: 999,
        });

      expect(response.status).toBe(404);
      expect(response.body.error).toBe('State category not found');
    });
  });

  describe('GET /api/user-state-categories', () => {
    it('should get all user state categories with pagination', async () => {
      const response = await request(app)
        .get('/api/user-state-categories')
        .set('Authorization', `Bearer mock-token`);

      expect(response.status).toBe(200);
      expect(response.body.data).toBeDefined();
      expect(response.body.pagination).toBeDefined();
      expect(Array.isArray(response.body.data)).toBe(true);
    });

    it('should filter by user_id', async () => {
      const response = await request(app)
        .get(`/api/user-state-categories?user_id=${testUser.id}`)
        .set('Authorization', `Bearer mock-token`);

      expect(response.status).toBe(200);
      expect(response.body.data.length).toBeGreaterThan(0);
      response.body.data.forEach(item => {
        expect(item.user_id).toBe(testUser.id);
      });
    });

    it('should filter by state_categories_id', async () => {
      const response = await request(app)
        .get(`/api/user-state-categories?state_categories_id=${testStateCategory.id}`)
        .set('Authorization', `Bearer mock-token`);

      expect(response.status).toBe(200);
      expect(response.body.data.length).toBeGreaterThan(0);
      response.body.data.forEach(item => {
        expect(item.state_categories_id).toBe(testStateCategory.id);
      });
    });
  });

  describe('GET /api/user-state-categories/:id', () => {
    let testAssociation;

    beforeAll(async () => {
      testAssociation = await UserStateCategory.findOne({
        where: {
          user_id: testUser.id,
          state_categories_id: testStateCategory.id,
        },
      });
    });

    it('should get single user state category by ID', async () => {
      const response = await request(app)
        .get(`/api/user-state-categories/${testAssociation.id}`)
        .set('Authorization', `Bearer mock-token`);

      expect(response.status).toBe(200);
      expect(response.body.id).toBe(testAssociation.id);
      expect(response.body.user_id).toBe(testUser.id);
      expect(response.body.state_categories_id).toBe(testStateCategory.id);
    });

    it('should return 404 for non-existent association', async () => {
      const response = await request(app)
        .get('/api/user-state-categories/999')
        .set('Authorization', `Bearer mock-token`);

      expect(response.status).toBe(404);
      expect(response.body.error).toBe('User state category not found');
    });

    it('should return 400 for invalid ID', async () => {
      const response = await request(app)
        .get('/api/user-state-categories/invalid')
        .set('Authorization', `Bearer mock-token`);

      expect(response.status).toBe(400);
      expect(response.body.error).toBe('Invalid user state category ID');
    });
  });

  describe('PUT /api/user-state-categories/:id', () => {
    let testAssociation;
    let anotherUser;
    let anotherStateCategory;

    beforeAll(async () => {
      testAssociation = await UserStateCategory.findOne({
        where: {
          user_id: testUser.id,
          state_categories_id: testStateCategory.id,
        },
      });

      // Create another user and state category for testing updates
      anotherUser = await User.create({
        name: 'Another User',
        email: 'another@example.com',
        password: 'password123',
        role: 'user',
        user_type: 'buyer',
      });

      anotherStateCategory = await StateCategory.create({
        name_en: 'Another Category EN',
        name_so: 'Another Category SO',
      });
    });

    it('should update user state category association', async () => {
      const response = await request(app)
        .put(`/api/user-state-categories/${testAssociation.id}`)
        .set('Authorization', `Bearer mock-token`)
        .send({
          user_id: anotherUser.id,
        });

      expect(response.status).toBe(200);
      expect(response.body.message).toBe('User state category association updated successfully');
      expect(response.body.data.user_id).toBe(anotherUser.id);
    });

    it('should return 404 for non-existent association', async () => {
      const response = await request(app)
        .put('/api/user-state-categories/999')
        .set('Authorization', `Bearer mock-token`)
        .send({
          user_id: testUser.id,
        });

      expect(response.status).toBe(404);
      expect(response.body.error).toBe('User state category association not found');
    });
  });

  describe('DELETE /api/user-state-categories/:id', () => {
    let testAssociation;

    beforeAll(async () => {
      // Create a new association for deletion test
      testAssociation = await UserStateCategory.create({
        user_id: testUser.id,
        state_categories_id: testStateCategory.id,
      });
    });

    it('should delete user state category association', async () => {
      const response = await request(app)
        .delete(`/api/user-state-categories/${testAssociation.id}`)
        .set('Authorization', `Bearer mock-token`);

      expect(response.status).toBe(200);
      expect(response.body.message).toBe('User state category association deleted successfully');

      // Verify deletion
      const deleted = await UserStateCategory.findByPk(testAssociation.id);
      expect(deleted).toBeNull();
    });

    it('should return 404 for non-existent association', async () => {
      const response = await request(app)
        .delete('/api/user-state-categories/999')
        .set('Authorization', `Bearer mock-token`);

      expect(response.status).toBe(404);
      expect(response.body.error).toBe('User state category association not found');
    });
  });
});
