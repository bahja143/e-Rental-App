'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('third_party_payments', {
      id: {
        allowNull: false,
        autoIncrement: true,
        primaryKey: true,
        type: Sequelize.INTEGER,
      },
      user_id: {
        type: Sequelize.INTEGER,
        allowNull: false,
        references: {
          model: 'users',
          key: 'id',
        },
        onUpdate: 'CASCADE',
        onDelete: 'CASCADE',
      },
      listing_rental_id: {
        type: Sequelize.INTEGER,
        allowNull: true,
        references: {
          model: 'listing_rentals',
          key: 'id',
        },
        onUpdate: 'CASCADE',
        onDelete: 'SET NULL',
      },
      provider: {
        type: Sequelize.ENUM('waafi'),
        allowNull: false,
        defaultValue: 'waafi',
      },
      context: {
        type: Sequelize.ENUM('listing_rental'),
        allowNull: false,
        defaultValue: 'listing_rental',
      },
      status: {
        type: Sequelize.ENUM('pending', 'success', 'failed'),
        allowNull: false,
        defaultValue: 'pending',
      },
      amount: {
        type: Sequelize.DECIMAL(15, 2),
        allowNull: false,
      },
      currency: {
        type: Sequelize.STRING(10),
        allowNull: false,
        defaultValue: 'USD',
      },
      payer_account: {
        type: Sequelize.STRING(32),
        allowNull: false,
      },
      transaction_ref: {
        type: Sequelize.STRING(255),
        allowNull: false,
        unique: true,
      },
      invoice_id: {
        type: Sequelize.STRING(255),
        allowNull: false,
        unique: true,
      },
      request_id: {
        type: Sequelize.STRING(64),
        allowNull: false,
      },
      response_code: {
        type: Sequelize.STRING(50),
        allowNull: true,
      },
      response_message: {
        type: Sequelize.TEXT,
        allowNull: true,
      },
      raw_response: {
        type: Sequelize.JSON,
        allowNull: true,
      },
      metadata: {
        type: Sequelize.JSON,
        allowNull: true,
      },
      createdAt: {
        allowNull: false,
        type: Sequelize.DATE,
      },
      updatedAt: {
        allowNull: false,
        type: Sequelize.DATE,
      },
    });

    await queryInterface.addIndex('third_party_payments', ['user_id']);
    await queryInterface.addIndex('third_party_payments', ['listing_rental_id']);
    await queryInterface.addIndex('third_party_payments', ['provider']);
    await queryInterface.addIndex('third_party_payments', ['status']);
    await queryInterface.addIndex('third_party_payments', ['createdAt']);
  },

  async down(queryInterface) {
    await queryInterface.dropTable('third_party_payments');
  },
};
