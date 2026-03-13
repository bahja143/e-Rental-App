const { ListingVisit, Listing } = require('../models');
const { Op } = require('sequelize');

// Get all listing visits with pagination, filtering, sorting
const getListingVisits = async (req, res) => {
  try {
    const {
      page = 1,
      limit = 10,
      sortBy = 'createdAt',
      sortOrder = 'DESC',
      listing_id,
      date_from,
      date_to,
      min_total_impression,
      max_total_impression,
      min_total_visit,
      max_total_visit,
      min_conversion,
      max_conversion
    } = req.query;

    const offset = (page - 1) * limit;
    const where = {};

    // Apply filters
    if (listing_id) {
      where.listing_id = listing_id;
    }
    if (date_from || date_to) {
      where.date = {};
      if (date_from) where.date[Op.gte] = date_from;
      if (date_to) where.date[Op.lte] = date_to;
    }
    if (min_total_impression || max_total_impression) {
      where.total_impression = {};
      if (min_total_impression) where.total_impression[Op.gte] = parseInt(min_total_impression);
      if (max_total_impression) where.total_impression[Op.lte] = parseInt(max_total_impression);
    }
    if (min_total_visit || max_total_visit) {
      where.total_visit = {};
      if (min_total_visit) where.total_visit[Op.gte] = parseInt(min_total_visit);
      if (max_total_visit) where.total_visit[Op.lte] = parseInt(max_total_visit);
    }
    if (min_conversion || max_conversion) {
      where.conversion = {};
      if (min_conversion) where.conversion[Op.gte] = parseInt(min_conversion);
      if (max_conversion) where.conversion[Op.lte] = parseInt(max_conversion);
    }

    const include = [{
      model: Listing,
      as: 'listing',
      attributes: ['id', 'title', 'address']
    }];

    const visits = await ListingVisit.findAndCountAll({
      where,
      limit: parseInt(limit),
      offset: parseInt(offset),
      order: [[sortBy, sortOrder.toUpperCase()]],
      include,
    });

    res.json({
      data: visits.rows,
      pagination: {
        total: visits.count,
        page: parseInt(page),
        limit: parseInt(limit),
        totalPages: Math.ceil(visits.count / limit),
      },
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Get listing visit by ID
const getListingVisitById = async (req, res) => {
  try {
    const include = [{
      model: Listing,
      as: 'listing',
      attributes: ['id', 'title', 'address']
    }];

    const visit = await ListingVisit.findByPk(req.params.id, {
      include,
    });
    if (!visit) {
      return res.status(404).json({ error: 'Listing visit not found' });
    }
    res.json(visit);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Create a new listing visit
const createListingVisit = async (req, res) => {
  try {
    const {
      listing_id,
      total_impression,
      app_impression,
      ad_impression,
      total_visit,
      app_visit,
      ad_visit,
      share_visit,
      conversion,
      date
    } = req.body;

    // Validate required fields
    if (!listing_id || !date) {
      return res.status(400).json({ error: 'listing_id and date are required' });
    }

    // Validate date format
    const dateObj = new Date(date);
    if (isNaN(dateObj.getTime())) {
      return res.status(400).json({ error: 'Invalid date format' });
    }

    // Validate numeric fields
    const numericFields = [
      'total_impression', 'app_impression', 'ad_impression',
      'total_visit', 'app_visit', 'ad_visit', 'share_visit', 'conversion'
    ];

    for (const field of numericFields) {
      if (req.body[field] !== undefined) {
        const value = parseInt(req.body[field]);
        if (isNaN(value) || value < 0) {
          return res.status(400).json({ error: `${field} must be a non-negative integer` });
        }
      }
    }

    // Check if visit record already exists for this listing and date
    const existingVisit = await ListingVisit.findOne({
      where: { listing_id, date }
    });
    if (existingVisit) {
      return res.status(400).json({ error: 'Visit record already exists for this listing and date' });
    }

    const createData = {
      listing_id,
      date,
      total_impression: total_impression !== undefined ? parseInt(total_impression) : 0,
      app_impression: app_impression !== undefined ? parseInt(app_impression) : 0,
      ad_impression: ad_impression !== undefined ? parseInt(ad_impression) : 0,
      total_visit: total_visit !== undefined ? parseInt(total_visit) : 0,
      app_visit: app_visit !== undefined ? parseInt(app_visit) : 0,
      ad_visit: ad_visit !== undefined ? parseInt(ad_visit) : 0,
      share_visit: share_visit !== undefined ? parseInt(share_visit) : 0,
      conversion: conversion !== undefined ? parseInt(conversion) : 0,
    };

    const visit = await ListingVisit.create(createData);
    res.status(201).json(visit);
  } catch (error) {
    if (error.name === 'SequelizeForeignKeyConstraintError') {
      res.status(400).json({ error: 'Invalid listing_id - listing does not exist' });
    } else {
      res.status(400).json({ error: error.message });
    }
  }
};

// Update listing visit
const updateListingVisit = async (req, res) => {
  try {
    const {
      total_impression,
      app_impression,
      ad_impression,
      total_visit,
      app_visit,
      ad_visit,
      share_visit,
      conversion,
      date
    } = req.body;

    // Validate date format if provided
    if (date) {
      const dateObj = new Date(date);
      if (isNaN(dateObj.getTime())) {
        return res.status(400).json({ error: 'Invalid date format' });
      }
    }

    // Validate numeric fields if provided
    const numericFields = [
      'total_impression', 'app_impression', 'ad_impression',
      'total_visit', 'app_visit', 'ad_visit', 'share_visit', 'conversion'
    ];

    for (const field of numericFields) {
      if (req.body[field] !== undefined) {
        const value = parseInt(req.body[field]);
        if (isNaN(value) || value < 0) {
          return res.status(400).json({ error: `${field} must be a non-negative integer` });
        }
      }
    }

    const updateData = {};
    if (total_impression !== undefined) updateData.total_impression = parseInt(total_impression);
    if (app_impression !== undefined) updateData.app_impression = parseInt(app_impression);
    if (ad_impression !== undefined) updateData.ad_impression = parseInt(ad_impression);
    if (total_visit !== undefined) updateData.total_visit = parseInt(total_visit);
    if (app_visit !== undefined) updateData.app_visit = parseInt(app_visit);
    if (ad_visit !== undefined) updateData.ad_visit = parseInt(ad_visit);
    if (share_visit !== undefined) updateData.share_visit = parseInt(share_visit);
    if (conversion !== undefined) updateData.conversion = parseInt(conversion);
    if (date !== undefined) updateData.date = date;

    const [updated] = await ListingVisit.update(updateData, {
      where: { id: req.params.id }
    });
    if (!updated) {
      return res.status(404).json({ error: 'Listing visit not found' });
    }

    const include = [{
      model: Listing,
      as: 'listing',
      attributes: ['id', 'title', 'address']
    }];

    const updatedVisit = await ListingVisit.findByPk(req.params.id, {
      include,
    });
    res.json(updatedVisit);
  } catch (error) {
    if (error.name === 'SequelizeUniqueConstraintError') {
      res.status(400).json({ error: 'Visit record already exists for this listing and date' });
    } else {
      res.status(400).json({ error: error.message });
    }
  }
};

// Delete listing visit
const deleteListingVisit = async (req, res) => {
  try {
    const deleted = await ListingVisit.destroy({
      where: { id: req.params.id }
    });
    if (!deleted) {
      return res.status(404).json({ error: 'Listing visit not found' });
    }
    res.status(204).send();
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

module.exports = {
  getListingVisits,
  getListingVisitById,
  createListingVisit,
  updateListingVisit,
  deleteListingVisit,
};
