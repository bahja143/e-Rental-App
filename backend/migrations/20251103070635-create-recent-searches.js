'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('recent_searches', {
      id: {
        type: Sequelize.INTEGER,
        primaryKey: true,
        autoIncrement: true,
      },
      user_id: {
        type: Sequelize.INTEGER,
        allowNull: true,
        references: {
          model: 'users',
          key: 'id',
        },
        onUpdate: 'CASCADE',
        onDelete: 'SET NULL',
      },
      device_id: {
        type: Sequelize.UUID,
        allowNull: true,
      },
      search_text: {
        type: Sequelize.STRING(255),
        allowNull: false,
      },
      category_id: {
        type: Sequelize.INTEGER,
        allowNull: true,
        references: {
          model: 'property_categories',
          key: 'id',
        },
        onUpdate: 'CASCADE',
        onDelete: 'SET NULL',
      },
      latitude: {
        type: Sequelize.DOUBLE,
        allowNull: false,
      },
      longitude: {
        type: Sequelize.DOUBLE,
        allowNull: false,
      },
      radius: {
        type: Sequelize.INTEGER,
        allowNull: false,
        defaultValue: 0,
      },
      created_at: {
        type: Sequelize.DATE,
        allowNull: false,
        defaultValue: Sequelize.NOW,
      },
    });

    // Add indexes
    await queryInterface.addIndex('recent_searches', ['user_id']);
    await queryInterface.addIndex('recent_searches', ['device_id']);
    await queryInterface.addIndex('recent_searches', ['category_id']);
    await queryInterface.addIndex('recent_searches', ['created_at']);
    await queryInterface.addIndex('recent_searches', ['search_text']);
    await queryInterface.addIndex('recent_searches', ['latitude', 'longitude']);
  },

  async down(queryInterface, Sequelize) {
    await queryInterface.dropTable('recent_searches');
  }
};
