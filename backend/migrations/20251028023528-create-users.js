'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('users', {
      id: {
        type: Sequelize.INTEGER,
        primaryKey: true,
        autoIncrement: true,
      },
      name: {
        type: Sequelize.STRING,
        allowNull: false,
        validate: {
          notEmpty: true,
          len: [2, 100],
        },
      },
      email: {
        type: Sequelize.STRING,
        allowNull: false,
        unique: true,
        validate: {
          isEmail: true,
        },
      },
      phone: {
        type: Sequelize.STRING,
        allowNull: true,
        unique: true,
        validate: {
          is: /^[\+]?[1-9][\d]{0,15}$/, // Basic phone validation
        },
      },
      password: {
        type: Sequelize.STRING,
        allowNull: false,
        validate: {
          len: [6, 255], // Minimum 6 characters
        },
      },
      city: {
        type: Sequelize.STRING(255),
        allowNull: true,
      },
      location: {
        type: Sequelize.GEOMETRY('POINT', 4326), // PostGIS POINT with SRID 4326 (WGS84)
        allowNull: true,
      },
      lat: {
        type: Sequelize.DECIMAL(10, 8),
        allowNull: true,
      },
      lng: {
        type: Sequelize.DECIMAL(11, 8),
        allowNull: true,
      },
      two_factor_code: {
        type: Sequelize.STRING,
        allowNull: true,
      },
      two_factor_expire: {
        type: Sequelize.DATE,
        allowNull: true,
      },
      looking_for: {
        type: Sequelize.ENUM('buy', 'sale', 'rent', 'monitor_my_property', 'just_look_around'),
        allowNull: true,
        defaultValue: 'just_look_around',
      },
      profile_picture_url: {
        type: Sequelize.TEXT,
        allowNull: true,
        validate: {
          isUrl: true,
        },
      },
      pending_balance: {
        type: Sequelize.INTEGER,
        allowNull: false,
        defaultValue: 0,
      },
      available_balance: {
        type: Sequelize.INTEGER,
        allowNull: false,
        defaultValue: 0,
      },
      looking_for_set: {
        type: Sequelize.BOOLEAN,
        allowNull: false,
        defaultValue: false,
      },
      category_set: {
        type: Sequelize.BOOLEAN,
        allowNull: false,
        defaultValue: false,
      },
      role: {
        type: Sequelize.ENUM('admin', 'user'),
        allowNull: false,
        defaultValue: 'user',
      },
      user_type: {
        type: Sequelize.ENUM('buyer', 'seller'),
        allowNull: false,
        defaultValue: 'buyer',
      },
      createdAt: {
        type: Sequelize.DATE,
        defaultValue: Sequelize.NOW,
      },
      updatedAt: {
        type: Sequelize.DATE,
        defaultValue: Sequelize.NOW,
      },
    });

    // Add indexes
    await queryInterface.addIndex('users', ['email'], { unique: true });
    await queryInterface.addIndex('users', ['phone'], {
      unique: true,
      where: {
        phone: {
          [Sequelize.Op.ne]: null,
        },
      },
    });
    await queryInterface.addIndex('users', ['location'], { using: 'GIST' });
    await queryInterface.addIndex('users', ['city']);
    await queryInterface.addIndex('users', ['looking_for']);
    await queryInterface.addIndex('users', ['available_balance']);
    await queryInterface.addIndex('users', ['city', 'looking_for']);
    await queryInterface.addIndex('users', ['createdAt']);
  },

  async down(queryInterface, Sequelize) {
    await queryInterface.dropTable('users');
  }
};
