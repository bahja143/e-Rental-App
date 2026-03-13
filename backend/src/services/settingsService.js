const { redisClient } = require('../config/database');

const SETTINGS_KEY = 'app:settings';

let memoryFallback = null;

const DEFAULTS = {
  videoSharingEnabled: process.env.ENABLE_VIDEO_SHARING === 'true',
  maintenanceMode: false,
  newRegistrationsEnabled: true,
  maxListingsPerUser: 50,
  appName: 'Hantario Rental',
};

const getAll = async () => {
  try {
    if (redisClient && typeof redisClient.get === 'function') {
      const raw = await redisClient.get(SETTINGS_KEY);
      if (raw) {
        const parsed = JSON.parse(raw);
        return { ...DEFAULTS, ...parsed };
      }
    }
  } catch (e) {
    console.error('SettingsService getAll:', e.message);
  }
  if (memoryFallback) return { ...DEFAULTS, ...memoryFallback };
  return { ...DEFAULTS };
};

const update = async (updates) => {
  const current = await getAll();
  const allowed = Object.keys(DEFAULTS);
  const next = { ...current };

  for (const [key, value] of Object.entries(updates)) {
    if (!allowed.includes(key)) continue;
    if (typeof value === 'boolean') {
      next[key] = value;
    } else if (key === 'maxListingsPerUser' && typeof value === 'number') {
      next[key] = Math.max(1, Math.min(999, value));
    } else if (key === 'appName' && typeof value === 'string') {
      next[key] = value.trim().slice(0, 100) || DEFAULTS.appName;
    }
  }

  try {
    if (redisClient && typeof redisClient.set === 'function') {
      await redisClient.set(SETTINGS_KEY, JSON.stringify(next));
    } else {
      memoryFallback = next;
    }
  } catch (e) {
    console.error('SettingsService update:', e.message);
    throw new Error('Failed to save settings');
  }
  return next;
};

module.exports = {
  getAll,
  update,
  DEFAULTS,
};
