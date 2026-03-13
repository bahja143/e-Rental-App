const settingsService = require('../services/settingsService');

const requireAdmin = (req, res, next) => {
  const role = req.user?.role?.toLowerCase?.();
  if (role !== 'admin') {
    return res.status(403).json({ error: 'Admin access required' });
  }
  next();
};

const getSettings = async (req, res) => {
  try {
    const settings = await settingsService.getAll();
    res.json(settings);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

const updateSettings = async (req, res) => {
  try {
    const settings = await settingsService.update(req.body);
    res.json(settings);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

module.exports = {
  getSettings,
  updateSettings,
  requireAdmin,
};
