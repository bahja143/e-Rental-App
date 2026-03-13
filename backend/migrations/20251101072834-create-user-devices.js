'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('user_devices', {
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
        onUpdate: 'CASCADE',
        onDelete: 'CASCADE',
      },
      device_type: {
        type: Sequelize.STRING(20),
        allowNull: false,
        validate: {
          notEmpty: true,
          len: [1, 20],
        },
      },
      fcm_token: {
        type: Sequelize.TEXT,
        allowNull: false,
        validate: {
          notEmpty: true,
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
    await queryInterface.addIndex('user_devices', ['user_id']);
    await queryInterface.addIndex('user_devices', ['device_type']);
    await queryInterface.addIndex('user_devices', ['createdAt']);
    await queryInterface.addIndex('user_devices', ['user_id', 'device_type']);
  },

  async down(queryInterface, Sequelize) {
    await queryInterface.dropTable('user_devices');
  }
};
