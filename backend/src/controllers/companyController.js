const { Company } = require('../models');
const { Op } = require('sequelize');

// Get all companies with pagination, filtering, and sorting
const getCompanies = async (req, res) => {
  try {
    const {
      page = 1,
      limit = 10,
      search,
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

    // Search filter with sanitization
    if (search && typeof search === 'string' && search.trim().length > 0) {
      const sanitizedSearch = search.trim().replace(/[%_]/g, '\\$&'); // Escape SQL wildcards
      whereClause[Op.or] = [
        { name_en: { [Op.like]: `%${sanitizedSearch}%` } },
        { name_so: { [Op.like]: `%${sanitizedSearch}%` } },
        { address_en: { [Op.like]: `%${sanitizedSearch}%` } },
        { address_so: { [Op.like]: `%${sanitizedSearch}%` } },
      ];
    }

    // Sorting with validation
    const validSortFields = ['id', 'name_en', 'name_so', 'address_en', 'address_so', 'createdAt', 'updatedAt'];
    const sortField = validSortFields.includes(sortBy) ? sortBy : 'createdAt';
    const sortDirection = sortOrder.toUpperCase() === 'ASC' ? 'ASC' : 'DESC';

    const { count, rows: companies } = await Company.findAndCountAll({
      where: whereClause,
      limit: limitNum,
      offset: offset,
      order: [[sortField, sortDirection]],
    });

    const totalPages = Math.ceil(count / limitNum);

    res.json({
      data: companies,
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
    console.error('Error fetching companies:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// Get single company
const getCompanyById = async (req, res) => {
  try {
    const { id } = req.params;

    // Input validation
    const companyId = parseInt(id);
    if (isNaN(companyId) || companyId < 1) {
      return res.status(400).json({ error: 'Invalid company ID' });
    }

    const company = await Company.findByPk(companyId);

    if (!company) {
      return res.status(404).json({ error: 'Company not found' });
    }

    res.json(company);
  } catch (error) {
    console.error('Error fetching company:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// Create new company
const createCompany = async (req, res) => {
  try {
    const {
      name_en,
      name_so,
      address_en,
      address_so,
      emails,
      phones,
    } = req.body;

    // Input validation and sanitization
    if (!name_en || typeof name_en !== 'string' || name_en.trim().length < 2 || name_en.trim().length > 255) {
      return res.status(400).json({ error: 'name_en must be 2-255 characters' });
    }
    if (!address_en || typeof address_en !== 'string' || address_en.trim().length === 0) {
      return res.status(400).json({ error: 'address_en is required and cannot be empty' });
    }

    const sanitizedNameEn = name_en.trim();
    const sanitizedAddressEn = address_en.trim();

    let sanitizedNameSo = null;
    if (name_so && typeof name_so === 'string') {
      sanitizedNameSo = name_so.trim().substring(0, 255);
    }

    let sanitizedAddressSo = null;
    if (address_so && typeof address_so === 'string') {
      sanitizedAddressSo = address_so.trim();
    }

    // Validate emails array
    let sanitizedEmails = null;
    if (emails !== undefined) {
      if (!Array.isArray(emails)) {
        return res.status(400).json({ error: 'emails must be an array' });
      }
      const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
      for (const email of emails) {
        if (typeof email !== 'string' || !emailRegex.test(email)) {
          return res.status(400).json({ error: 'Invalid email format in emails array' });
        }
      }
      sanitizedEmails = emails;
    }

    // Validate phones array
    let sanitizedPhones = null;
    if (phones !== undefined) {
      if (!Array.isArray(phones)) {
        return res.status(400).json({ error: 'phones must be an array' });
      }
      const phoneRegex = /^[\+]?[1-9][\d]{0,15}$/;
      for (const phone of phones) {
        if (typeof phone !== 'string' || !phoneRegex.test(phone)) {
          return res.status(400).json({ error: 'Invalid phone format in phones array' });
        }
      }
      sanitizedPhones = phones;
    }

    const companyData = {
      name_en: sanitizedNameEn,
      name_so: sanitizedNameSo,
      address_en: sanitizedAddressEn,
      address_so: sanitizedAddressSo,
      emails: sanitizedEmails,
      phones: sanitizedPhones,
    };

    const company = await Company.create(companyData);

    res.status(201).json({
      message: 'Company created successfully',
      company: company.toJSON(),
    });
  } catch (error) {
    console.error('Error creating company:', error);

    if (error.name === 'SequelizeValidationError') {
      return res.status(400).json({ error: error.errors[0].message });
    }

    res.status(500).json({ error: 'Internal server error' });
  }
};

// Update company
const updateCompany = async (req, res) => {
  try {
    const { id } = req.params;

    // Input validation
    const companyId = parseInt(id);
    if (isNaN(companyId) || companyId < 1) {
      return res.status(400).json({ error: 'Invalid company ID' });
    }

    const {
      name_en,
      name_so,
      address_en,
      address_so,
      emails,
      phones,
    } = req.body;

    const company = await Company.findByPk(companyId);
    if (!company) {
      return res.status(404).json({ error: 'Company not found' });
    }

    const updateData = {};

    // Sanitize and validate provided fields
    if (name_en !== undefined) {
      if (typeof name_en !== 'string' || name_en.trim().length < 2 || name_en.trim().length > 255) {
        return res.status(400).json({ error: 'name_en must be 2-255 characters' });
      }
      updateData.name_en = name_en.trim();
    }

    if (name_so !== undefined) {
      if (name_so === null) {
        updateData.name_so = null;
      } else if (typeof name_so === 'string') {
        updateData.name_so = name_so.trim().substring(0, 255);
      } else {
        return res.status(400).json({ error: 'Invalid name_so format' });
      }
    }

    if (address_en !== undefined) {
      if (typeof address_en !== 'string' || address_en.trim().length === 0) {
        return res.status(400).json({ error: 'address_en cannot be empty' });
      }
      updateData.address_en = address_en.trim();
    }

    if (address_so !== undefined) {
      if (address_so === null) {
        updateData.address_so = null;
      } else if (typeof address_so === 'string') {
        updateData.address_so = address_so.trim();
      } else {
        return res.status(400).json({ error: 'Invalid address_so format' });
      }
    }

    if (emails !== undefined) {
      if (emails === null) {
        updateData.emails = null;
      } else if (Array.isArray(emails)) {
        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        for (const email of emails) {
          if (typeof email !== 'string' || !emailRegex.test(email)) {
            return res.status(400).json({ error: 'Invalid email format in emails array' });
          }
        }
        updateData.emails = emails;
      } else {
        return res.status(400).json({ error: 'emails must be an array or null' });
      }
    }

    if (phones !== undefined) {
      if (phones === null) {
        updateData.phones = null;
      } else if (Array.isArray(phones)) {
        const phoneRegex = /^[\+]?[1-9][\d]{0,15}$/;
        for (const phone of phones) {
          if (typeof phone !== 'string' || !phoneRegex.test(phone)) {
            return res.status(400).json({ error: 'Invalid phone format in phones array' });
          }
        }
        updateData.phones = phones;
      } else {
        return res.status(400).json({ error: 'phones must be an array or null' });
      }
    }

    await company.update(updateData);

    res.json({
      message: 'Company updated successfully',
      company: company.toJSON(),
    });
  } catch (error) {
    console.error('Error updating company:', error);

    if (error.name === 'SequelizeValidationError') {
      return res.status(400).json({ error: error.errors[0].message });
    }

    res.status(500).json({ error: 'Internal server error' });
  }
};

// Delete company
const deleteCompany = async (req, res) => {
  try {
    const { id } = req.params;

    // Input validation
    const companyId = parseInt(id);
    if (isNaN(companyId) || companyId < 1) {
      return res.status(400).json({ error: 'Invalid company ID' });
    }

    const company = await Company.findByPk(companyId);
    if (!company) {
      return res.status(404).json({ error: 'Company not found' });
    }

    await company.destroy();

    res.json({ message: 'Company deleted successfully' });
  } catch (error) {
    console.error('Error deleting company:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

module.exports = {
  getCompanies,
  getCompanyById,
  createCompany,
  updateCompany,
  deleteCompany,
};
