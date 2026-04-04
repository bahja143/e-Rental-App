const mongoose = require('mongoose');

const parseBoolean = (value, defaultValue = true) => {
  if (value == null || value === '') return defaultValue;
  const normalized = `${value}`.trim().toLowerCase();
  if (['1', 'true', 'yes', 'on'].includes(normalized)) return true;
  if (['0', 'false', 'no', 'off'].includes(normalized)) return false;
  return defaultValue;
};

const isMongoEnabled = () => parseBoolean(process.env.MONGO_ENABLED, true);

const isMongoConnected = () => mongoose.connection.readyState === 1;

const requireMongo = (req, res, next) => {
  if (!isMongoEnabled()) {
    return res.status(503).json({ error: 'Chat is disabled on this environment' });
  }

  if (!isMongoConnected()) {
    return res.status(503).json({ error: 'Chat service is temporarily unavailable' });
  }

  next();
};

module.exports = {
  isMongoEnabled,
  isMongoConnected,
  requireMongo,
};
