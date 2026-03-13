'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('withdraw_balances', {
      id: {
        type: Sequelize.INTEGER,
        primaryKey: true,
        autoIncrement: true,
      },
      user_id: {
        type: Sequelize.INTEGER,
        allowNull: false,
        references: {
          model: 'users',
          key: 'id',
        },
        onDelete: 'CASCADE',
        onUpdate: 'CASCADE',
      },
      amount: {
        type: Sequelize.DECIMAL(255, 2),
        allowNull: false,
        validate: {
          min: 0.01,
        },
      },
      status: {
        type: Sequelize.ENUM('requested', 'success', 'failed', 'cancelled'),
        allowNull: false,
        defaultValue: 'requested',
      },
      date: {
        type: Sequelize.DATE,
        allowNull: false,
        defaultValue: Sequelize.NOW,
      },
      before_balance: {
        type: Sequelize.DECIMAL(255, 2),
        allowNull: false,
        validate: {
          min: 0,
        },
      },
      after_balance: {
        type: Sequelize.DECIMAL(255, 2),
        allowNull: false,
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
    await queryInterface.addIndex('withdraw_balances', ['user_id']);
    await queryInterface.addIndex('withdraw_balances', ['status']);
    await queryInterface.addIndex('withdraw_balances', ['date']);
    await queryInterface.addIndex('withdraw_balances', ['user_id', 'status']);
    await queryInterface.addIndex('withdraw_balances', ['user_id', 'date']);
    await queryInterface.addIndex('withdraw_balances', ['createdAt']);
  },

  async down(queryInterface, Sequelize) {
    await queryInterface.dropTable('withdraw_balances');
  }
};
