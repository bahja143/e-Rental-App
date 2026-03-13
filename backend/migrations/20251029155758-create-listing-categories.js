'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up (queryInterface, Sequelize) {
    await queryInterface.createTable('listing_categories', {
      id: {
        allowNull: false,
        autoIncrement: true,
        primaryKey: true,
        type: Sequelize.INTEGER
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
      property_category_id: {
        type: Sequelize.INTEGER,
        allowNull: false,
        references: {
          model: 'property_categories',
          key: 'id'
        },
        onUpdate: 'CASCADE',
        onDelete: 'CASCADE'
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
    await queryInterface.addIndex('listing_categories', ['listing_id'], {
      name: 'listing_categories_listing_id_index'
    });

    await queryInterface.addIndex('listing_categories', ['property_category_id'], {
      name: 'listing_categories_property_category_id_index'
    });

    // Composite index for unique listing-category pairs
    await queryInterface.addIndex('listing_categories', ['listing_id', 'property_category_id'], {
      name: 'listing_categories_listing_property_unique',
      unique: true
    });

    await queryInterface.addIndex('listing_categories', ['createdAt'], {
      name: 'listing_categories_created_at_index'
    });
  },

  async down (queryInterface, Sequelize) {
    await queryInterface.dropTable('listing_categories');
  }
};
