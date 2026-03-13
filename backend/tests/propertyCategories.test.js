process.env.NODE_ENV = 'test';
process.env.JWT_SECRET = 'test-secret';

const request = require('supertest');
const { sequelize, PropertyCategory } = require('../src/models');
const jwt = require('jsonwebtoken');

describe('PropertyCategory API', () => {
  let app;
  let server;
  let authToken;

  beforeAll(async () => {
    // Create a test app with in-memory database
    const express = require('express');
    const cors = require('cors');
    const helmet = require('helmet');
    const morgan = require('morgan');
    const rateLimit = require('express-rate-limit');

    app = express();

    // Middleware
    app.use(helmet());
    app.use(cors());
    app.use(morgan('combined'));
    app.use(express.json());
    app.use(express.urlencoded({ extended: true }));

    // Rate limiting (disabled for tests)
    const limiter = rateLimit({
      windowMs: 15 * 60 * 1000,
      max: 100,
      message: 'Too many requests from this IP, please try again later.',
      standardHeaders: true,
      legacyHeaders: false,
      skip: () => true, // Skip rate limiting for tests
    });
    app.use(limiter);

    // Sync the in-memory database
    await sequelize.sync({ force: true });

    // Create a test JWT token
    const payload = { id: 1, email: 'test@example.com' };
    authToken = jwt.sign(payload, process.env.JWT_SECRET || 'test-secret', { expiresIn: '1h' });

    // Import and use the propertyCategories routes
    const propertyCategoriesRouter = require('../src/routes/propertyCategories');
    app.use('/api/property-categories', propertyCategoriesRouter);

    // Basic route
    app.get('/', (req, res) => {
      res.json({ message: 'Welcome to Hantario API' });
    });

    server = app.listen(0); // Use random available port
  });

  afterAll(async () => {
    if (server) {
      server.close();
    }
    await sequelize.close();
  });

  beforeEach(async () => {
    // Clear the table before each test
    await PropertyCategory.destroy({ where: {} });
  });

  it('should create a new property category', async () => {
    const response = await request(app)
      .post('/api/property-categories')
      .set('Authorization', `Bearer ${authToken}`)
      .send({ name_en: 'Apartment', name_so: 'Apartment So' })
      .expect(201);

    expect(response.body).toHaveProperty('id');
    expect(response.body.name_en).toBe('Apartment');
    expect(response.body.name_so).toBe('Apartment So');
  });
});
