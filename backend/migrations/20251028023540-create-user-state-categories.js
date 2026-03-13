'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('user_state_categories', {
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
      state_categories_id: {
        type: Sequelize.INTEGER,
        allowNull: false,
        references: {
          model: 'state_categories',
          key: 'id',
        },
        onDelete: 'CASCADE',
        onUpdate: 'CASCADE',
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
    await queryInterface.addIndex('user_state_categories', ['user_id', 'state_categories_id'], { unique: true });
    await queryInterface.addIndex('user_state_categories', ['user_id']);
    await queryInterface.addIndex('user_state_categories', ['state_categories_id']);
    await queryInterface.addIndex('user_state_categories', ['createdAt']);
  },

  async down(queryInterface, Sequelize) {
    await queryInterface.dropTable('user_state_categories');
  }
};
