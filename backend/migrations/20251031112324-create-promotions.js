'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('promotions', {
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
          key: 'id'
        },
        onUpdate: 'CASCADE',
        onDelete: 'CASCADE'
      },
      subtotal: {
        type: Sequelize.DECIMAL(10, 2),
        allowNull: false,
        validate: {
          min: 0,
        },
      },
      coupon_code: {
        type: Sequelize.STRING,
        allowNull: true,
        validate: {
          len: [0, 50],
        },
      },
      discount: {
        type: Sequelize.DECIMAL(10, 2),
        allowNull: false,
        defaultValue: 0.00,
        validate: {
          min: 0,
        },
      },
      total: {
        type: Sequelize.DECIMAL(10, 2),
        allowNull: false,
        validate: {
          min: 0,
        },
      },
      start_date: {
        type: Sequelize.DATE,
        allowNull: false,
      },
      end_date: {
        type: Sequelize.DATE,
        allowNull: false,
      },
      coupon_id: {
        type: Sequelize.INTEGER,
        allowNull: true,
        references: {
          model: 'coupons',
          key: 'id'
        },
        onUpdate: 'CASCADE',
        onDelete: 'SET NULL'
      },
      promotion_package_id: {
        type: Sequelize.INTEGER,
        allowNull: true,
        references: {
          model: 'promotion_packs',
          key: 'id'
        },
        onUpdate: 'CASCADE',
        onDelete: 'SET NULL'
      },
      date: {
        type: Sequelize.DATE,
        allowNull: false,
        defaultValue: Sequelize.NOW,
      },
      status: {
        type: Sequelize.ENUM('active', 'expired'),
        allowNull: false,
        defaultValue: 'active',
        validate: {
          isIn: [['active', 'expired']],
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

    // Add indexes
    await queryInterface.addIndex('promotions', ['listing_id']);
    await queryInterface.addIndex('promotions', ['coupon_id']);
    await queryInterface.addIndex('promotions', ['promotion_package_id']);
    await queryInterface.addIndex('promotions', ['status']);
    await queryInterface.addIndex('promotions', ['start_date']);
    await queryInterface.addIndex('promotions', ['end_date']);
    await queryInterface.addIndex('promotions', ['date']);
    await queryInterface.addIndex('promotions', ['listing_id', 'status']);
    await queryInterface.addIndex('promotions', ['status', 'start_date', 'end_date']);
    await queryInterface.addIndex('promotions', ['coupon_id', 'status']);
    await queryInterface.addIndex('promotions', ['promotion_package_id', 'status']);
    await queryInterface.addIndex('promotions', ['createdAt']);
    await queryInterface.addIndex('promotions', ['start_date', 'end_date']);
  },

  async down(queryInterface, Sequelize) {
    await queryInterface.dropTable('promotions');
  }
};
