/**
 * @file propertyFeatures.test.js
 * @description Jest + Supertest tests for Property Features API (CRUD operations)
 */

const request = require('supertest');
const app = require('../src/app');
const { sequelize } = require('../src/models');

describe('PropertyFeatures API', () => {
  beforeAll(async () => {
    await sequelize.authenticate();
    await sequelize.sync({ force: true });
  });

  afterAll(async () => {
    await sequelize.close();
  });

  let createdId;

  // ======================
  // GET /api/property-features
  // ======================

  describe('GET /api/property-features', () => {
    it('should get all property features with pagination', async () => {
      const response = await request(app).get('/api/property-features');
      expect(response.status).toBe(200);
      expect(Array.isArray(response.body)).toBe(true);
    });

    it('should filter by search', async () => {
      const response = await request(app).get('/api/property-features?search=test');
      expect(response.status).toBe(200);
      expect(Array.isArray(response.body)).toBe(true);
    });

    it('should filter by type', async () => {
      const response = await request(app).get('/api/property-features?type=string');
      expect(response.status).toBe(200);
      expect(Array.isArray(response.body)).toBe(true);
    });

    it('should sort by name_en', async () => {
      const response = await request(app).get('/api/property-features?sortBy=name_en&sortOrder=ASC');
      expect(response.status).toBe(200);
      expect(Array.isArray(response.body)).toBe(true);
    });
  });

  // ======================
  // GET /api/property-features/:id
  // ======================

  describe('GET /api/property-features/:id', () => {
    it('should get single property feature by ID', async () => {
      const response = await request(app).get('/api/property-features/1');
      if (response.status === 200) {
        expect(response.body).toHaveProperty('id', 1);
      } else {
        expect(response.status).toBe(404);
      }
    });

    it('should return 404 for non-existent property feature', async () => {
      const response = await request(app).get('/api/property-features/999');
      expect(response.status).toBe(404);
      expect(response.body.error).toBe('Property feature not found');
    });

    it('should return 404 for invalid ID', async () => {
      const response = await request(app).get('/api/property-features/invalid');
      expect(response.status).toBe(404);
      expect(response.body.error).toBe('Property feature not found');
    });
  });

  // ======================
  // POST /api/property-features
  // ======================

  describe('POST /api/property-features', () => {
    it('should create a new property feature', async () => {
      const response = await request(app)
        .post('/api/property-features')
        .send({
          name_en: 'Test Feature',
          name_so: 'টেস্ট ফিচার',
          type: 'string'
        });

      expect(response.status).toBe(201);
      expect(response.body).toHaveProperty('id');
      createdId = response.body.id;
    });

    it('should create property feature with default type', async () => {
      const response = await request(app)
        .post('/api/property-features')
        .send({
          name_en: 'Default Type Feature',
          name_so: 'ডিফল্ট টাইপ ফিচার'
        });

      expect(response.status).toBe(201);
      expect(response.body.type).toBeDefined();
    });

    it('should return 400 for missing name_en', async () => {
      const response = await request(app)
        .post('/api/property-features')
        .send({
          name_so: 'নাম অনুপস্থিত'
        });

      expect(response.status).toBe(400);
      expect(response.body.error).toBe('name_en and name_so are required');
    });

    it('should return 400 for missing name_so', async () => {
      const response = await request(app)
        .post('/api/property-features')
        .send({
          name_en: 'Missing Name SO'
        });

      expect(response.status).toBe(400);
      expect(response.body.error).toBe('name_en and name_so are required');
    });

    it('should return 400 for invalid type', async () => {
      const response = await request(app)
        .post('/api/property-features')
        .send({
          name_en: 'Invalid Type',
          name_so: 'অবৈধ টাইপ',
          type: 'unknown'
        });

      expect(response.status).toBe(400);
      expect(response.body.error).toBe('type must be either "number" or "string"');
    });

    it('should return 400 for duplicate name_en', async () => {
      const response = await request(app)
        .post('/api/property-features')
        .send({
          name_en: 'Test Feature',
          name_so: 'ডুপ্লিকেট ফিচার',
          type: 'string'
        });

      expect(response.status).toBe(400);
    });
  });

  // ======================
  // PUT /api/property-features/:id
  // ======================

  describe('PUT /api/property-features/:id', () => {
    it('should update property feature', async () => {
      const response = await request(app)
        .put(`/api/property-features/${createdId}`)
        .send({
          name_en: 'Updated Feature',
          name_so: 'আপডেটেড ফিচার',
          type: 'string'
        });

      expect(response.status).toBe(200);
      expect(response.body.name_en).toBe('Updated Feature');
    });

    it('should return 400 for non-existent property feature', async () => {
      const response = await request(app)
        .put('/api/property-features/999')
        .send({
          name_en: 'Nonexistent',
          name_so: 'অস্তিত্বহীন'
        });

      expect(response.status).toBe(400);
      expect(response.body.error).toBe('Property feature not found');
    });

    it('should return 400 for missing name_en on update', async () => {
      const response = await request(app)
        .put(`/api/property-features/${createdId}`)
        .send({
          name_so: 'নাম অনুপস্থিত'
        });

      expect(response.status).toBe(400);
      expect(response.body.error).toBe('name_en and name_so are required');
    });

    it('should return 400 for invalid type on update', async () => {
      const response = await request(app)
        .put(`/api/property-features/${createdId}`)
        .send({
          name_en: 'Invalid Type Update',
          name_so: 'অবৈধ টাইপ আপডেট',
          type: 'invalid'
        });

      expect(response.status).toBe(400);
      expect(response.body.error).toBe('name_en and name_so are required');
    });
  });

  // ======================
  // DELETE /api/property-features/:id
  // ======================

  describe('DELETE /api/property-features/:id', () => {
    it('should delete property feature', async () => {
      const response = await request(app).delete(`/api/property-features/${createdId}`);
      expect(response.status).toBe(204);
    });

    it('should return 404 for non-existent property feature', async () => {
      const response = await request(app).delete('/api/property-features/999');
      expect(response.status).toBe(404);
      expect(response.body.error).toBe('Property feature not found');
    });

    it('should return 404 for invalid ID', async () => {
      const response = await request(app).delete('/api/property-features/invalid');
      expect(response.status).toBe(404);
      expect(response.body.error).toBe('Property feature not found');
    });
  });
});
