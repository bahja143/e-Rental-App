const request = require('supertest');
const app = require('../src/app');
const { sequelize } = require('../src/models');
const { Language } = require('../src/models');

// Mock the auth middleware
jest.mock('../src/middleware/authMiddleware', () => ({
  authenticateToken: (req, res, next) => {
    req.user = { userId: 1, email: 'test@example.com' };
    next();
  },
}));

describe('Languages API', () => {
  let testLanguage;

  beforeAll(async () => {
    // Sync database
    await sequelize.sync({ force: true });

    // Create test language
    testLanguage = await Language.create({
      key: 'test_key',
      en: 'Test English',
      so: 'Test Somali',
    });
  });

  afterAll(async () => {
    await sequelize.close();
  });

  describe('POST /api/languages', () => {
    it('should create a new language', async () => {
      const response = await request(app)
        .post('/api/languages')
        .set('Authorization', `Bearer mock-token`)
        .send({
          key: 'welcome_message',
          en: 'Welcome to our platform',
          so: 'Ku soo dhowow madalkayaga',
        });

      expect(response.status).toBe(201);
      expect(response.body.message).toBe('Language created successfully');
      expect(response.body.data.key).toBe('welcome_message');
      expect(response.body.data.en).toBe('Welcome to our platform');
      expect(response.body.data.so).toBe('Ku soo dhowow madalkayaga');
    });

    it('should return 409 for duplicate key', async () => {
      const response = await request(app)
        .post('/api/languages')
        .set('Authorization', `Bearer mock-token`)
        .send({
          key: 'test_key',
          en: 'Duplicate English',
          so: 'Duplicate Somali',
        });

      expect(response.status).toBe(409);
      expect(response.body.error).toBe('Language key already exists');
    });

    it('should return 400 for invalid key', async () => {
      const response = await request(app)
        .post('/api/languages')
        .set('Authorization', `Bearer mock-token`)
        .send({
          key: '',
          en: 'English text',
          so: 'Somali text',
        });

      expect(response.status).toBe(400);
      expect(response.body.error).toBe('key must be 1-255 characters');
    });

    it('should return 400 for missing en', async () => {
      const response = await request(app)
        .post('/api/languages')
        .set('Authorization', `Bearer mock-token`)
        .send({
          key: 'missing_en',
          so: 'Somali text',
        });

      expect(response.status).toBe(400);
      expect(response.body.error).toBe('en must be a non-empty string');
    });

    it('should return 400 for missing so', async () => {
      const response = await request(app)
        .post('/api/languages')
        .set('Authorization', `Bearer mock-token`)
        .send({
          key: 'missing_so',
          en: 'English text',
        });

      expect(response.status).toBe(400);
      expect(response.body.error).toBe('so must be a non-empty string');
    });
  });

  describe('GET /api/languages', () => {
    it('should get all languages with pagination', async () => {
      const response = await request(app)
        .get('/api/languages')
        .set('Authorization', `Bearer mock-token`);

      expect(response.status).toBe(200);
      expect(response.body.data).toBeDefined();
      expect(response.body.pagination).toBeDefined();
      expect(Array.isArray(response.body.data)).toBe(true);
      expect(response.body.data.length).toBeGreaterThan(0);
    });

    it('should filter by search', async () => {
      const response = await request(app)
        .get('/api/languages?search=test')
        .set('Authorization', `Bearer mock-token`);

      expect(response.status).toBe(200);
      expect(response.body.data.length).toBeGreaterThan(0);
      response.body.data.forEach(item => {
        expect(item.key.includes('test') || item.en.includes('test') || item.so.includes('test')).toBe(true);
      });
    });

    it('should sort by key', async () => {
      const response = await request(app)
        .get('/api/languages?sortBy=key&sortOrder=ASC')
        .set('Authorization', `Bearer mock-token`);

      expect(response.status).toBe(200);
      expect(response.body.data.length).toBeGreaterThan(0);
    });
  });

  describe('GET /api/languages/:id', () => {
    it('should get single language by ID', async () => {
      const response = await request(app)
        .get(`/api/languages/${testLanguage.id}`)
        .set('Authorization', `Bearer mock-token`);

      expect(response.status).toBe(200);
      expect(response.body.id).toBe(testLanguage.id);
      expect(response.body.key).toBe(testLanguage.key);
      expect(response.body.en).toBe(testLanguage.en);
      expect(response.body.so).toBe(testLanguage.so);
    });

    it('should return 404 for non-existent language', async () => {
      const response = await request(app)
        .get('/api/languages/999')
        .set('Authorization', `Bearer mock-token`);

      expect(response.status).toBe(404);
      expect(response.body.error).toBe('Language not found');
    });

    it('should return 400 for invalid ID', async () => {
      const response = await request(app)
        .get('/api/languages/invalid')
        .set('Authorization', `Bearer mock-token`);

      expect(response.status).toBe(400);
      expect(response.body.error).toBe('Invalid language ID');
    });
  });

  describe('PUT /api/languages/:id', () => {
    it('should update language', async () => {
      const response = await request(app)
        .put(`/api/languages/${testLanguage.id}`)
        .set('Authorization', `Bearer mock-token`)
        .send({
          en: 'Updated English',
        });

      expect(response.status).toBe(200);
      expect(response.body.message).toBe('Language updated successfully');
      expect(response.body.data.en).toBe('Updated English');
    });

    it('should return 404 for non-existent language', async () => {
      const response = await request(app)
        .put('/api/languages/999')
        .set('Authorization', `Bearer mock-token`)
        .send({
          en: 'Updated English',
        });

      expect(response.status).toBe(404);
      expect(response.body.error).toBe('Language not found');
    });

    it('should return 409 for duplicate key', async () => {
      // Create another language first
      await Language.create({
        key: 'another_key',
        en: 'Another English',
        so: 'Another Somali',
      });

      const response = await request(app)
        .put(`/api/languages/${testLanguage.id}`)
        .set('Authorization', `Bearer mock-token`)
        .send({
          key: 'another_key',
        });

      expect(response.status).toBe(409);
      expect(response.body.error).toBe('Language key already exists');
    });
  });

  describe('DELETE /api/languages/:id', () => {
    let deleteLanguage;

    beforeAll(async () => {
      // Create a language for deletion test
      deleteLanguage = await Language.create({
        key: 'delete_key',
        en: 'Delete English',
        so: 'Delete Somali',
      });
    });

    it('should delete language', async () => {
      const response = await request(app)
        .delete(`/api/languages/${deleteLanguage.id}`)
        .set('Authorization', `Bearer mock-token`);

      expect(response.status).toBe(200);
      expect(response.body.message).toBe('Language deleted successfully');

      // Verify deletion
      const deleted = await Language.findByPk(deleteLanguage.id);
      expect(deleted).toBeNull();
    });

    it('should return 404 for non-existent language', async () => {
      const response = await request(app)
        .delete('/api/languages/999')
        .set('Authorization', `Bearer mock-token`);

      expect(response.status).toBe(404);
      expect(response.body.error).toBe('Language not found');
    });
  });
});
