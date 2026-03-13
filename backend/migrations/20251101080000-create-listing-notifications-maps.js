'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('listing_notifications_maps', {
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
        onUpdate: 'CASCADE',
        onDelete: 'CASCADE',
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
      sent_at: {
        type: Sequelize.DATE,
        allowNull: false,
        defaultValue: Sequelize.NOW,
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
    await queryInterface.addIndex('listing_notifications_maps', ['listing_id']);
    await queryInterface.addIndex('listing_notifications_maps', ['user_id']);
    await queryInterface.addIndex('listing_notifications_maps', ['sent_at']);
    await queryInterface.addIndex('listing_notifications_maps', ['listing_id', 'user_id']);
    await queryInterface.addIndex('listing_notifications_maps', ['user_id', 'sent_at']);
    await queryInterface.addIndex('listing_notifications_maps', ['createdAt']);
  },

  async down(queryInterface, Sequelize) {
    await queryInterface.dropTable('listing_notifications_maps');
  }
};
