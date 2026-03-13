'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up (queryInterface, Sequelize) {
    await queryInterface.createTable('listings', {
      id: {
        allowNull: false,
        autoIncrement: true,
        primaryKey: true,
        type: Sequelize.INTEGER
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
      title: {
        type: Sequelize.STRING(255),
        allowNull: false
      },
      location: {
        type: Sequelize.GEOMETRY('POINT', 4326), // PostGIS POINT with SRID 4326 (WGS84)
        allowNull: false
      },
      lat: {
        type: Sequelize.DECIMAL(10, 8),
        allowNull: false
      },
      lng: {
        type: Sequelize.DECIMAL(11, 8),
        allowNull: false
      },
      address: {
        type: Sequelize.TEXT,
        allowNull: false
      },
      images: {
        type: Sequelize.JSON,
        allowNull: true,
        defaultValue: []
      },
      sell_price: {
        type: Sequelize.INTEGER,
        allowNull: true
      },
      rent_price: {
        type: Sequelize.INTEGER,
        allowNull: true
      },
      rent_type: {
        type: Sequelize.ENUM('daily', 'monthly', 'yearly'),
        allowNull: true
      },
      description: {
        type: Sequelize.TEXT,
        allowNull: true
      },
      availability: {
        type: Sequelize.ENUM('1', '2'),
        allowNull: false,
        defaultValue: '1'
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
    await queryInterface.addIndex('listings', ['user_id'], {
      name: 'listings_user_id_index'
    });

    await queryInterface.addIndex('listings', ['location'], {
      name: 'listings_location_gist_index',
      using: 'GIST' // PostGIS spatial index
    });

    await queryInterface.addIndex('listings', ['lat', 'lng'], {
      name: 'listings_location_index'
    });

    await queryInterface.addIndex('listings', ['sell_price'], {
      name: 'listings_sell_price_index'
    });

    await queryInterface.addIndex('listings', ['rent_price'], {
      name: 'listings_rent_price_index'
    });

    await queryInterface.addIndex('listings', ['rent_type'], {
      name: 'listings_rent_type_index'
    });

    await queryInterface.addIndex('listings', ['availability'], {
      name: 'listings_availability_index'
    });

    await queryInterface.addIndex('listings', ['createdAt'], {
      name: 'listings_created_at_index'
    });
  },

  async down (queryInterface, Sequelize) {
    await queryInterface.dropTable('listings');
  }
};
