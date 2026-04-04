/**
 * Public Listing Controller
 * Read-only endpoints for unauthenticated users to browse listings.
 */

const { Listing, User, ListingType, PropertyCategory, ListingFeature, PropertyFeatures, ListingFacility, Facility } = require('../models');
const { Op, Sequelize } = require('sequelize');
const rentalService = require('../services/rentalService');
const config = require('../config/config');
const { normalizeListingCollection, normalizeListingMediaFields } = require('../utils/listingSerializer');

// Reuse filters from main listing controller
const buildListingQuery = (query) => {
  const {
    page = 1,
    limit = 10,
    sortBy = 'createdAt',
    sortOrder = 'DESC',
    search,
    user_id,
    title,
    lat,
    lng,
    distance,
    rent_price_min,
    rent_price_max,
    sell_price_min,
    sell_price_max,
    rent_type,
    availability,
    include,
  } = query;

  const where = {};
  const offset = (parseInt(page) - 1) * parseInt(limit);

  if (search) {
    const term = String(search).trim();
    where[Op.or] = [
      { title: { [Op.like]: `%${term}%` } },
      { address: { [Op.like]: `%${term}%` } },
      { description: { [Op.like]: `%${term}%` } },
    ];
  } else {
    if (user_id) where.user_id = user_id;
    if (title) where.title = { [Op.like]: `%${title}%` };
    if (rent_type) where.rent_type = rent_type;
    if (availability) where.availability = availability;

    if (lat && lng && distance) {
      const latNum = parseFloat(lat);
      const lngNum = parseFloat(lng);
      const distanceInMeters = parseFloat(distance) * 1000;
      if (process.env.NODE_ENV === 'test') {
        where.lat = { [Op.between]: [latNum - 0.01, latNum + 0.01] };
        where.lng = { [Op.between]: [lngNum - 0.01, lngNum + 0.01] };
      } else if (config.isMySQL) {
        where[Op.and] = Sequelize.where(
          Sequelize.literal(`(6371000 * acos(LEAST(1, GREATEST(-1,
            cos(radians(\`lat\`)) * cos(radians(${latNum})) * cos(radians(${lngNum}) - radians(\`lng\`)) +
            sin(radians(\`lat\`)) * sin(radians(${latNum}))
          )))) <= ${distanceInMeters}`),
          true
        );
      } else {
        where[Op.and] = Sequelize.where(
          Sequelize.fn('ST_DWithin',
            Sequelize.col('location'),
            Sequelize.fn('ST_SetSRID', Sequelize.fn('ST_MakePoint', lngNum, latNum), 4326),
            distanceInMeters
          ),
          true
        );
      }
    }
  }

  // Price filters apply with or without text search (Figma search results + filter).
  if (rent_price_min || rent_price_max) {
    where.rent_price = {};
    if (rent_price_min) where.rent_price[Op.gte] = parseInt(rent_price_min, 10);
    if (rent_price_max) where.rent_price[Op.lte] = parseInt(rent_price_max, 10);
  }
  if (sell_price_min || sell_price_max) {
    where.sell_price = {};
    if (sell_price_min) where.sell_price[Op.gte] = parseInt(sell_price_min, 10);
    if (sell_price_max) where.sell_price[Op.lte] = parseInt(sell_price_max, 10);
  }

  const includeList = [
    {
      model: User,
      as: 'user',
      attributes: ['id', 'name', 'profile_picture_url'],
    },
  ];

  const includes = include ? String(include).split(',').map(s => s.trim()) : [];
  if (includes.includes('types')) {
    includeList.push({
      model: ListingType,
      as: 'listingTypes',
      attributes: ['id', 'name_en', 'name_so'],
      through: { attributes: [] },
    });
  }
  if (includes.includes('categories')) {
    includeList.push({
      model: PropertyCategory,
      as: 'propertyCategories',
      attributes: ['id', 'name_en', 'name_so'],
      through: { attributes: [] },
    });
  }
  if (includes.includes('features')) {
    includeList.push({
      model: ListingFeature,
      as: 'listingFeatures',
      attributes: ['id', 'value'],
      include: [{ model: PropertyFeatures, as: 'propertyFeature', attributes: ['id', 'name_en', 'name_so', 'type'] }],
    });
  }
  if (includes.includes('facilities')) {
    includeList.push({
      model: ListingFacility,
      as: 'listingFacilities',
      attributes: ['id', 'value'],
      include: [{ model: Facility, as: 'facility', attributes: ['id', 'name_en', 'name_so'] }],
    });
  }

  return { where, offset, limit: parseInt(limit) || 10, sortBy, sortOrder, includeList };
};

