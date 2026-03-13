'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('user_listing_pack_transactions', {
      id: {
        allowNull: false,
        autoIncrement: true,
        primaryKey: true,
        type: Sequelize.INTEGER
      },
      user_id: {
        type: Sequelize.INTEGER,
        allowNull: false,
        references: {
          model: 'users',
          key: 'id'
        },
        onUpdate: 'CASCADE',
        onDelete: 'CASCADE'
      },
      listing_pack_id: {
        type: Sequelize.INTEGER,
        allowNull: false,
        references: {
          model: 'listing_packs',
          key: 'id'
        },
        onUpdate: 'CASCADE',
        onDelete: 'CASCADE'
      },
      type: {
        type: Sequelize.ENUM('buy', 'upgrade', 'downgrade', 'renew', 'refund', 'adjustment'),
        allowNull: false
      },
      subtotal: {
        type: Sequelize.DECIMAL(10, 2),
        allowNull: false
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
      discount: {
        type: Sequelize.DECIMAL(10, 2),
        allowNull: true
      },
      total: {
        type: Sequelize.DECIMAL(10, 2),
        allowNull: true
      },
      coupon_code: {
        type: Sequelize.STRING(50),
        allowNull: true
      },
      previous_pack_id: {
        type: Sequelize.INTEGER,
        allowNull: true,
        references: {
          model: 'listing_packs',
          key: 'id'
        },
        onUpdate: 'CASCADE',
        onDelete: 'SET NULL'
      },
      adjusted_amount: {
        type: Sequelize.DECIMAL(10, 2),
        allowNull: true
      },
      payment_method: {
        type: Sequelize.ENUM('bank', 'card', 'wallet', 'admin'),
        allowNull: false
      },
      transaction_ref: {
        type: Sequelize.STRING(255),
        allowNull: false
      },
      status: {
        type: Sequelize.ENUM('pending', 'success', 'failed'),
        allowNull: false,
        defaultValue: 'pending'
      },
      note: {
        type: Sequelize.TEXT,
        allowNull: true
      },
      bank_name: {
        type: Sequelize.STRING(100),
        allowNull: true
      },
      branch: {
        type: Sequelize.STRING(100),
        allowNull: true
      },
      bank_account: {
        type: Sequelize.STRING(50),
        allowNull: true
      },
      account_holder_name: {
        type: Sequelize.STRING(100),
        allowNull: true
      },
      swift: {
        type: Sequelize.STRING(20),
        allowNull: true
      },
      createdAt: {
        allowNull: false,
        type: Sequelize.DATE
      },
      updatedAt: {
        allowNull: false,
        type: Sequelize.DATE
      }
    });

    // Add indexes for performance
    await queryInterface.addIndex('user_listing_pack_transactions', ['user_id']);
    await queryInterface.addIndex('user_listing_pack_transactions', ['listing_pack_id']);
    await queryInterface.addIndex('user_listing_pack_transactions', ['coupon_id']);
    await queryInterface.addIndex('user_listing_pack_transactions', ['status']);
    await queryInterface.addIndex('user_listing_pack_transactions', ['type']);
    await queryInterface.addIndex('user_listing_pack_transactions', ['createdAt']);
  },

  async down(queryInterface, Sequelize) {
    await queryInterface.dropTable('user_listing_pack_transactions');
  }
};
