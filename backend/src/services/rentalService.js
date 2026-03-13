/**
 * Rental Service
 * Handles availability checks, price calculation, and coupon validation for rentals.
 */

const { ListingRental, Listing, Coupon } = require('../models');
const { Op } = require('sequelize');

/** Statuses that block availability (listing is occupied) */
const BLOCKING_STATUSES = ['pending', 'confirmed'];

/**
 * Check if a listing is available for the given date range.
 * Excludes overlapping rentals with pending or confirmed status.
 * @param {number} listingId - Listing ID
 * @param {Date} startDate - Requested start date
 * @param {Date} endDate - Requested end date
 * @param {number} [excludeRentalId] - Optional rental ID to exclude (for updates)
 * @returns {Promise<{ available: boolean, conflictingRental?: object }>}
 */
async function checkListingAvailability(listingId, startDate, endDate, excludeRentalId = null) {
  const where = {
    list_id: listingId,
    status: { [Op.in]: BLOCKING_STATUSES },
    [Op.or]: [
      // New range overlaps: existing start before our end AND existing end after our start
      {
        start_date: { [Op.lt]: endDate },
        end_date: { [Op.gt]: startDate },
      },
    ],
  };

  if (excludeRentalId) {
    where.id = { [Op.ne]: excludeRentalId };
  }

  const conflictingRental = await ListingRental.findOne({
    where,
    attributes: ['id', 'start_date', 'end_date', 'status'],
  });

  return {
    available: !conflictingRental,
    conflictingRental: conflictingRental ? conflictingRental.toJSON() : null,
  };
}

/**
 * Calculate rental subtotal from listing price and date range.
 * @param {number} rentPrice - Price per unit (daily/monthly/yearly)
 * @param {string} rentType - 'daily' | 'monthly' | 'yearly'
 * @param {Date} startDate - Rental start
 * @param {Date} endDate - Rental end
 * @returns {number} Subtotal in same currency as rentPrice
 */
function calculateRentalSubtotal(rentPrice, rentType, startDate, endDate) {
  const price = parseFloat(rentPrice) || 0;
  if (price <= 0) return 0;

  const start = new Date(startDate);
  const end = new Date(endDate);
  const diffMs = end - start;
  const diffDays = Math.ceil(diffMs / (1000 * 60 * 60 * 24));

  switch (rentType) {
    case 'daily':
      return Math.round(price * Math.max(1, diffDays) * 100) / 100;
    case 'monthly':
      return Math.round(price * Math.max(1, Math.ceil(diffDays / 30)) * 100) / 100;
    case 'yearly':
      return Math.round(price * Math.max(1, Math.ceil(diffDays / 365)) * 100) / 100;
    default:
      return Math.round(price * Math.max(1, diffDays) * 100) / 100;
  }
}

/**
 * Check if user has exceeded per_user_limit for a coupon (for rentals).
 * @param {number} couponId
 * @param {number} userId
 * @returns {Promise<boolean>} - true if user can still use
 */
async function checkCouponPerUserLimit(couponId, userId) {
  const count = await ListingRental.count({
    where: { coupon_id: couponId, renter_id: userId },
  });
  const coupon = await Coupon.findByPk(couponId);
  if (!coupon || coupon.per_user_limit === null) return true;
  return count < coupon.per_user_limit;
}

/**
 * Validate coupon and compute discount for a rental.
 * @param {object} coupon - Coupon model instance
 * @param {number} subtotal - Purchase amount before discount
 * @param {string} useCase - Must be 'listing_rent'
 * @param {number} [userId] - For per_user_limit check
 * @returns {Promise<{ valid: boolean, discount: number, error?: string }>}
 */
async function validateAndApplyCoupon(coupon, subtotal, useCase = 'listing_rent', userId = null) {
  if (!coupon) {
    return { valid: false, discount: 0, error: 'Coupon not found' };
  }

  if (coupon.use_case !== useCase) {
    return { valid: false, discount: 0, error: 'Coupon is not valid for rentals' };
  }

  if (!coupon.isValid()) {
    return { valid: false, discount: 0, error: 'Coupon is expired or has reached usage limit' };
  }

  if (!coupon.canApplyToPurchase(subtotal)) {
    return {
      valid: false,
      discount: 0,
      error: `Minimum purchase of ${coupon.min_purchase} required for this coupon`,
    };
  }

  if (userId) {
    const canUse = await checkCouponPerUserLimit(coupon.id, userId);
    if (!canUse) {
      return { valid: false, discount: 0, error: 'You have reached the usage limit for this coupon' };
    }
  }

  const value = parseFloat(coupon.value);
  let discount = 0;

  if (coupon.type === 'percentage') {
    discount = Math.round((subtotal * value) / 100 * 100) / 100;
  } else {
    discount = Math.min(value, subtotal);
  }

  return { valid: true, discount };
}

/**
 * Resolve coupon by ID or code.
 * @param {number|null} couponId
 * @param {string|null} couponCode
 * @returns {Promise<Coupon|null>}
 */
async function resolveCoupon(couponId, couponCode) {
  if (couponId) {
    return Coupon.findByPk(couponId);
  }
  if (couponCode && typeof couponCode === 'string') {
    const code = couponCode.trim().toUpperCase();
    return Coupon.findOne({ where: { code } });
  }
  return null;
}

/**
 * Get a rental price quote (subtotal, discount, total) without creating a rental.
 * @param {number} listingId
 * @param {Date} startDate
 * @param {Date} endDate
 * @param {string} rentType
 * @param {number|null} couponId
 * @param {string|null} couponCode
 * @returns {Promise<{ subtotal, discount, total, coupon?: object, error?: string }>}
 */
async function getRentalQuote(listingId, startDate, endDate, rentType, couponId = null, couponCode = null) {
  const listing = await Listing.findByPk(listingId);
  if (!listing) {
    return { subtotal: 0, discount: 0, total: 0, error: 'Listing not found' };
  }

  const rentPrice = listing.rent_price;
  if (!rentPrice || rentPrice <= 0) {
    return { subtotal: 0, discount: 0, total: 0, error: 'Listing has no rent price configured' };
  }

  const listingRentType = listing.rent_type || rentType || 'daily';
  const subtotal = calculateRentalSubtotal(rentPrice, listingRentType, startDate, endDate);

  let discount = 0;
  let coupon = null;

  if (couponId || couponCode) {
    coupon = await resolveCoupon(couponId, couponCode);
    const result = await validateAndApplyCoupon(coupon, subtotal, 'listing_rent');
    if (result.valid) {
      discount = result.discount;
    } else {
      return {
        subtotal,
        discount: 0,
        total: subtotal,
        error: result.error,
      };
    }
  }

  const total = Math.round((subtotal - discount) * 100) / 100;

  return {
    subtotal,
    discount,
    total,
    coupon: coupon ? { id: coupon.id, code: coupon.code } : undefined,
  };
}

module.exports = {
  checkListingAvailability,
  calculateRentalSubtotal,
  validateAndApplyCoupon,
  checkCouponPerUserLimit,
  resolveCoupon,
  getRentalQuote,
};
