'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('type_listings', {
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
      listing_type_id: {
        type: Sequelize.INTEGER,
        allowNull: false,
        references: {
          model: 'listing_types',
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
    await queryInterface.addIndex('type_listings', ['listing_id'], {
      name: 'type_listings_listing_id_index'
    });

    await queryInterface.addIndex('type_listings', ['listing_type_id'], {
      name: 'type_listings_listing_type_id_index'
    });

    // Composite unique index to prevent duplicate associations
    await queryInterface.addIndex('type_listings', ['listing_id', 'listing_type_id'], {
      unique: true,
      name: 'type_listings_unique_listing_type_index'
    });

    await queryInterface.addIndex('type_listings', ['createdAt'], {
      name: 'type_listings_created_at_index'
    });
  },

  async down(queryInterface, Sequelize) {
    await queryInterface.dropTable('type_listings');
  }
};
