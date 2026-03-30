const { Listing, ListingRental, User, Coupon, Promotion, CompanyEarning, WithdrawBalance } = require('../models');

const requireAdmin = (req, res, next) => {
  const role = `${req.user?.role ?? ''}`.toLowerCase();
  if (role !== 'admin') {
    return res.status(403).json({ error: 'Admin access required' });
  }
  return next();
};

const toAmount = (value) => {
  const parsed = Number(value ?? 0);
  return Number.isFinite(parsed) ? parsed : 0;
};

const monthKey = (value) => {
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return null;
  return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}`;
};

const getAdminOverview = async (req, res) => {
  try {
    const months = Math.min(Math.max(parseInt(req.query.months, 10) || 6, 3), 24);
    const recentLimit = Math.min(Math.max(parseInt(req.query.recentLimit, 10) || 8, 3), 20);

    const [
      listingsCount,
      usersCount,
      rentalsCount,
      activeCouponsCount,
      activePromotionsCount,
      pendingWithdrawalsCount,
      earningsRows,
      rentalRows,
      recentRentals,
    ] = await Promise.all([
      Listing.count(),
      User.count(),
      ListingRental.count(),
      Coupon.count({ where: { is_active: true } }),
      Promotion.count({ where: { status: 'active' } }),
      WithdrawBalance.count({ where: { status: 'requested' } }),
      CompanyEarning.findAll({
        attributes: ['commission', 'listing', 'promotion', 'date'],
        order: [['date', 'DESC']],
        raw: true,
      }),
      ListingRental.findAll({
        attributes: ['id', 'list_id', 'status', 'total', 'subtotal', 'commission', 'createdAt'],
        include: [
          {
            model: Listing,
            as: 'listing',
            attributes: ['id', 'title'],
          },
          {
            model: User,
            as: 'renter',
            attributes: ['id', 'name', 'email'],
          },
        ],
        order: [['createdAt', 'DESC']],
      }),
      ListingRental.findAll({
        attributes: ['id', 'status', 'start_date', 'end_date', 'total', 'subtotal', 'createdAt'],
        include: [
          {
            model: Listing,
            as: 'listing',
            attributes: ['id', 'title'],
          },
          {
            model: User,
            as: 'renter',
            attributes: ['id', 'name', 'email'],
          },
        ],
        order: [['createdAt', 'DESC']],
        limit: recentLimit,
      }),
    ]);

    const statusCounts = {
      pending: 0,
      confirmed: 0,
      completed: 0,
      cancelled: 0,
    };
    const monthlyMap = new Map();
    const listingMap = new Map();

    const now = new Date();
    for (let index = months - 1; index >= 0; index -= 1) {
      const seed = new Date(now.getFullYear(), now.getMonth() - index, 1);
      const key = `${seed.getFullYear()}-${String(seed.getMonth() + 1).padStart(2, '0')}`;
      monthlyMap.set(key, {
        month: key,
        rentals: 0,
        revenue: 0,
      });
    }

    rentalRows.forEach((row) => {
      const status = `${row.status ?? ''}`.toLowerCase();
      if (Object.prototype.hasOwnProperty.call(statusCounts, status)) {
        statusCounts[status] += 1;
      }

      const total = toAmount(row.total ?? row.subtotal);
      const key = monthKey(row.createdAt);
      if (key && monthlyMap.has(key)) {
        const current = monthlyMap.get(key);
        current.rentals += 1;
        current.revenue += total;
      }

      const listingId = `${row.listing?.id ?? row.list_id ?? ''}`;
      const listingTitle = row.listing?.title || (listingId ? `Listing #${listingId}` : 'Unknown Listing');
      if (!listingId) return;

      const currentListing = listingMap.get(listingId) ?? {
        listingId,
        title: listingTitle,
        rentals: 0,
        revenue: 0,
      };
      currentListing.rentals += 1;
      currentListing.revenue += total;
      listingMap.set(listingId, currentListing);
    });

    const earnings = earningsRows.reduce(
      (acc, row) => {
        acc.commission += toAmount(row.commission);
        acc.listing += toAmount(row.listing);
        acc.promotion += toAmount(row.promotion);
        return acc;
      },
      { commission: 0, listing: 0, promotion: 0 }
    );

    const grossRevenue = rentalRows.reduce((sum, row) => sum + toAmount(row.total ?? row.subtotal), 0);
    const platformRevenue = earnings.commission + earnings.listing + earnings.promotion;

    res.json({
      metrics: {
        listings: listingsCount,
        users: usersCount,
        rentals: rentalsCount,
        activeCoupons: activeCouponsCount,
        activePromotions: activePromotionsCount,
        pendingWithdrawals: pendingWithdrawalsCount,
        grossRevenue,
        platformRevenue,
      },
      rentals: {
        statuses: statusCounts,
        recent: recentRentals.map((row) => ({
          id: row.id,
          status: row.status,
          start_date: row.start_date,
          end_date: row.end_date,
          total: toAmount(row.total ?? row.subtotal),
          createdAt: row.createdAt,
          listing: row.listing
            ? {
                id: row.listing.id,
                title: row.listing.title,
              }
            : null,
          renter: row.renter
            ? {
                id: row.renter.id,
                name: row.renter.name,
                email: row.renter.email,
              }
            : null,
        })),
        monthlyTrend: [...monthlyMap.values()],
      },
      finances: {
        commission: earnings.commission,
        listing: earnings.listing,
        promotion: earnings.promotion,
        platformRevenue,
      },
      topListings: [...listingMap.values()].sort((a, b) => b.revenue - a.revenue).slice(0, 5),
    });
  } catch (error) {
    console.error('Admin overview error:', error);
    res.status(500).json({ error: 'Failed to load admin overview' });
  }
};

module.exports = {
  requireAdmin,
  getAdminOverview,
};
