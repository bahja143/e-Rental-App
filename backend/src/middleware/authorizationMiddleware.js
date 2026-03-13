/**
 * Authorization Middleware
 * Ensures users can only modify their own resources (listings, rentals).
 */

const { Listing, ListingRental, User } = require('../models');

/**
 * Require that the user owns the listing (used for update/delete listing).
 * Expects req.params.id or req.params.listingId to be the listing ID.
 */
const requireListingOwner = async (req, res, next) => {
  try {
    const listingId = req.params.id || req.params.listingId;
    const userId = req.user?.userId ?? req.user?.id;

    if (!userId) {
      return res.status(401).json({ error: 'Authentication required' });
    }

    // Admin can bypass
    if (req.user?.role === 'admin') {
      return next();
    }

    const listing = await Listing.findByPk(listingId);
    if (!listing) {
      return res.status(404).json({ error: 'Listing not found' });
    }

    if (parseInt(listing.user_id) !== parseInt(userId)) {
      return res.status(403).json({ error: 'You do not have permission to modify this listing' });
    }

    req.listing = listing;
    next();
  } catch (error) {
    console.error('requireListingOwner error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

/**
 * Require that the user is the listing owner OR the renter (for rental operations).
 * Expects req.params.id to be the rental ID.
 */
const requireRentalParticipant = async (req, res, next) => {
  try {
    const rentalId = req.params.id;
    const userId = req.user?.userId ?? req.user?.id;

    if (!userId) {
      return res.status(401).json({ error: 'Authentication required' });
    }

    if (req.user?.role === 'admin') {
      return next();
    }

    const rental = await ListingRental.findByPk(rentalId, {
      include: [{ model: Listing, as: 'listing', attributes: ['id', 'user_id'] }],
    });

    if (!rental) {
      return res.status(404).json({ error: 'Rental not found' });
    }

    const isOwner = parseInt(rental.listing?.user_id) === parseInt(userId);
    const isRenter = parseInt(rental.renter_id) === parseInt(userId);

    if (!isOwner && !isRenter) {
      return res.status(403).json({ error: 'You do not have permission to modify this rental' });
    }

    req.rental = rental;
    req.isRentalOwner = isOwner;
    req.isRenter = isRenter;
    next();
  } catch (error) {
    console.error('requireRentalParticipant error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

/**
 * Require that the user is the listing owner (for confirming/cancelling rentals).
 * Only owners can confirm or cancel pending rentals.
 */
const requireRentalOwner = async (req, res, next) => {
  try {
    const rentalId = req.params.id;
    const userId = req.user?.userId ?? req.user?.id;

    if (!userId) {
      return res.status(401).json({ error: 'Authentication required' });
    }

    if (req.user?.role === 'admin') {
      return next();
    }

    const rental = await ListingRental.findByPk(rentalId, {
      include: [{ model: Listing, as: 'listing', attributes: ['id', 'user_id'] }],
    });

    if (!rental) {
      return res.status(404).json({ error: 'Rental not found' });
    }

    const isOwner = parseInt(rental.listing?.user_id) === parseInt(userId);
    if (!isOwner) {
      return res.status(403).json({ error: 'Only the listing owner can perform this action' });
    }

    req.rental = rental;
    next();
  } catch (error) {
    console.error('requireRentalOwner error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

module.exports = {
  requireListingOwner,
  requireRentalParticipant,
  requireRentalOwner,
};
