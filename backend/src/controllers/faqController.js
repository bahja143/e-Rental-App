const { Faq } = require('../models');
const { Op } = require('sequelize');

// Get all faqs with pagination, filtering, and sorting
const getFaqs = async (req, res) => {
  try {
    const {
      page = 1,
      limit = 10,
      search,
      type,
      sortBy = 'createdAt',
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

    // Filter by type
    if (type) {
      if (!['buyer', 'seller'].includes(type)) {
        return res.status(400).json({ error: 'Invalid type. Must be buyer or seller' });
      }
      whereClause.type = type;
    }

    // Search filter with sanitization
    if (search && typeof search === 'string' && search.trim().length > 0) {
      const sanitizedSearch = search.trim().replace(/[%_]/g, '\\$&'); // Escape SQL wildcards
      whereClause[Op.or] = [
        { title_en: { [Op.like]: `%${sanitizedSearch}%` } },
        { title_so: { [Op.like]: `%${sanitizedSearch}%` } },
        { description_en: { [Op.like]: `%${sanitizedSearch}%` } },
        { description_so: { [Op.like]: `%${sanitizedSearch}%` } },
      ];
    }

    // Sorting with validation
    const validSortFields = ['id', 'title_en', 'title_so', 'type', 'createdAt', 'updatedAt'];
    const sortField = validSortFields.includes(sortBy) ? sortBy : 'createdAt';
    const sortDirection = sortOrder.toUpperCase() === 'ASC' ? 'ASC' : 'DESC';

    const { count, rows: faqs } = await Faq.findAndCountAll({
      where: whereClause,
      limit: limitNum,
      offset: offset,
      order: [[sortField, sortDirection]],
    });

    const totalPages = Math.ceil(count / limitNum);

    res.json({
      data: faqs,
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
    console.error('Error fetching faqs:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// Get single faq
const getFaqById = async (req, res) => {
  try {
    const { id } = req.params;

    // Input validation
    const faqId = parseInt(id);
    if (isNaN(faqId) || faqId < 1) {
      return res.status(400).json({ error: 'Invalid faq ID' });
    }

    const faq = await Faq.findByPk(faqId);
    if (!faq) {
      return res.status(404).json({ error: 'Faq not found' });
    }

    res.json(faq);
  } catch (error) {
    console.error('Error fetching faq:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// Create new faq
const createFaq = async (req, res) => {
  try {
    const { title_en, title_so, description_en, description_so, type } = req.body;

    // Input validation
    if (!title_en || typeof title_en !== 'string' || title_en.trim().length === 0) {
      return res.status(400).json({ error: 'title_en is required and must be a non-empty string' });
    }

    if (title_en.length > 255) {
      return res.status(400).json({ error: 'title_en must be 255 characters or less' });
    }

    if (title_so !== undefined && (typeof title_so !== 'string' || title_so.length > 255)) {
      return res.status(400).json({ error: 'title_so must be a string of 255 characters or less' });
    }

    if (description_en !== undefined && typeof description_en !== 'string') {
      return res.status(400).json({ error: 'description_en must be a string' });
    }

    if (description_so !== undefined && typeof description_so !== 'string') {
      return res.status(400).json({ error: 'description_so must be a string' });
    }

    if (!type || !['buyer', 'seller'].includes(type)) {
      return res.status(400).json({ error: 'type is required and must be either buyer or seller' });
    }

    const faq = await Faq.create({
      title_en: title_en.trim(),
      title_so: title_so ? title_so.trim() : null,
      description_en: description_en || null,
      description_so: description_so || null,
      type,
    });

    res.status(201).json({
      message: 'Faq created successfully',
      faq: faq.toJSON(),
    });
  } catch (error) {
    console.error('Error creating faq:', error);

    if (error.name === 'SequelizeValidationError') {
      return res.status(400).json({ error: error.errors[0].message });
    }

    res.status(500).json({ error: 'Internal server error' });
  }
};

// Update faq
const updateFaq = async (req, res) => {
  try {
    const { id } = req.params;
    const { title_en, title_so, description_en, description_so, type } = req.body;

    // Input validation
    const faqId = parseInt(id);
    if (isNaN(faqId) || faqId < 1) {
      return res.status(400).json({ error: 'Invalid faq ID' });
    }

    const faq = await Faq.findByPk(faqId);
    if (!faq) {
      return res.status(404).json({ error: 'Faq not found' });
    }

    const updateData = {};

    if (title_en !== undefined) {
      if (typeof title_en !== 'string' || title_en.trim().length === 0) {
        return res.status(400).json({ error: 'title_en must be a non-empty string' });
      }
      if (title_en.length > 255) {
        return res.status(400).json({ error: 'title_en must be 255 characters or less' });
      }
      updateData.title_en = title_en.trim();
    }

    if (title_so !== undefined) {
      if (title_so === null) {
        updateData.title_so = null;
      } else if (typeof title_so === 'string' && title_so.length <= 255) {
        updateData.title_so = title_so.trim();
      } else {
        return res.status(400).json({ error: 'title_so must be a string of 255 characters or less or null' });
      }
    }

    if (description_en !== undefined) {
      if (description_en === null) {
        updateData.description_en = null;
      } else if (typeof description_en === 'string') {
        updateData.description_en = description_en;
      } else {
        return res.status(400).json({ error: 'description_en must be a string or null' });
      }
    }

    if (description_so !== undefined) {
      if (description_so === null) {
        updateData.description_so = null;
      } else if (typeof description_so === 'string') {
        updateData.description_so = description_so;
      } else {
        return res.status(400).json({ error: 'description_so must be a string or null' });
      }
    }

    if (type !== undefined) {
      if (!['buyer', 'seller'].includes(type)) {
        return res.status(400).json({ error: 'type must be either buyer or seller' });
      }
      updateData.type = type;
    }

    if (Object.keys(updateData).length === 0) {
      return res.status(400).json({ error: 'No valid fields to update' });
    }

    await faq.update(updateData);

    res.json({
      message: 'Faq updated successfully',
      faq: faq.toJSON(),
    });
  } catch (error) {
    console.error('Error updating faq:', error);

    if (error.name === 'SequelizeValidationError') {
      return res.status(400).json({ error: error.errors[0].message });
    }

    res.status(500).json({ error: 'Internal server error' });
  }
};

// Delete faq
const deleteFaq = async (req, res) => {
  try {
    const { id } = req.params;

    // Input validation
    const faqId = parseInt(id);
    if (isNaN(faqId) || faqId < 1) {
      return res.status(400).json({ error: 'Invalid faq ID' });
    }

    const faq = await Faq.findByPk(faqId);
    if (!faq) {
      return res.status(404).json({ error: 'Faq not found' });
    }

    await faq.destroy();

    res.json({ message: 'Faq deleted successfully' });
  } catch (error) {
    console.error('Error deleting faq:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

module.exports = {
  getFaqs,
  getFaqById,
  createFaq,
  updateFaq,
  deleteFaq,
};
