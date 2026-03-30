process.env.NODE_ENV = 'test';

const request = require('supertest');
const { sequelize, User, Listing, ListingRental, Coupon, Promotion, WithdrawBalance, CompanyEarning } = require('../src/models');

jest.mock('../src/middleware/authMiddleware', () => ({
  authenticateToken: (req, res, next) => {
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

jest.setTimeout(20000);

describe('Admin Reports API', () => {
  let app;
  let server;
  let owner;
  let renter;
  let listing;

  beforeAll(async () => {
    app = require('../src/app');
    await sequelize.sync({ force: true });

    owner = await User.create({
      name: 'Admin Owner',
      email: 'admin-owner@example.com',
      password: 'password123',
      phone: '+252611111111',
      role: 'admin',
    });

    renter = await User.create({
      name: 'Rental User',
      email: 'renter@example.com',
      password: 'password123',
      phone: '+252622222222',
      role: 'user',
    });

    listing = await Listing.create({
      user_id: owner.id,
      title: 'Ocean View Apartment',
      lat: 2.0469,
      lng: 45.3182,
      address: 'Mogadishu Coast',
      rent_price: 1200,
      rent_type: 'monthly',
      images: [],
      availability: '1',
    });

    server = app.listen(0);
  });

  afterAll(async () => {
    if (server) server.close();
    await sequelize.close();
    await mongoose.connection.close();
  });

  beforeEach(async () => {
    await ListingRental.destroy({ where: {} });
    await Coupon.destroy({ where: {} });
    await Promotion.destroy({ where: {} });
    await WithdrawBalance.destroy({ where: {} });
    await CompanyEarning.destroy({ where: {} });
  });

  it('returns coherent admin overview metrics and recent activity', async () => {
    const coupon = await Coupon.create({
      code: 'ADMIN10',
      type: 'percentage',
      value: 10,
      use_case: 'listing_rent',
      is_active: true,
    });

    await Promotion.create({
      listing_id: listing.id,
      subtotal: 100,
      discount: 10,
      total: 90,
      start_date: new Date(),
      end_date: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
      coupon_id: coupon.id,
      status: 'active',
    });

    await ListingRental.create({
      list_id: listing.id,
      renter_id: renter.id,
      start_date: new Date(),
      end_date: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
      rent_type: 'monthly',
      status: 'confirmed',
      subtotal: 1200,
      discount: 100,
      total: 1100,
      commission: 50,
      sellers_value: 1050,
      coupon_id: coupon.id,
      coupon_code: coupon.code,
    });

    await WithdrawBalance.create({
      user_id: owner.id,
      amount: 250,
      status: 'requested',
      before_balance: 900,
      after_balance: 650,
    });

    await CompanyEarning.create({
      date: new Date(),
      commission: 50,
      listing: 20,
      promotion: 30,
    });

    const response = await request(app).get('/api/admin/reports/overview').expect(200);

    expect(response.body.metrics.listings).toBeGreaterThanOrEqual(1);
    expect(response.body.metrics.users).toBeGreaterThanOrEqual(2);
    expect(response.body.metrics.rentals).toBe(1);
    expect(response.body.metrics.activeCoupons).toBe(1);
    expect(response.body.metrics.activePromotions).toBe(1);
    expect(response.body.metrics.pendingWithdrawals).toBe(1);
    expect(response.body.metrics.grossRevenue).toBe(1100);
    expect(response.body.finances.platformRevenue).toBe(100);
    expect(response.body.rentals.statuses.confirmed).toBe(1);
    expect(response.body.topListings).toHaveLength(1);
    expect(response.body.topListings[0].title).toBe('Ocean View Apartment');
    expect(response.body.rentals.recent).toHaveLength(1);
    expect(response.body.rentals.monthlyTrend.length).toBeGreaterThanOrEqual(3);
  });
});
