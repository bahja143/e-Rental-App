'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up (queryInterface, Sequelize) {
    await queryInterface.createTable('listing_visits', {
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
      total_impression: {
        type: Sequelize.INTEGER,
        allowNull: true,
        defaultValue: 0,
        validate: {
          min: 0
        }
      },
      app_impression: {
        type: Sequelize.INTEGER,
        allowNull: true,
        defaultValue: 0,
        validate: {
          min: 0
        }
      },
      ad_impression: {
        type: Sequelize.INTEGER,
        allowNull: true,
        defaultValue: 0,
        validate: {
          min: 0
        }
      },
      total_visit: {
        type: Sequelize.INTEGER,
        allowNull: true,
        defaultValue: 0,
        validate: {
          min: 0
        }
      },
      app_visit: {
        type: Sequelize.INTEGER,
        allowNull: true,
        defaultValue: 0,
        validate: {
          min: 0
        }
      },
      ad_visit: {
        type: Sequelize.INTEGER,
        allowNull: true,
        defaultValue: 0,
        validate: {
          min: 0
        }
      },
      share_visit: {
        type: Sequelize.INTEGER,
        allowNull: true,
        defaultValue: 0,
        validate: {
          min: 0
        }
      },
      conversion: {
        type: Sequelize.INTEGER,
        allowNull: true,
        defaultValue: 0,
        validate: {
          min: 0
        }
      },
      date: {
        type: Sequelize.DATEONLY,
        allowNull: false,
        validate: {
          isDate: true
        }
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
    await queryInterface.addIndex('listing_visits', ['listing_id'], {
      name: 'listing_visits_listing_id_index'
    });

    await queryInterface.addIndex('listing_visits', ['date'], {
      name: 'listing_visits_date_index'
    });

    await queryInterface.addIndex('listing_visits', ['total_impression'], {
      name: 'listing_visits_total_impression_index'
    });

    await queryInterface.addIndex('listing_visits', ['total_visit'], {
      name: 'listing_visits_total_visit_index'
    });

    await queryInterface.addIndex('listing_visits', ['conversion'], {
      name: 'listing_visits_conversion_index'
    });

    // Composite indexes for common queries
    await queryInterface.addIndex('listing_visits', ['listing_id', 'date'], {
      name: 'listing_visits_listing_id_date_index',
      unique: true // Ensure one record per listing per date
    });

    await queryInterface.addIndex('listing_visits', ['date', 'total_visit'], {
      name: 'listing_visits_date_total_visit_index'
    });

    await queryInterface.addIndex('listing_visits', ['listing_id', 'createdAt'], {
      name: 'listing_visits_listing_id_created_at_index'
    });
  },

  async down (queryInterface, Sequelize) {
    await queryInterface.dropTable('listing_visits');
  }
};
