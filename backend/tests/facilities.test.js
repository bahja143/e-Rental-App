process.env.NODE_ENV = 'test';
process.env.JWT_SECRET = 'test-secret';

const request = require('supertest');
const { sequelize, Facility } = require('../src/models');
const jwt = require('jsonwebtoken');

describe('Facilities API', () => {
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

    // Import and use the facilities routes
    const facilitiesRouter = require('../src/routes/facilities');
    app.use('/api/facilities', facilitiesRouter);

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
    await Facility.destroy({ where: {} });
  });

  it('should create a new facility', async () => {
    const response = await request(app)
      .post('/api/facilities')
      .set('Authorization', `Bearer ${authToken}`)
      .send({ name_en: 'Swimming Pool', name_so: 'Barkada Dabaal' })
      .expect(201);

    expect(response.body).toHaveProperty('id');
    expect(response.body.name_en).toBe('Swimming Pool');
    expect(response.body.name_so).toBe('Barkada Dabaal');
  });

  it('should get all facilities with pagination', async () => {
    // Create test facilities
    await Facility.bulkCreate([
      { name_en: 'Swimming Pool', name_so: 'Barkada Dabaal' },
      { name_en: 'Gym', name_so: 'Jimicsi' },
      { name_en: 'Parking', name_so: 'Baabuurta' },
    ]);

    const response = await request(app)
      .get('/api/facilities')
      .set('Authorization', `Bearer ${authToken}`)
      .expect(200);

    expect(response.body.data).toHaveLength(3);
    expect(response.body.pagination).toHaveProperty('total');
    expect(response.body.pagination.total).toBe(3);
  });

  it('should filter facilities by search', async () => {
    await Facility.bulkCreate([
      { name_en: 'Swimming Pool', name_so: 'Barkada Dabaal' },
      { name_en: 'Gym', name_so: 'Jimicsi' },
    ]);

    const response = await request(app)
      .get('/api/facilities?search=Swimming')
      .set('Authorization', `Bearer ${authToken}`)
      .expect(200);

    expect(response.body.data).toHaveLength(1);
    expect(response.body.data[0].name_en).toBe('Swimming Pool');
  });

  it('should get facility by ID', async () => {
    const facility = await Facility.create({
      name_en: 'Swimming Pool',
      name_so: 'Barkada Dabaal',
    });

    const response = await request(app)
      .get(`/api/facilities/${facility.id}`)
      .set('Authorization', `Bearer ${authToken}`)
      .expect(200);

    expect(response.body.id).toBe(facility.id);
    expect(response.body.name_en).toBe('Swimming Pool');
  });

  it('should return 404 for non-existent facility', async () => {
    const response = await request(app)
      .get('/api/facilities/999')
      .set('Authorization', `Bearer ${authToken}`)
      .expect(404);

    expect(response.body.error).toBe('Facility not found');
  });

  it('should update a facility', async () => {
    const facility = await Facility.create({
      name_en: 'Swimming Pool',
      name_so: 'Barkada Dabaal',
    });

    const response = await request(app)
      .put(`/api/facilities/${facility.id}`)
      .set('Authorization', `Bearer ${authToken}`)
      .send({ name_en: 'Updated Pool', name_so: 'Barkada Cusub' })
      .expect(200);

    expect(response.body.name_en).toBe('Updated Pool');
    expect(response.body.name_so).toBe('Barkada Cusub');
  });

  it('should delete a facility', async () => {
    const facility = await Facility.create({
      name_en: 'Swimming Pool',
      name_so: 'Barkada Dabaal',
    });

    await request(app)
      .delete(`/api/facilities/${facility.id}`)
      .set('Authorization', `Bearer ${authToken}`)
      .expect(204);

    // Verify deletion
    const deleted = await Facility.findByPk(facility.id);
    expect(deleted).toBeNull();
  });

  it('should return 400 for duplicate name_en', async () => {
    await Facility.create({
      name_en: 'Swimming Pool',
      name_so: 'Barkada Dabaal',
    });

    const response = await request(app)
      .post('/api/facilities')
      .set('Authorization', `Bearer ${authToken}`)
      .send({ name_en: 'Swimming Pool', name_so: 'Duplicate' })
      .expect(400);

    expect(response.body.error).toBe('Facility with this name_en already exists');
  });

  it('should return 400 for missing required fields', async () => {
    const response = await request(app)
      .post('/api/facilities')
      .set('Authorization', `Bearer ${authToken}`)
      .send({ name_en: 'Test' })
      .expect(400);

    expect(response.body.error).toBe('name_en and name_so are required');
  });

  it('should sanitize inputs', async () => {
    const response = await request(app)
      .post('/api/facilities')
      .set('Authorization', `Bearer ${authToken}`)
      .send({ name_en: '  Swimming Pool  ', name_so: '  Barkada Dabaal  ' })
      .expect(201);

    expect(response.body.name_en).toBe('Swimming Pool');
    expect(response.body.name_so).toBe('Barkada Dabaal');
  });
});
