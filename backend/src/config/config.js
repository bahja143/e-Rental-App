require('dotenv').config();

const env = process.env.NODE_ENV || 'development';
const dialect = env === 'test' ? 'sqlite' : (process.env.DB_DIALECT || 'mysql');
const isMySQL = dialect === 'mysql';

module.exports = {
  isMySQL,
  dialect,
  development: {
    username: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD || '',
    database: process.env.DB_NAME || 'rental_db',
    host: process.env.DB_HOST || 'localhost',
    port: process.env.DB_PORT || (isMySQL ? 3306 : 5432),
    dialect: dialect,
    define: {
      timestamps: true,
      underscored: false,
      freezeTableName: true,
    },
    dialectOptions: isMySQL ? {
      decimalNumbers: true,
      charset: 'utf8mb4',
    } : {},
    logging: process.env.DB_LOGGING === 'true' ? console.log : false,
  },
  test: {
    dialect: 'sqlite',
    storage: ':memory:',
    define: {
      timestamps: true,
      underscored: false,
      freezeTableName: true,
    },
    logging: false
  },
  production: {
    username: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,
    host: process.env.DB_HOST,
    port: process.env.DB_PORT || (process.env.DB_DIALECT === 'mysql' ? 3306 : 5432),
    dialect: process.env.DB_DIALECT || 'mysql',
    define: {
      timestamps: true,
      underscored: false,
      freezeTableName: true,
    },
    dialectOptions: process.env.DB_DIALECT === 'mysql' ? {
      decimalNumbers: true,
      charset: 'utf8mb4',
    } : {},
  }
};
