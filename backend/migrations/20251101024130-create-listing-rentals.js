'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('listing_rentals', {
      id: {
        type: Sequelize.INTEGER,
        primaryKey: true,
        autoIncrement: true,
      },
      list_id: {
        type: Sequelize.INTEGER,
        allowNull: false,
        references: {
          model: 'listings',
          key: 'id',
        },
        onDelete: 'CASCADE',
        onUpdate: 'CASCADE',
      },
      renter_id: {
        type: Sequelize.INTEGER,
        allowNull: false,
        references: {
          model: 'users',
          key: 'id',
        },
        onDelete: 'CASCADE',
        onUpdate: 'CASCADE',
      },
      start_date: {
        type: Sequelize.DATE,
        allowNull: false,
      },
      end_date: {
        type: Sequelize.DATE,
        allowNull: false,
      },
      rent_type: {
        type: Sequelize.ENUM('daily', 'monthly', 'yearly'),
        allowNull: false,
      },
      status: {
        type: Sequelize.ENUM('pending', 'confirmed', 'cancelled', 'completed'),
        allowNull: false,
        defaultValue: 'pending',
      },
      date: {
        type: Sequelize.DATE,
        allowNull: false,
        defaultValue: Sequelize.NOW,
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
      subtotal: {
        type: Sequelize.DECIMAL(255, 2),
        allowNull: false,
        validate: {
          min: 0,
        },
      },
      coupon_code: {
        type: Sequelize.STRING(50),
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

    // Add indexes for performance
    await queryInterface.addIndex('listing_rentals', ['list_id']);
    await queryInterface.addIndex('listing_rentals', ['renter_id']);
    await queryInterface.addIndex('listing_rentals', ['status']);
    await queryInterface.addIndex('listing_rentals', ['rent_type']);
    await queryInterface.addIndex('listing_rentals', ['start_date']);
    await queryInterface.addIndex('listing_rentals', ['end_date']);
    await queryInterface.addIndex('listing_rentals', ['date']);
    await queryInterface.addIndex('listing_rentals', ['coupon_id']);
    await queryInterface.addIndex('listing_rentals', ['list_id', 'status']);
    await queryInterface.addIndex('listing_rentals', ['renter_id', 'status']);
    await queryInterface.addIndex('listing_rentals', ['list_id', 'start_date']);
    await queryInterface.addIndex('listing_rentals', ['list_id', 'end_date']);
    await queryInterface.addIndex('listing_rentals', ['createdAt']);
  },

  async down(queryInterface, Sequelize) {
    await queryInterface.dropTable('listing_rentals');
  }
};
