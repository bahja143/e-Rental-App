process.env.NODE_ENV = 'test';

const request = require('supertest');
const { sequelize, Company } = require('../src/models');

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

describe('Companies API', () => {
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
    await Company.destroy({ where: {} });
    // Reset SQLite auto-increment sequence
    await sequelize.query('DELETE FROM sqlite_sequence WHERE name = "companies"');
  });

  describe('GET /api/companies', () => {
    it('should return empty array when no companies exist', async () => {
      const response = await request(app)
        .get('/api/companies')
        .expect(200);

      expect(response.body).toHaveProperty('data');
      expect(response.body).toHaveProperty('pagination');
      expect(response.body.data).toHaveLength(0);
      expect(response.body.pagination.totalItems).toBe(0);
    });

    it('should return companies with default pagination', async () => {
      // Create test companies
      const companies = [];
      for (let i = 1; i <= 15; i++) {
        companies.push({
          name_en: `Company ${i}`,
          name_so: `Shirkadda ${i}`,
          address_en: `Address ${i} English`,
          address_so: `Cinwaanka ${i} Somali`,
          emails: [`contact${i}@company${i}.com`],
          phones: [`+252${i}000000`],
        });
      }
      await Company.bulkCreate(companies);

      const response = await request(app)
        .get('/api/companies')
        .expect(200);

      expect(response.body.data).toHaveLength(10); // Default limit
      expect(response.body.pagination.totalItems).toBe(15);
      expect(response.body.pagination.totalPages).toBe(2);
      expect(response.body.pagination.currentPage).toBe(1);
      expect(response.body.pagination.hasNextPage).toBe(true);
      expect(response.body.pagination.hasPrevPage).toBe(false);
    });

    it('should support pagination', async () => {
      // Create test companies
      const companies = [];
      for (let i = 1; i <= 25; i++) {
        companies.push({
          name_en: `Company ${i}`,
          address_en: `Address ${i}`,
        });
      }
      await Company.bulkCreate(companies);

      const response = await request(app)
        .get('/api/companies?page=2&limit=10')
        .expect(200);

      expect(response.body.data).toHaveLength(10);
      expect(response.body.pagination.totalItems).toBe(25);
      expect(response.body.pagination.currentPage).toBe(2);
      expect(response.body.pagination.hasNextPage).toBe(true);
      expect(response.body.pagination.hasPrevPage).toBe(true);
    });

    it('should support search functionality', async () => {
      await Company.create({
        name_en: 'Tech Solutions Ltd',
        name_so: 'Xalinta Teknoloji',
        address_en: '123 Tech Street',
        address_so: '123 Waddada Teknoloji',
      });
      await Company.create({
        name_en: 'Global Services Inc',
        address_en: '456 Service Avenue',
      });
      await Company.create({
        name_en: 'Local Company',
        address_en: '789 Local Road',
      });

      const response = await request(app)
        .get('/api/companies?search=tech')
        .expect(200);

      expect(response.body.data).toHaveLength(1);
      expect(response.body.data[0].name_en).toBe('Tech Solutions Ltd');
      expect(response.body.data[0].name_so).toBe('Xalinta Teknoloji');
    });

    it('should support sorting', async () => {
      await Company.create({
        name_en: 'Zeta Corp',
        address_en: 'Address Z',
      });
      await Company.create({
        name_en: 'Alpha Inc',
        address_en: 'Address A',
      });

      const response = await request(app)
        .get('/api/companies?sortBy=name_en&sortOrder=ASC')
        .expect(200);

      expect(response.body.data[0].name_en).toBe('Alpha Inc');
      expect(response.body.data[1].name_en).toBe('Zeta Corp');
    });

    it('should handle invalid page number', async () => {
      const response = await request(app)
        .get('/api/companies?page=invalid')
        .expect(400);

      expect(response.body.error).toBe('Invalid page number');
    });

    it('should handle invalid limit', async () => {
      const response = await request(app)
        .get('/api/companies?limit=200')
        .expect(400);

      expect(response.body.error).toBe('Invalid limit (1-100)');
    });
  });

  describe('GET /api/companies/:id', () => {
    it('should return a company by ID', async () => {
      const company = await Company.create({
        name_en: 'Test Company',
        address_en: 'Test Address',
        emails: ['test@company.com'],
        phones: ['+2521000000'],
      });

      const response = await request(app)
        .get(`/api/companies/${company.id}`)
        .expect(200);

      expect(response.body.id).toBe(company.id);
      expect(response.body.name_en).toBe('Test Company');
      expect(response.body.address_en).toBe('Test Address');
    });

    it('should return 404 for non-existent company', async () => {
      const response = await request(app)
        .get('/api/companies/999')
        .expect(404);

      expect(response.body.error).toBe('Company not found');
    });

    it('should handle invalid ID', async () => {
      const response = await request(app)
        .get('/api/companies/invalid')
        .expect(400);

      expect(response.body.error).toBe('Invalid company ID');
    });
  });

  describe('POST /api/companies', () => {
    it('should create a new company', async () => {
      const newCompany = {
        name_en: 'New Company Ltd',
        name_so: 'Shirkadda Cusub',
        address_en: '123 Business Street',
        address_so: '123 Waddada Ganacsiga',
        emails: ['contact@newcompany.com', 'info@newcompany.com'],
        phones: ['+2521000000', '+2522000000'],
      };

      const response = await request(app)
        .post('/api/companies')
        .send(newCompany)
        .expect(201);

      expect(response.body.message).toBe('Company created successfully');
      expect(response.body.company.name_en).toBe(newCompany.name_en);
      expect(response.body.company.name_so).toBe(newCompany.name_so);
      expect(response.body.company.address_en).toBe(newCompany.address_en);
      expect(response.body.company.address_so).toBe(newCompany.address_so);
      expect(response.body.company.emails).toEqual(newCompany.emails);
      expect(response.body.company.phones).toEqual(newCompany.phones);
    });

    it('should create company with minimal required fields', async () => {
      const newCompany = {
        name_en: 'Minimal Company',
        address_en: 'Minimal Address',
      };

      const response = await request(app)
        .post('/api/companies')
        .send(newCompany)
        .expect(201);

      expect(response.body.company.name_en).toBe(newCompany.name_en);
      expect(response.body.company.address_en).toBe(newCompany.address_en);
      expect(response.body.company.name_so).toBeNull();
      expect(response.body.company.address_so).toBeNull();
      expect(response.body.company.emails).toBeNull();
      expect(response.body.company.phones).toBeNull();
    });

    it('should validate required fields', async () => {
      const response = await request(app)
        .post('/api/companies')
        .send({})
        .expect(400);

      expect(response.body.error).toBe('name_en must be 2-255 characters');
    });

    it('should validate name_en length', async () => {
      const response = await request(app)
        .post('/api/companies')
        .send({
          name_en: 'A',
          address_en: 'Valid Address',
        })
        .expect(400);

      expect(response.body.error).toBe('name_en must be 2-255 characters');
    });

    it('should validate address_en is not empty', async () => {
      const response = await request(app)
        .post('/api/companies')
        .send({
          name_en: 'Valid Name',
          address_en: '',
        })
        .expect(400);

      expect(response.body.error).toBe('address_en is required and cannot be empty');
    });

    it('should validate emails array format', async () => {
      const response = await request(app)
        .post('/api/companies')
        .send({
          name_en: 'Valid Name',
          address_en: 'Valid Address',
          emails: 'invalid-email',
        })
        .expect(400);

      expect(response.body.error).toBe('emails must be an array');
    });

    it('should validate email format in array', async () => {
      const response = await request(app)
        .post('/api/companies')
        .send({
          name_en: 'Valid Name',
          address_en: 'Valid Address',
          emails: ['invalid-email'],
        })
        .expect(400);

      expect(response.body.error).toBe('Invalid email format in emails array');
    });

    it('should validate phones array format', async () => {
      const response = await request(app)
        .post('/api/companies')
        .send({
          name_en: 'Valid Name',
          address_en: 'Valid Address',
          phones: 'invalid-phone',
        })
        .expect(400);

      expect(response.body.error).toBe('phones must be an array');
    });

    it('should validate phone format in array', async () => {
      const response = await request(app)
        .post('/api/companies')
        .send({
          name_en: 'Valid Name',
          address_en: 'Valid Address',
          phones: ['invalid-phone'],
        })
        .expect(400);

      expect(response.body.error).toBe('Invalid phone format in phones array');
    });
  });

  describe('PUT /api/companies/:id', () => {
    let testCompany;

    beforeEach(async () => {
      testCompany = await Company.create({
        name_en: 'Test Company',
        name_so: 'Shirkadda Tijaabo',
        address_en: 'Test Address',
        address_so: 'Cinwaanka Tijaabo',
        emails: ['test@company.com'],
        phones: ['+2521000000'],
      });
    });

    it('should update a company', async () => {
      const updates = {
        name_en: 'Updated Company',
        name_so: 'Shirkadda Cusub',
        address_en: 'Updated Address',
        address_so: 'Cinwaanka Cusub',
        emails: ['updated@company.com'],
        phones: ['+2522000000'],
      };

      const response = await request(app)
        .put(`/api/companies/${testCompany.id}`)
        .send(updates)
        .expect(200);

      expect(response.body.message).toBe('Company updated successfully');
      expect(response.body.company.name_en).toBe(updates.name_en);
      expect(response.body.company.name_so).toBe(updates.name_so);
      expect(response.body.company.address_en).toBe(updates.address_en);
      expect(response.body.company.address_so).toBe(updates.address_so);
      expect(response.body.company.emails).toEqual(updates.emails);
      expect(response.body.company.phones).toEqual(updates.phones);
    });

    it('should return 404 for non-existent company', async () => {
      const response = await request(app)
        .put('/api/companies/999')
        .send({ name_en: 'Updated' })
        .expect(404);

      expect(response.body.error).toBe('Company not found');
    });

    it('should validate update data', async () => {
      const response = await request(app)
        .put(`/api/companies/${testCompany.id}`)
        .send({ name_en: 'A' })
        .expect(400);

      expect(response.body.error).toBe('name_en must be 2-255 characters');
    });

    it('should validate emails array on update', async () => {
      const response = await request(app)
        .put(`/api/companies/${testCompany.id}`)
        .send({ emails: 'invalid' })
        .expect(400);

      expect(response.body.error).toBe('emails must be an array or null');
    });

    it('should validate phones array on update', async () => {
      const response = await request(app)
        .put(`/api/companies/${testCompany.id}`)
        .send({ phones: 'invalid' })
        .expect(400);

      expect(response.body.error).toBe('phones must be an array or null');
    });

    it('should allow setting fields to null', async () => {
      const response = await request(app)
        .put(`/api/companies/${testCompany.id}`)
        .send({
          name_so: null,
          address_so: null,
          emails: null,
          phones: null,
        })
        .expect(200);

      expect(response.body.company.name_so).toBeNull();
      expect(response.body.company.address_so).toBeNull();
      expect(response.body.company.emails).toBeNull();
      expect(response.body.company.phones).toBeNull();
    });
  });

  describe('DELETE /api/companies/:id', () => {
    let testCompany;

    beforeEach(async () => {
      testCompany = await Company.create({
        name_en: 'Test Company',
        address_en: 'Test Address',
      });
    });

    it('should delete a company', async () => {
      const response = await request(app)
        .delete(`/api/companies/${testCompany.id}`)
        .expect(200);

      expect(response.body.message).toBe('Company deleted successfully');

      // Verify deletion
      const deleted = await Company.findByPk(testCompany.id);
      expect(deleted).toBeNull();
    });

    it('should return 404 for non-existent company', async () => {
      const response = await request(app)
        .delete('/api/companies/999')
        .expect(404);

      expect(response.body.error).toBe('Company not found');
    });

    it('should handle invalid ID', async () => {
      const response = await request(app)
        .delete('/api/companies/invalid')
        .expect(400);

      expect(response.body.error).toBe('Invalid company ID');
    });
  });
});
