'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('listing_features', {
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
      property_feature_id: {
        type: Sequelize.INTEGER,
        allowNull: false,
        references: {
          model: 'property_features',
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
    await queryInterface.addIndex('listing_features', ['listing_id'], {
      name: 'listing_features_listing_id_idx'
    });
    await queryInterface.addIndex('listing_features', ['property_feature_id'], {
      name: 'listing_features_property_feature_id_idx'
    });
    await queryInterface.addIndex('listing_features', ['listing_id', 'property_feature_id'], {
      unique: true,
      name: 'listing_features_listing_property_unique_idx'
    });
    await queryInterface.addIndex('listing_features', ['createdAt'], {
      name: 'listing_features_created_at_idx'
    });
  },

  async down(queryInterface, Sequelize) {
    await queryInterface.dropTable('listing_features');
  }
};
