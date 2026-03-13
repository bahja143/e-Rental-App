// Database configuration
const { Sequelize } = require('sequelize');
const Redis = require('ioredis');
const config = require('./config.js');

const env = process.env.NODE_ENV || 'development';
const dbConfig = config[env];

let sequelize;
if (env === 'test') {
  sequelize = new Sequelize({
    dialect: 'sqlite',
    storage: ':memory:',
    define: dbConfig.define,
    logging: dbConfig.logging
  });
} else {
  sequelize = new Sequelize(dbConfig.database, dbConfig.username, dbConfig.password, {
    host: dbConfig.host,
    port: dbConfig.port,
    dialect: dbConfig.dialect,
    define: dbConfig.define,
    logging: dbConfig.logging || false,
    dialectOptions: dbConfig.dialectOptions || {},
  });
}



// Redis client for caching and queues
let redisClient;
if (env !== 'test') {
  redisClient = new Redis({
    host: process.env.REDIS_HOST || 'redis',
    port: parseInt(process.env.REDIS_PORT || '6379', 10),
    maxRetriesPerRequest: null,
  });

  redisClient.on('error', (err) => console.error('Redis Client Error', err));
}

module.exports = {
  sequelize,
  redisClient,
};
