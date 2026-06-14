const path = require('path');
const dotenv = require('dotenv');

const loadEnvFile = (envPath, override = false) => {
  dotenv.config({ path: envPath, override });
};

// Load repo-level variables first, then allow backend/.env to override them.
loadEnvFile(path.resolve(__dirname, '../../../.env'));
loadEnvFile(path.resolve(__dirname, '../../.env'), true);

