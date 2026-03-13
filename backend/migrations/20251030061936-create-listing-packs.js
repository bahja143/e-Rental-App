'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('listing_packs', {
      id: {
        type: Sequelize.INTEGER,
        primaryKey: true,
        autoIncrement: true,
      },
      name_en: {
        type: Sequelize.STRING,
        allowNull: false,
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
      price: {
        type: Sequelize.INTEGER,
        allowNull: false,
        validate: {
          min: 0,
        },
      },
      duration: {
        type: Sequelize.INTEGER,
        allowNull: false,
        validate: {
          min: 1,
        },
      },
      features: {
        type: Sequelize.JSON,
        allowNull: true,
        defaultValue: {},
      },
      listing_amount: {
        type: Sequelize.INTEGER,
        allowNull: false,
        validate: {
          min: 0,
        },
      },
      display: {
        type: Sequelize.BOOLEAN,
        allowNull: false,
        defaultValue: true, // true = 1, false = 0
        validate: {
          isIn: [[true, false]],
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
    await queryInterface.addIndex('listing_packs', ['name_en']);
    await queryInterface.addIndex('listing_packs', ['name_so']);
    await queryInterface.addIndex('listing_packs', ['price']);
    await queryInterface.addIndex('listing_packs', ['duration']);
    await queryInterface.addIndex('listing_packs', ['listing_amount']);
    await queryInterface.addIndex('listing_packs', ['display']);
    await queryInterface.addIndex('listing_packs', ['createdAt']);
  },

  async down(queryInterface, Sequelize) {
    await queryInterface.dropTable('listing_packs');
  }
};
