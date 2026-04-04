const { Listing, User, ListingType, PropertyCategory, ListingFeature, PropertyFeatures, ListingFacility, Facility, Favourite, sequelize } = require('../models');
const { Op, Sequelize } = require('sequelize');
const config = require('../config/config');
const { normalizeListingCollection, normalizeListingMediaFields } = require('../utils/listingSerializer');

// Get all listings with pagination, filtering, sorting
const getListings = async (req, res) => {
  try {
    const {
      page = 1,
      limit = 10,
      sortBy = 'createdAt',
      sortOrder = 'DESC',
      user_id,
      title,
      lat,
      lng,
      distance, // Distance in kilometers for near search
      sell_price_min,
      sell_price_max,
      rent_price_min,
      rent_price_max,
      rent_type,
      availability
    } = req.query;

    const offset = (page - 1) * limit;
    const where = {};

    // Handle general search parameter
    if (req.query.search) {
      const searchTerm = req.query.search;
      where[Op.or] = [
        { title: { [Op.like]: `%${searchTerm}%` } },
        { address: { [Op.like]: `%${searchTerm}%` } },
        { description: { [Op.like]: `%${searchTerm}%` } }
      ];
    } else {
      // Apply individual filters
      if (user_id) {
        where.user_id = user_id;
      }
      if (title) {
        where.title = { [Op.like]: `%${title}%` };
      }
      if (lat && lng && distance) {
        const latNum = parseFloat(lat);
        const lngNum = parseFloat(lng);
        const distanceInMeters = parseFloat(distance) * 1000;
        if (process.env.NODE_ENV === 'test') {
          where.lat = { [Op.between]: [latNum - 0.01, latNum + 0.01] };
          where.lng = { [Op.between]: [lngNum - 0.01, lngNum + 0.01] };
        } else if (config.isMySQL) {
          // Haversine formula for MySQL (distance in meters)
          where[Op.and] = Sequelize.where(
            Sequelize.literal(`(6371000 * acos(LEAST(1, GREATEST(-1,
              cos(radians(\`lat\`)) * cos(radians(${latNum})) * cos(radians(${lngNum}) - radians(\`lng\`)) +
              sin(radians(\`lat\`)) * sin(radians(${latNum}))
            )))) <= ${distanceInMeters}`),
            true
          );
        } else {
          // PostGIS
          where[Op.and] = Sequelize.where(
            Sequelize.fn('ST_DWithin',
              Sequelize.col('location'),
              Sequelize.fn('ST_SetSRID', Sequelize.fn('ST_MakePoint', lngNum, latNum), 4326),
              distanceInMeters
            ),
            true
          );
        }
      } else if (lat && lng) {
        // Fallback to lat/lng range if no distance search
        where.lat = lat;
        where.lng = lng;
      }
      if (sell_price_min || sell_price_max) {
        where.sell_price = {};
        if (sell_price_min) where.sell_price[Op.gte] = parseInt(sell_price_min);
        if (sell_price_max) where.sell_price[Op.lte] = parseInt(sell_price_max);
      }
      if (rent_price_min || rent_price_max) {
        where.rent_price = {};
        if (rent_price_min) where.rent_price[Op.gte] = parseInt(rent_price_min);
        if (rent_price_max) where.rent_price[Op.lte] = parseInt(rent_price_max);
      }
      if (rent_type) {
        where.rent_type = rent_type;
      }
      if (availability) {
        where.availability = availability;
      }
    }

    const include = [{
      model: User,
      as: 'user',
      attributes: ['id', 'name', 'email', 'phone', 'profile_picture_url']
    }];

    // Include listing types if requested
    if (req.query.include && req.query.include.includes('types')) {
      include.push({
        model: ListingType,
        as: 'listingTypes',
        attributes: ['id', 'name_en', 'name_so'],
        through: { attributes: [] } // Exclude junction table attributes
      });
    }

    // Include property categories if requested
    if (req.query.include && req.query.include.includes('categories')) {
      include.push({
        model: PropertyCategory,
        as: 'propertyCategories',
        attributes: ['id', 'name_en', 'name_so'],
        through: { attributes: [] } // Exclude junction table attributes
      });
    }

    // Include listing features if requested
    if (req.query.include && req.query.include.includes('features')) {
      include.push({
        model: ListingFeature,
        as: 'listingFeatures',
        attributes: ['id', 'value'],
        include: [{
          model: PropertyFeatures,
          as: 'propertyFeature',
          attributes: ['id', 'name_en', 'name_so', 'type']
        }]
      });
    }

    // Include listing facilities if requested
    if (req.query.include && req.query.include.includes('facilities')) {
      include.push({
        model: ListingFacility,
        as: 'listingFacilities',
        attributes: ['id', 'value'],
        include: [{
          model: Facility,
          as: 'facility',
          attributes: ['id', 'name_en', 'name_so']
        }]
      });
    }

    // Include favourites if requested
    if (req.query.include && req.query.include.includes('favourites')) {
      include.push({
        model: Favourite,
        as: 'favourites',
        attributes: ['user_id', 'add_date'],
        include: [{
          model: User,
          as: 'user',
          attributes: ['id', 'name', 'email']
        }]
      });
    }

    const listings = await Listing.findAndCountAll({
      where,
      limit: parseInt(limit),
      offset: parseInt(offset),
      order: [[sortBy, sortOrder.toUpperCase()]],
      include,
    });

    res.json({
      data: normalizeListingCollection(listings.rows),
      pagination: {
        total: listings.count,
        page: parseInt(page),
        limit: parseInt(limit),
        totalPages: Math.ceil(listings.count / limit),
      },
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Get listing by ID
const getListingById = async (req, res) => {
  try {
    const include = [{
      model: User,
      as: 'user',
      attributes: ['id', 'name', 'email', 'phone', 'profile_picture_url']
    }];

    // Include listing types if requested
    if (req.query.include && req.query.include.includes('types')) {
      include.push({
        model: ListingType,
        as: 'listingTypes',
        attributes: ['id', 'name_en', 'name_so'],
        through: { attributes: [] } // Exclude junction table attributes
      });
    }

    // Include property categories if requested
    if (req.query.include && req.query.include.includes('categories')) {
      include.push({
        model: PropertyCategory,
        as: 'propertyCategories',
        attributes: ['id', 'name_en', 'name_so'],
        through: { attributes: [] } // Exclude junction table attributes
      });
    }

    // Include listing features if requested
    if (req.query.include && req.query.include.includes('features')) {
      include.push({
        model: ListingFeature,
        as: 'listingFeatures',
        attributes: ['id', 'value'],
        include: [{
          model: PropertyFeatures,
          as: 'propertyFeature',
          attributes: ['id', 'name_en', 'name_so', 'type']
        }]
      });
    }

    // Include listing facilities if requested
    if (req.query.include && req.query.include.includes('facilities')) {
      include.push({
        model: ListingFacility,
        as: 'listingFacilities',
        attributes: ['id', 'value'],
        include: [{
          model: Facility,
          as: 'facility',
          attributes: ['id', 'name_en', 'name_so']
        }]
      });
    }

    // Include favourites if requested
    if (req.query.include && req.query.include.includes('favourites')) {
      include.push({
        model: Favourite,
        as: 'favourites',
        attributes: ['user_id', 'add_date'],
        include: [{
          model: User,
          as: 'user',
          attributes: ['id', 'name', 'email']
        }]
      });
    }

    const listing = await Listing.findByPk(req.params.id, {
      include,
    });
    if (!listing) {
      return res.status(404).json({ error: 'Listing not found' });
    }
    res.json(normalizeListingMediaFields(listing));
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Create a new listing (user_id from auth; body user_id ignored for security)
const createListing = async (req, res) => {
  try {
    const userId = req.user?.userId ?? req.user?.id;
    if (!userId) {
      return res.status(401).json({ error: 'Authentication required' });
    }

    const {
      title,
      lat,
      lng,
      address,
      images,
      videos,
      sell_price,
      rent_price,
      rent_type,
      description,
      availability
    } = req.body;

    // Sanitize inputs
    const sanitizedTitle = title?.trim();
    const sanitizedAddress = address?.trim();
    const sanitizedDescription = description?.trim();
    const hasLat = lat !== undefined && lat !== null && `${lat}`.trim() !== '';
    const hasLng = lng !== undefined && lng !== null && `${lng}`.trim() !== '';

    // Validate required fields
    if (!sanitizedTitle || !hasLat || !hasLng || !sanitizedAddress) {
      return res.status(400).json({ error: 'title, lat, lng, and address are required' });
    }

    const latNum = Number.parseFloat(lat);
    const lngNum = Number.parseFloat(lng);

    if (!Number.isFinite(latNum) || !Number.isFinite(lngNum)) {
      return res.status(400).json({ error: 'lat and lng must be valid numbers' });
    }

    // Validate coordinates
    if (latNum < -90 || latNum > 90 || lngNum < -180 || lngNum > 180) {
      return res.status(400).json({ error: 'Invalid latitude or longitude values' });
    }

    // Validate prices
    if (sell_price !== undefined && sell_price < 0) {
      return res.status(400).json({ error: 'sell_price must be non-negative' });
    }
    if (rent_price !== undefined && rent_price < 0) {
      return res.status(400).json({ error: 'rent_price must be non-negative' });
    }

    // Validate images array
    if (images && !Array.isArray(images)) {
      return res.status(400).json({ error: 'images must be an array' });
    }
    if (videos && !Array.isArray(videos)) {
      return res.status(400).json({ error: 'videos must be an array' });
    }

    const createData = {
      user_id: userId,
      title: sanitizedTitle,
      lat: latNum,
      lng: lngNum,
      address: sanitizedAddress,
      images: images || [],
      videos: videos || [],
      sell_price: sell_price ? parseInt(sell_price) : null,
      rent_price: rent_price ? parseInt(rent_price) : null,
      rent_type,
      description: sanitizedDescription,
      availability: availability || '1',
    };

    // Location will be set by model hooks

    const listing = await Listing.create(createData);
    res.status(201).json(normalizeListingMediaFields(listing));
  } catch (error) {
    if (error.name === 'SequelizeForeignKeyConstraintError') {
      res.status(400).json({ error: 'Invalid user_id - user does not exist' });
    } else {
      res.status(400).json({ error: error.message });
    }
  }
};

// Update listing
const updateListing = async (req, res) => {
  try {
    const {
      title,
      lat,
      lng,
      address,
      images,
      videos,
      sell_price,
      rent_price,
      rent_type,
      description,
      availability
    } = req.body;

    // Sanitize inputs
    const sanitizedTitle = title?.trim();
    const sanitizedAddress = address?.trim();
    const sanitizedDescription = description?.trim();
    const hasLat = lat !== undefined && lat !== null && `${lat}`.trim() !== '';
    const hasLng = lng !== undefined && lng !== null && `${lng}`.trim() !== '';

    if (hasLat !== hasLng) {
      return res.status(400).json({ error: 'Both lat and lng must be provided together' });
    }

    let latNum;
    let lngNum;
    if (hasLat && hasLng) {
      latNum = Number.parseFloat(lat);
      lngNum = Number.parseFloat(lng);
      if (!Number.isFinite(latNum) || !Number.isFinite(lngNum)) {
        return res.status(400).json({ error: 'lat and lng must be valid numbers' });
      }
    }

    // Validate coordinates if provided
    if (latNum !== undefined && (latNum < -90 || latNum > 90)) {
      return res.status(400).json({ error: 'Invalid latitude value' });
    }
    if (lngNum !== undefined && (lngNum < -180 || lngNum > 180)) {
      return res.status(400).json({ error: 'Invalid longitude value' });
    }

    // Validate prices if provided
    if (sell_price !== undefined && sell_price < 0) {
      return res.status(400).json({ error: 'sell_price must be non-negative' });
    }
    if (rent_price !== undefined && rent_price < 0) {
      return res.status(400).json({ error: 'rent_price must be non-negative' });
    }

    // Validate images array if provided
    if (images && !Array.isArray(images)) {
      return res.status(400).json({ error: 'images must be an array' });
    }
    if (videos && !Array.isArray(videos)) {
      return res.status(400).json({ error: 'videos must be an array' });
    }

    const updateData = {};
    if (sanitizedTitle) updateData.title = sanitizedTitle;
    // Location will be updated by model hooks if lat/lng change
    if (latNum !== undefined) updateData.lat = latNum;
    if (lngNum !== undefined) updateData.lng = lngNum;
    if (sanitizedAddress) updateData.address = sanitizedAddress;
    if (images !== undefined) updateData.images = images;
    if (videos !== undefined) updateData.videos = videos;
    if (sell_price !== undefined) updateData.sell_price = sell_price ? parseInt(sell_price) : null;
    if (rent_price !== undefined) updateData.rent_price = rent_price ? parseInt(rent_price) : null;
    if (rent_type !== undefined) updateData.rent_type = rent_type;
    if (sanitizedDescription !== undefined) updateData.description = sanitizedDescription;
    if (availability) updateData.availability = availability;

    const [updated] = await Listing.update(updateData, {
      where: { id: req.params.id }
    });
    if (!updated) {
      return res.status(404).json({ error: 'Listing not found' });
    }
    const include = [{
      model: User,
      as: 'user',
      attributes: ['id', 'name', 'email', 'phone', 'profile_picture_url']
    }];

    // Include listing types if requested
    if (req.query.include && req.query.include.includes('types')) {
      include.push({
        model: ListingType,
        as: 'listingTypes',
        attributes: ['id', 'name_en', 'name_so'],
        through: { attributes: [] } // Exclude junction table attributes
      });
    }

    // Include property categories if requested
    if (req.query.include && req.query.include.includes('categories')) {
      include.push({
        model: PropertyCategory,
        as: 'propertyCategories',
        attributes: ['id', 'name_en', 'name_so'],
        through: { attributes: [] } // Exclude junction table attributes
      });
    }

    // Include listing features if requested
    if (req.query.include && req.query.include.includes('features')) {
      include.push({
        model: ListingFeature,
        as: 'listingFeatures',
        attributes: ['id', 'value'],
        include: [{
          model: PropertyFeatures,
          as: 'propertyFeature',
          attributes: ['id', 'name_en', 'name_so', 'type']
        }]
      });
    }

    // Include listing facilities if requested
    if (req.query.include && req.query.include.includes('facilities')) {
      include.push({
        model: ListingFacility,
        as: 'listingFacilities',
        attributes: ['id', 'value'],
        include: [{
          model: Facility,
          as: 'facility',
          attributes: ['id', 'name_en', 'name_so']
        }]
      });
    }

    const updatedListing = await Listing.findByPk(req.params.id, {
      include,
    });
    res.json(normalizeListingMediaFields(updatedListing));
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

// Delete listing
const deleteListing = async (req, res) => {
  try {
    const deleted = await Listing.destroy({
      where: { id: req.params.id }
    });
    if (!deleted) {
      return res.status(404).json({ error: 'Listing not found' });
    }
    res.status(204).send();
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

module.exports = {
  getListings,
  getListingById,
  createListing,
  updateListing,
  deleteListing,
};
