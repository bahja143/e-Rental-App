'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up (queryInterface, Sequelize) {
    await queryInterface.createTable('listing_reviews', {
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
      user_id: {
        type: Sequelize.INTEGER,
        allowNull: false,
        references: {
          model: 'users',
          key: 'id'
        },
        onUpdate: 'CASCADE',
        onDelete: 'CASCADE'
      },
      rating: {
        type: Sequelize.INTEGER,
        allowNull: false,
        validate: {
          min: 1,
          max: 5
        }
      },
      comment: {
        type: Sequelize.TEXT,
        allowNull: false,
        validate: {
          notEmpty: true
        }
      },
      images: {
        type: Sequelize.JSON,
        allowNull: true,
        defaultValue: []
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
    await queryInterface.addIndex('listing_reviews', ['listing_id'], {
      name: 'listing_reviews_listing_id_index'
    });

    await queryInterface.addIndex('listing_reviews', ['user_id'], {
      name: 'listing_reviews_user_id_index'
    });

    await queryInterface.addIndex('listing_reviews', ['rating'], {
      name: 'listing_reviews_rating_index'
    });

    await queryInterface.addIndex('listing_reviews', ['createdAt'], {
      name: 'listing_reviews_created_at_index'
    });

    // Composite index for common queries
    await queryInterface.addIndex('listing_reviews', ['listing_id', 'createdAt'], {
      name: 'listing_reviews_listing_id_created_at_index'
    });

    await queryInterface.addIndex('listing_reviews', ['user_id', 'createdAt'], {
      name: 'listing_reviews_user_id_created_at_index'
    });
  },

  async down (queryInterface, Sequelize) {
    await queryInterface.dropTable('listing_reviews');
  }
};
