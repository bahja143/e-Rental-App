/**
 * MySQL Setup Script
 * Creates the database if it doesn't exist, then syncs all tables.
 * Run: node scripts/setup-mysql.js
 */
require('dotenv').config();
process.env.NODE_ENV = process.env.NODE_ENV || 'development';
process.env.DB_DIALECT = 'mysql';
const mysql = require('mysql2/promise');
const { sequelize } = require('../src/config/database');
const db = require('../src/models');

async function setup() {
  const database = process.env.DB_NAME || 'rental_db';
  const host = process.env.DB_HOST || 'localhost';
  const port = process.env.DB_PORT || 3306;
  const user = process.env.DB_USER || 'root';
  const password = process.env.DB_PASSWORD || '';

  console.log('Creating database if not exists...');
  const connection = await mysql.createConnection({
    host,
    port,
    user,
    password,
  });

  await connection.query(`CREATE DATABASE IF NOT EXISTS \`${database}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci`);
  console.log(`Database '${database}' ready.`);
  await connection.end();

  console.log('Syncing Sequelize models...');
  await sequelize.sync({ alter: false });
  console.log('Database setup complete.');
  process.exit(0);
}

setup().catch((err) => {
  console.error('Setup failed:', err.message);
  process.exit(1);
});
