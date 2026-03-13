const { CompanyEarning } = require('../models');
const { Op } = require('sequelize');

// Get all company earnings with pagination, filtering, and sorting
const getCompanyEarnings = async (req, res) => {
  try {
    const {
      page = 1,
      limit = 10,
      startDate,
      endDate,
      sortBy = 'date',
      sortOrder = 'DESC',
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

    // Date range filter with validation
    if (startDate || endDate) {
      whereClause.date = {};
      if (startDate) {
        const start = new Date(startDate);
        if (isNaN(start.getTime())) {
          return res.status(400).json({ error: 'Invalid startDate format' });
        }
        whereClause.date[Op.gte] = startDate;
      }
      if (endDate) {
        const end = new Date(endDate);
        if (isNaN(end.getTime())) {
          return res.status(400).json({ error: 'Invalid endDate format' });
        }
        whereClause.date[Op.lte] = endDate;
      }
    }

    // Sorting with validation
    const validSortFields = ['id', 'date', 'commission', 'listing', 'promotion', 'createdAt', 'updatedAt'];
    const sortField = validSortFields.includes(sortBy) ? sortBy : 'date';
    const sortDirection = sortOrder.toUpperCase() === 'ASC' ? 'ASC' : 'DESC';

    const { count, rows: companyEarnings } = await CompanyEarning.findAndCountAll({
      where: whereClause,
      limit: limitNum,
      offset: offset,
      order: [[sortField, sortDirection]],
    });

    const totalPages = Math.ceil(count / limitNum);

    res.json({
      data: companyEarnings,
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
    console.error('Error fetching company earnings:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// Get single company earning
const getCompanyEarningById = async (req, res) => {
  try {
    const { id } = req.params;

    // Input validation
    const earningId = parseInt(id);
    if (isNaN(earningId) || earningId < 1) {
      return res.status(400).json({ error: 'Invalid company earning ID' });
    }

    const companyEarning = await CompanyEarning.findByPk(earningId);
    if (!companyEarning) {
      return res.status(404).json({ error: 'Company earning not found' });
    }

    res.json(companyEarning);
  } catch (error) {
    console.error('Error fetching company earning:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// Create new company earning
const createCompanyEarning = async (req, res) => {
  try {
    const { date, commission, listing, promotion } = req.body;

    // Input validation and sanitization
    if (!date) {
      return res.status(400).json({ error: 'date is required' });
    }

    const earningDate = new Date(date);
    if (isNaN(earningDate.getTime())) {
      return res.status(400).json({ error: 'Invalid date format' });
    }

    // Validate decimal fields
    const validateDecimal = (value, fieldName) => {
      if (value !== undefined) {
        const num = parseFloat(value);
        if (isNaN(num) || num < 0 || num > 99999999.99) {
          return res.status(400).json({ error: `${fieldName} must be a valid decimal between 0 and 99999999.99` });
        }
        return num;
      }
      return 0.00;
    };

    const commissionValue = validateDecimal(commission, 'commission');
    if (commissionValue === undefined) return;

    const listingValue = validateDecimal(listing, 'listing');
    if (listingValue === undefined) return;

    const promotionValue = validateDecimal(promotion, 'promotion');
    if (promotionValue === undefined) return;

    const companyEarning = await CompanyEarning.create({
      date: date,
      commission: commissionValue,
      listing: listingValue,
      promotion: promotionValue,
    });

    res.status(201).json({
      message: 'Company earning created successfully',
      companyEarning: companyEarning.toJSON(),
    });
  } catch (error) {
    console.error('Error creating company earning:', error);

    if (error.name === 'SequelizeValidationError') {
      return res.status(400).json({ error: error.errors[0].message });
    }

    res.status(500).json({ error: 'Internal server error' });
  }
};

// Update company earning
const updateCompanyEarning = async (req, res) => {
  try {
    const { id } = req.params;
    const { date, commission, listing, promotion } = req.body;

    // Input validation
    const earningId = parseInt(id);
    if (isNaN(earningId) || earningId < 1) {
      return res.status(400).json({ error: 'Invalid company earning ID' });
    }

    const companyEarning = await CompanyEarning.findByPk(earningId);
    if (!companyEarning) {
      return res.status(404).json({ error: 'Company earning not found' });
    }

    const updateData = {};

    // Validate and set date
    if (date !== undefined) {
      const earningDate = new Date(date);
      if (isNaN(earningDate.getTime())) {
        return res.status(400).json({ error: 'Invalid date format' });
      }
      updateData.date = date;
    }

    // Validate decimal fields
    const validateDecimal = (value, fieldName) => {
      if (value !== undefined) {
        const num = parseFloat(value);
        if (isNaN(num) || num < 0 || num > 99999999.99) {
          return res.status(400).json({ error: `${fieldName} must be a valid decimal between 0 and 99999999.99` });
        }
        return num;
      }
      return undefined;
    };

    const commissionValue = validateDecimal(commission, 'commission');
    if (commissionValue === undefined && commission !== undefined) return;
    if (commissionValue !== undefined) updateData.commission = commissionValue;

    const listingValue = validateDecimal(listing, 'listing');
    if (listingValue === undefined && listing !== undefined) return;
    if (listingValue !== undefined) updateData.listing = listingValue;

    const promotionValue = validateDecimal(promotion, 'promotion');
    if (promotionValue === undefined && promotion !== undefined) return;
    if (promotionValue !== undefined) updateData.promotion = promotionValue;

    if (Object.keys(updateData).length === 0) {
      return res.status(400).json({ error: 'No valid fields to update' });
    }

    await companyEarning.update(updateData);

    res.json({
      message: 'Company earning updated successfully',
      companyEarning: companyEarning.toJSON(),
    });
  } catch (error) {
    console.error('Error updating company earning:', error);

    if (error.name === 'SequelizeValidationError') {
      return res.status(400).json({ error: error.errors[0].message });
    }

    res.status(500).json({ error: 'Internal server error' });
  }
};

// Delete company earning
const deleteCompanyEarning = async (req, res) => {
  try {
    const { id } = req.params;

    // Input validation
    const earningId = parseInt(id);
    if (isNaN(earningId) || earningId < 1) {
      return res.status(400).json({ error: 'Invalid company earning ID' });
    }

    const companyEarning = await CompanyEarning.findByPk(earningId);
    if (!companyEarning) {
      return res.status(404).json({ error: 'Company earning not found' });
    }

    await companyEarning.destroy();

    res.json({ message: 'Company earning deleted successfully' });
  } catch (error) {
    console.error('Error deleting company earning:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// Get total earnings summary
const getEarningsSummary = async (req, res) => {
  try {
    const { startDate, endDate } = req.query;

    let start = null;
    let end = null;

    if (startDate) {
      start = new Date(startDate);
      if (isNaN(start.getTime())) {
        return res.status(400).json({ error: 'Invalid startDate format' });
      }
    }

    if (endDate) {
      end = new Date(endDate);
      if (isNaN(end.getTime())) {
        return res.status(400).json({ error: 'Invalid endDate format' });
      }
    }

    const summary = await CompanyEarning.getTotalEarnings(start, end);

    res.json({
      summary,
      dateRange: {
        startDate: start,
        endDate: end,
      },
    });
  } catch (error) {
    console.error('Error fetching earnings summary:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

module.exports = {
  getCompanyEarnings,
  getCompanyEarningById,
  createCompanyEarning,
  updateCompanyEarning,
  deleteCompanyEarning,
  getEarningsSummary,
};
