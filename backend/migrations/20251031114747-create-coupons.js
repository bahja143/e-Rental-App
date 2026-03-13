'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('coupons', {
      id: {
        type: Sequelize.INTEGER,
        primaryKey: true,
        autoIncrement: true,
      },
      code: {
        type: Sequelize.STRING,
        allowNull: false,
        unique: true,
        validate: {
          notEmpty: true,
          len: [3, 50],
          isAlphanumeric: true,
        },
      },
      type: {
        type: Sequelize.ENUM('percentage', 'fixed'),
        allowNull: false,
        validate: {
          isIn: [['percentage', 'fixed']],
        },
      },
      value: {
        type: Sequelize.DECIMAL(10, 2),
        allowNull: false,
        validate: {
          min: 0.01,
          max: 999999.99,
        },
      },
      use_case: {
        type: Sequelize.ENUM('listing_package', 'promotion_package', 'listing_buy', 'listing_rent'),
        allowNull: false,
        validate: {
          isIn: [['listing_package', 'promotion_package', 'listing_buy', 'listing_rent']],
        },
      },
      min_purchase: {
        type: Sequelize.INTEGER,
        allowNull: true,
        validate: {
          min: 0,
        },
      },
      start_date: {
        type: Sequelize.DATE,
        allowNull: true,
      },
      expire_date: {
        type: Sequelize.DATE,
        allowNull: true,
      },
      usage_limit: {
        type: Sequelize.INTEGER,
        allowNull: true,
        validate: {
          min: 1,
        },
      },
      per_user_limit: {
        type: Sequelize.INTEGER,
        allowNull: true,
        validate: {
          min: 1,
        },
      },
      is_active: {
        type: Sequelize.BOOLEAN,
        allowNull: false,
        defaultValue: true,
      },
      used: {
        type: Sequelize.INTEGER,
        allowNull: false,
        defaultValue: 0,
        validate: {
          min: 0,
        },
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
    await queryInterface.addIndex('coupons', ['code'], { unique: true });
    await queryInterface.addIndex('coupons', ['type']);
    await queryInterface.addIndex('coupons', ['use_case']);
    await queryInterface.addIndex('coupons', ['is_active']);
    await queryInterface.addIndex('coupons', ['expire_date']);
    await queryInterface.addIndex('coupons', ['start_date']);
    await queryInterface.addIndex('coupons', ['min_purchase']);
    await queryInterface.addIndex('coupons', ['usage_limit']);
    await queryInterface.addIndex('coupons', ['createdAt']);
    await queryInterface.addIndex('coupons', ['is_active', 'expire_date']);
    await queryInterface.addIndex('coupons', ['type', 'use_case', 'is_active']);
  },

  async down(queryInterface, Sequelize) {
    await queryInterface.dropTable('coupons');
  }
};
