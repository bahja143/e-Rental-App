'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('listing_buyings', {
      id: {
        type: Sequelize.INTEGER,
        primaryKey: true,
        autoIncrement: true,
      },
      listing_id: {
        type: Sequelize.INTEGER,
        allowNull: false,
        references: {
          model: 'listings',
          key: 'id',
        },
        onDelete: 'CASCADE',
        onUpdate: 'CASCADE',
      },
      buyer_id: {
        type: Sequelize.INTEGER,
        allowNull: false,
        references: {
          model: 'users',
          key: 'id',
        },
        onDelete: 'CASCADE',
        onUpdate: 'CASCADE',
      },
      subtotal: {
        type: Sequelize.DECIMAL(255, 2),
        allowNull: false,
        validate: {
          min: 0,
        },
      },
      coupon_code: {
        type: Sequelize.STRING(255),
        allowNull: true,
      },
      coupon_id: {
        type: Sequelize.INTEGER,
        allowNull: true,
        references: {
          model: 'coupons',
          key: 'id',
        },
        onDelete: 'SET NULL',
        onUpdate: 'CASCADE',
      },
      discount: {
        type: Sequelize.DECIMAL(255, 2),
        allowNull: false,
        defaultValue: 0,
        validate: {
          min: 0,
        },
      },
      total: {
        type: Sequelize.DECIMAL(255, 2),
        allowNull: false,
        validate: {
          min: 0,
        },
      },
      status: {
        type: Sequelize.ENUM('pending', 'paid', 'confirmed', 'cancelled', 'completed'),
        allowNull: false,
        defaultValue: 'pending',
      },
      commission: {
        type: Sequelize.DECIMAL(255, 2),
        allowNull: false,
        defaultValue: 0,
        validate: {
          min: 0,
        },
      },
      sellers_value: {
        type: Sequelize.DECIMAL(255, 2),
        allowNull: false,
        defaultValue: 0,
        validate: {
          min: 0,
        },
      },
      bank_name: {
        type: Sequelize.STRING(255),
        allowNull: true,
      },
      branch: {
        type: Sequelize.STRING(255),
        allowNull: true,
      },
      bank_account: {
        type: Sequelize.STRING(255),
        allowNull: true,
      },
      account_holder_name: {
        type: Sequelize.STRING(255),
        allowNull: true,
      },
      swift: {
        type: Sequelize.STRING(50),
        allowNull: true,
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

    // Add indexes for performance
    await queryInterface.addIndex('listing_buyings', ['listing_id']);
    await queryInterface.addIndex('listing_buyings', ['buyer_id']);
    await queryInterface.addIndex('listing_buyings', ['coupon_id']);
    await queryInterface.addIndex('listing_buyings', ['status']);
    await queryInterface.addIndex('listing_buyings', ['createdAt']);
    await queryInterface.addIndex('listing_buyings', ['buyer_id', 'status']);
    await queryInterface.addIndex('listing_buyings', ['listing_id', 'status']);
  },

  async down(queryInterface, Sequelize) {
    await queryInterface.dropTable('listing_buyings');
  }
};
