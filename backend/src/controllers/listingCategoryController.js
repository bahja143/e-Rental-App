const { ListingCategory, Listing, PropertyCategory } = require('../models');
const { Op } = require('sequelize');

// Get all listing categories with pagination, filtering, and sorting
const getListingCategories = async (req, res) => {
  try {
    const {
      page = 1,
      limit = 10,
      sortBy = 'createdAt',
      sortOrder = 'DESC',
      listing_id,
      property_category_id,
    } = req.query;

    // Input validation and sanitization
    const pageNum = parseInt(page);
    const limitNum = parseInt(limit);

    if (isNaN(pageNum) || pageNum < 1) {
      return res.status(400).json({ error: 'Invalid page number' });
    }
    if (isNaN(limitNum) || limitNum < 1 || limitNum > 100) {
      return res.status(400).json({ error: 'Invalid limit (1-100)' });
    }

    const offset = (pageNum - 1) * limitNum;
    const whereClause = {};

    // Filter by listing_id with validation
    if (listing_id) {
      const listingIdNum = parseInt(listing_id);
      if (isNaN(listingIdNum) || listingIdNum < 1) {
        return res.status(400).json({ error: 'Invalid listing_id' });
      }
      whereClause.listing_id = listingIdNum;
    }

    // Filter by property_category_id with validation
    if (property_category_id) {
      const categoryIdNum = parseInt(property_category_id);
      if (isNaN(categoryIdNum) || categoryIdNum < 1) {
        return res.status(400).json({ error: 'Invalid property_category_id' });
      }
      whereClause.property_category_id = categoryIdNum;
    }

    // Sorting with validation
    const validSortFields = ['id', 'listing_id', 'property_category_id', 'createdAt', 'updatedAt'];
    const sortField = validSortFields.includes(sortBy) ? sortBy : 'createdAt';
    const sortDirection = sortOrder.toUpperCase() === 'ASC' ? 'ASC' : 'DESC';

    const include = [
      {
        model: Listing,
        as: 'listing',
        attributes: ['id', 'title', 'address', 'sell_price', 'rent_price'],
      },
      {
        model: PropertyCategory,
        as: 'propertyCategory',
        attributes: ['id', 'name_en', 'name_so'],
      },
    ];

    const { count, rows: listingCategories } = await ListingCategory.findAndCountAll({
      where: whereClause,
      limit: limitNum,
      offset: offset,
      order: [[sortField, sortDirection]],
      include,
    });

    const totalPages = Math.ceil(count / limitNum);

    res.json({
      data: listingCategories,
      pagination: {
        currentPage: pageNum,
        totalPages,
        totalItems: count,
        itemsPerPage: limitNum,
        hasNextPage: pageNum < totalPages,
        hasPrevPage: pageNum > 1,
      },
    });
  } catch (error) {
    console.error('Error fetching listing categories:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// Get listing category by ID
const getListingCategoryById = async (req, res) => {
  try {
    const { id } = req.params;

    // Input validation
    const categoryId = parseInt(id);
    if (isNaN(categoryId) || categoryId < 1) {
      return res.status(400).json({ error: 'Invalid listing category ID' });
    }

    const listingCategory = await ListingCategory.findByPk(categoryId, {
      include: [
        {
          model: Listing,
          as: 'listing',
          attributes: ['id', 'title', 'address', 'sell_price', 'rent_price'],
        },
        {
          model: PropertyCategory,
          as: 'propertyCategory',
          attributes: ['id', 'name_en', 'name_so'],
        },
      ],
    });

    if (!listingCategory) {
      return res.status(404).json({ error: 'Listing category not found' });
    }

    res.json(listingCategory);
  } catch (error) {
    console.error('Error fetching listing category:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// Create a new listing category
const createListingCategory = async (req, res) => {
  try {
    const { listing_id, property_category_id } = req.body;

    // Input validation and sanitization
    const listingIdNum = parseInt(listing_id);
    const categoryIdNum = parseInt(property_category_id);

    if (isNaN(listingIdNum) || listingIdNum < 1) {
      return res.status(400).json({ error: 'Valid listing_id is required' });
    }
    if (isNaN(categoryIdNum) || categoryIdNum < 1) {
      return res.status(400).json({ error: 'Valid property_category_id is required' });
    }

    // Check if listing exists
    const listing = await Listing.findByPk(listingIdNum);
    if (!listing) {
      return res.status(400).json({ error: 'Listing not found' });
    }

    // Check if property category exists
    const propertyCategory = await PropertyCategory.findByPk(categoryIdNum);
    if (!propertyCategory) {
      return res.status(400).json({ error: 'Property category not found' });
    }

    // Check for duplicate listing-category pair
    const existing = await ListingCategory.findOne({
      where: {
        listing_id: listingIdNum,
        property_category_id: categoryIdNum,
      },
    });

    if (existing) {
      return res.status(409).json({ error: 'This listing-category association already exists' });
    }

    const listingCategory = await ListingCategory.create({
      listing_id: listingIdNum,
      property_category_id: categoryIdNum,
    });

    // Fetch the created record with associations
    const createdCategory = await ListingCategory.findByPk(listingCategory.id, {
      include: [
        {
          model: Listing,
          as: 'listing',
          attributes: ['id', 'title', 'address', 'sell_price', 'rent_price'],
        },
        {
          model: PropertyCategory,
          as: 'propertyCategory',
          attributes: ['id', 'name_en', 'name_so'],
        },
      ],
    });

    res.status(201).json({
      message: 'Listing category created successfully',
      listingCategory: createdCategory,
    });
  } catch (error) {
    console.error('Error creating listing category:', error);

    if (error.name === 'SequelizeUniqueConstraintError') {
      return res.status(409).json({ error: 'This listing-category association already exists' });
    }

    res.status(500).json({ error: 'Internal server error' });
  }
};

// Update listing category (only allows updating the association)
const updateListingCategory = async (req, res) => {
  try {
    const { id } = req.params;
    const { listing_id, property_category_id } = req.body;

    // Input validation
    const categoryId = parseInt(id);
    if (isNaN(categoryId) || categoryId < 1) {
      return res.status(400).json({ error: 'Invalid listing category ID' });
    }

    const listingCategory = await ListingCategory.findByPk(categoryId);
    if (!listingCategory) {
      return res.status(404).json({ error: 'Listing category not found' });
    }

    const updateData = {};

    // Validate and sanitize listing_id if provided
    if (listing_id !== undefined) {
      const listingIdNum = parseInt(listing_id);
      if (isNaN(listingIdNum) || listingIdNum < 1) {
        return res.status(400).json({ error: 'Invalid listing_id' });
      }

      // Check if listing exists
      const listing = await Listing.findByPk(listingIdNum);
      if (!listing) {
        return res.status(400).json({ error: 'Listing not found' });
      }

      updateData.listing_id = listingIdNum;
    }

    // Validate and sanitize property_category_id if provided
    if (property_category_id !== undefined) {
      const categoryIdNum = parseInt(property_category_id);
      if (isNaN(categoryIdNum) || categoryIdNum < 1) {
        return res.status(400).json({ error: 'Invalid property_category_id' });
      }

      // Check if property category exists
      const propertyCategory = await PropertyCategory.findByPk(categoryIdNum);
      if (!propertyCategory) {
        return res.status(400).json({ error: 'Property category not found' });
      }

      updateData.property_category_id = categoryIdNum;
    }

    // Check for conflicts if both are being updated
    if (updateData.listing_id && updateData.property_category_id) {
      const existing = await ListingCategory.findOne({
        where: {
          listing_id: updateData.listing_id,
          property_category_id: updateData.property_category_id,
          id: { [Op.ne]: categoryId }, // Exclude current record
        },
      });

      if (existing) {
        return res.status(409).json({ error: 'This listing-category association already exists' });
      }
    }

    await listingCategory.update(updateData);

    // Fetch updated record with associations
    const updatedCategory = await ListingCategory.findByPk(categoryId, {
      include: [
        {
          model: Listing,
          as: 'listing',
          attributes: ['id', 'title', 'address', 'sell_price', 'rent_price'],
        },
        {
          model: PropertyCategory,
          as: 'propertyCategory',
          attributes: ['id', 'name_en', 'name_so'],
        },
      ],
    });

    res.json({
      message: 'Listing category updated successfully',
      listingCategory: updatedCategory,
    });
  } catch (error) {
    console.error('Error updating listing category:', error);

    if (error.name === 'SequelizeUniqueConstraintError') {
      return res.status(409).json({ error: 'This listing-category association already exists' });
    }

    res.status(500).json({ error: 'Internal server error' });
  }
};

// Delete listing category
const deleteListingCategory = async (req, res) => {
  try {
    const { id } = req.params;

    // Input validation
    const categoryId = parseInt(id);
    if (isNaN(categoryId) || categoryId < 1) {
      return res.status(400).json({ error: 'Invalid listing category ID' });
    }

    const listingCategory = await ListingCategory.findByPk(categoryId);
    if (!listingCategory) {
      return res.status(404).json({ error: 'Listing category not found' });
    }

    await listingCategory.destroy();

    res.json({ message: 'Listing category deleted successfully' });
  } catch (error) {
    console.error('Error deleting listing category:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

module.exports = {
  getListingCategories,
  getListingCategoryById,
  createListingCategory,
  updateListingCategory,
  deleteListingCategory,
};
