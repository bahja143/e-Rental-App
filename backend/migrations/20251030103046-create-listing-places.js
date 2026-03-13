'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('listing_places', {
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
          key: 'id'
        },
        onUpdate: 'CASCADE',
        onDelete: 'CASCADE'
      },
      nearby_place_id: {
        type: Sequelize.INTEGER,
        allowNull: false,
        references: {
          model: 'nearby_places',
          key: 'id'
        },
        onUpdate: 'CASCADE',
        onDelete: 'CASCADE'
      },
      value: {
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

    // Add indexes for performance
    await queryInterface.addIndex('listing_places', ['listing_id'], {
      name: 'listing_places_listing_id_idx'
    });
    await queryInterface.addIndex('listing_places', ['nearby_place_id'], {
      name: 'listing_places_nearby_place_id_idx'
    });
    await queryInterface.addIndex('listing_places', ['listing_id', 'nearby_place_id'], {
      unique: true,
      name: 'listing_places_listing_nearby_place_unique_idx'
    });
    await queryInterface.addIndex('listing_places', ['createdAt'], {
      name: 'listing_places_created_at_idx'
    });
  },

  async down(queryInterface, Sequelize) {
    await queryInterface.dropTable('listing_places');
  }
};
