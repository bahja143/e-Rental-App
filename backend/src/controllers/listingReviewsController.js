const { ListingReview, User, Listing } = require('../models');
const { Op } = require('sequelize');

// Get all listing reviews with pagination, filtering, sorting
const getListingReviews = async (req, res) => {
  try {
    const {
      page = 1,
      limit = 10,
      sortBy = 'createdAt',
      sortOrder = 'DESC',
      listing_id,
      user_id,
      rating,
      rating_min,
      rating_max,
      date_from,
      date_to
    } = req.query;

    const offset = (page - 1) * limit;
    const where = {};

    // Apply filters
    if (listing_id) {
      where.listing_id = listing_id;
    }
    if (user_id) {
      where.user_id = user_id;
    }
    if (rating) {
      where.rating = rating;
    }
    if (rating_min || rating_max) {
      where.rating = {};
      if (rating_min) where.rating[Op.gte] = parseInt(rating_min);
      if (rating_max) where.rating[Op.lte] = parseInt(rating_max);
    }
    if (date_from || date_to) {
      where.createdAt = {};
      if (date_from) where.createdAt[Op.gte] = new Date(date_from);
      if (date_to) where.createdAt[Op.lte] = new Date(date_to);
    }

    const include = [{
      model: User,
      as: 'user',
      attributes: ['id', 'name', 'email', 'phone', 'profile_picture_url']
    }, {
      model: Listing,
      as: 'listing',
      attributes: ['id', 'title', 'address']
    }];

    const reviews = await ListingReview.findAndCountAll({
      where,
      limit: parseInt(limit),
      offset: parseInt(offset),
      order: [[sortBy, sortOrder.toUpperCase()]],
      include,
    });

    res.json({
      data: reviews.rows,
      pagination: {
        total: reviews.count,
        page: parseInt(page),
        limit: parseInt(limit),
        totalPages: Math.ceil(reviews.count / limit),
      },
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Get listing review by ID
const getListingReviewById = async (req, res) => {
  try {
    const include = [{
      model: User,
      as: 'user',
      attributes: ['id', 'name', 'email', 'phone', 'profile_picture_url']
    }, {
      model: Listing,
      as: 'listing',
      attributes: ['id', 'title', 'address']
    }];

    const review = await ListingReview.findByPk(req.params.id, {
      include,
    });
    if (!review) {
      return res.status(404).json({ error: 'Listing review not found' });
    }
    res.json(review);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Create a new listing review
const createListingReview = async (req, res) => {
  try {
    const {
      listing_id,
      user_id,
      rating,
      comment,
      images
    } = req.body;

    // Sanitize inputs
    const sanitizedComment = comment?.trim();

    // Validate required fields
    if (!listing_id || !user_id || rating === undefined || !sanitizedComment) {
      return res.status(400).json({ error: 'listing_id, user_id, rating, and comment are required' });
    }

    // Validate rating
    if (rating < 1 || rating > 5 || !Number.isInteger(rating)) {
      return res.status(400).json({ error: 'Rating must be an integer between 1 and 5' });
    }

    // Validate images array
    if (images && !Array.isArray(images)) {
      return res.status(400).json({ error: 'images must be an array' });
    }

    // Check if user has already reviewed this listing
    const existingReview = await ListingReview.findOne({
      where: { listing_id, user_id }
    });
    if (existingReview) {
      return res.status(400).json({ error: 'User has already reviewed this listing' });
    }

    const createData = {
      listing_id,
      user_id,
      rating: parseInt(rating),
      comment: sanitizedComment,
      images: images || [],
    };

    const review = await ListingReview.create(createData);
    res.status(201).json(review);
  } catch (error) {
    if (error.name === 'SequelizeForeignKeyConstraintError') {
      res.status(400).json({ error: 'Invalid listing_id or user_id - listing or user does not exist' });
    } else {
      res.status(400).json({ error: error.message });
    }
  }
};

// Update listing review
const updateListingReview = async (req, res) => {
  try {
    const {
      rating,
      comment,
      images
    } = req.body;

    // Sanitize inputs
    const sanitizedComment = comment?.trim();

    // Validate rating if provided
    if (rating !== undefined && (rating < 1 || rating > 5 || !Number.isInteger(rating))) {
      return res.status(400).json({ error: 'Rating must be an integer between 1 and 5' });
    }

    // Validate images array if provided
    if (images && !Array.isArray(images)) {
      return res.status(400).json({ error: 'images must be an array' });
    }

    const updateData = {};
    if (rating !== undefined) updateData.rating = parseInt(rating);
    if (sanitizedComment !== undefined) updateData.comment = sanitizedComment;
    if (images !== undefined) updateData.images = images;

    const [updated] = await ListingReview.update(updateData, {
      where: { id: req.params.id }
    });
    if (!updated) {
      return res.status(404).json({ error: 'Listing review not found' });
    }

    const include = [{
      model: User,
      as: 'user',
      attributes: ['id', 'name', 'email', 'phone', 'profile_picture_url']
    }, {
      model: Listing,
      as: 'listing',
      attributes: ['id', 'title', 'address']
    }];

    const updatedReview = await ListingReview.findByPk(req.params.id, {
      include,
    });
    res.json(updatedReview);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

// Delete listing review
const deleteListingReview = async (req, res) => {
  try {
    const deleted = await ListingReview.destroy({
      where: { id: req.params.id }
    });
    if (!deleted) {
      return res.status(404).json({ error: 'Listing review not found' });
    }
    res.status(204).send();
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

module.exports = {
  getListingReviews,
  getListingReviewById,
  createListingReview,
  updateListingReview,
  deleteListingReview,
};