const getPublicListings = async (req, res) => {
  try {
    const { where, offset, limit, sortBy, sortOrder, includeList } = buildListingQuery(req.query);
    const validSort = ['id', 'title', 'rent_price', 'sell_price', 'createdAt'].includes(sortBy) ? sortBy : 'createdAt';
    const sortDir = sortOrder?.toUpperCase() === 'ASC' ? 'ASC' : 'DESC';

    const { count, rows } = await Listing.findAndCountAll({
      where,
      limit,
      offset,
      order: [[validSort, sortDir]],
      include: includeList,
      attributes: [
        'id', 'title', 'address', 'lat', 'lng', 'images', 'videos', 'rent_price', 'rent_type',
        'sell_price', 'description', 'availability', 'createdAt',
      ],
    });

    res.json({
      data: normalizeListingCollection(rows),
      pagination: {
        page: parseInt(req.query.page) || 1,
        limit,
        total: count,
        totalPages: Math.ceil(count / limit),
      },
    });
  } catch (error) {
    console.error('getPublicListings:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

const getPublicListingById = async (req, res) => {
  try {
    const includeList = [
      { model: User, as: 'user', attributes: ['id', 'name', 'profile_picture_url'] },
      { model: ListingType, as: 'listingTypes', attributes: ['id', 'name_en', 'name_so'], through: { attributes: [] } },
      { model: PropertyCategory, as: 'propertyCategories', attributes: ['id', 'name_en', 'name_so'], through: { attributes: [] } },
      { model: ListingFeature, as: 'listingFeatures', attributes: ['id', 'value'], include: [{ model: PropertyFeatures, as: 'propertyFeature', attributes: ['id', 'name_en', 'name_so', 'type'] }] },
      { model: ListingFacility, as: 'listingFacilities', attributes: ['id', 'value'], include: [{ model: Facility, as: 'facility', attributes: ['id', 'name_en', 'name_so'] }] },
    ];

    const listing = await Listing.findByPk(req.params.id, {
      include: includeList,
      attributes: ['id', 'title', 'address', 'lat', 'lng', 'images', 'videos', 'rent_price', 'rent_type', 'sell_price', 'description', 'availability', 'createdAt'],
    });

    if (!listing) {
      return res.status(404).json({ error: 'Listing not found' });
    }

    res.json(normalizeListingMediaFields(listing));
  } catch (error) {
    console.error('getPublicListingById:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

const getListingAvailability = async (req, res) => {
  try {
    const { id } = req.params;
    const { start_date, end_date } = req.query;

    const listingId = parseInt(id);
    if (isNaN(listingId)) {
      return res.status(400).json({ error: 'Invalid listing ID' });
    }

    if (!start_date || !end_date) {
      return res.status(400).json({ error: 'start_date and end_date query params are required' });
    }

    const startDate = new Date(start_date);
    const endDate = new Date(end_date);
    if (isNaN(startDate.getTime()) || isNaN(endDate.getTime())) {
      return res.status(400).json({ error: 'Invalid date format' });
    }
    if (endDate <= startDate) {
      return res.status(400).json({ error: 'end_date must be after start_date' });
    }

    const { available, conflictingRental } = await rentalService.checkListingAvailability(listingId, startDate, endDate);

    res.json({ available, conflictingRental });
  } catch (error) {
    console.error('getListingAvailability:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

const getRentalQuote = async (req, res) => {
  try {
    const { id } = req.params;
    const { start_date, end_date, rent_type, coupon_code, coupon_id } = req.query;

    const listingId = parseInt(id);
    if (isNaN(listingId)) {
      return res.status(400).json({ error: 'Invalid listing ID' });
    }

    if (!start_date || !end_date) {
      return res.status(400).json({ error: 'start_date and end_date query params are required' });
    }

    const startDate = new Date(start_date);
    const endDate = new Date(end_date);
    if (isNaN(startDate.getTime()) || isNaN(endDate.getTime())) {
      return res.status(400).json({ error: 'Invalid date format' });
    }
    if (endDate <= startDate) {
      return res.status(400).json({ error: 'end_date must be after start_date' });
    }

    const quote = await rentalService.getRentalQuote(
      listingId,
      startDate,
      endDate,
      rent_type || 'daily',
      coupon_id ? parseInt(coupon_id) : null,
      coupon_code || null
    );

    if (quote.error) {
      return res.status(400).json({ ...quote });
    }

    res.json(quote);
  } catch (error) {
    console.error('getRentalQuote:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

module.exports = {
  getPublicListings,
  getPublicListingById,
  getListingAvailability,
  getRentalQuote,
};
