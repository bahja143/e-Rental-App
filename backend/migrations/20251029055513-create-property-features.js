'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('property_features', {
      id: {
        type: Sequelize.INTEGER,
        primaryKey: true,
        autoIncrement: true,
      },
      name_en: {
        type: Sequelize.STRING,
        allowNull: false,
        unique: true,
        validate: {
          notEmpty: true,
          len: [1, 255],
        },
      },
      name_so: {
        type: Sequelize.STRING,
        allowNull: false,
        validate: {
          notEmpty: true,
          len: [1, 255],
        },
      },
      type: {
        type: Sequelize.ENUM('number', 'string'),
        allowNull: false,
        defaultValue: 'string',
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
    await queryInterface.addIndex('property_features', ['name_en'], { unique: true });
    await queryInterface.addIndex('property_features', ['type']);
    await queryInterface.addIndex('property_features', ['createdAt']);
  },

  async down(queryInterface, Sequelize) {
    await queryInterface.dropTable('property_features');
  }
};
