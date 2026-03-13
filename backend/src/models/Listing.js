const { DataTypes } = require('sequelize');
const config = require('../config/config');

const isMySQL = config.isMySQL || process.env.NODE_ENV === 'test';

module.exports = (sequelize) => {
  const Listing = sequelize.define('Listing', {
    id: {
      type: DataTypes.INTEGER,
      primaryKey: true,
      autoIncrement: true,
    },
    user_id: {
      type: DataTypes.INTEGER,
      allowNull: false,
      references: {
        model: 'users',
        key: 'id'
      },
      onUpdate: 'CASCADE',
      onDelete: 'CASCADE'
    },
    title: {
      type: DataTypes.STRING(255),
      allowNull: false,
      validate: {
        notEmpty: true,
        len: [1, 255],
      },
    },
    location: {
      type: (process.env.NODE_ENV === 'test' || isMySQL) ? DataTypes.JSON : DataTypes.GEOMETRY('POINT', 4326),
      allowNull: (process.env.NODE_ENV === 'test' || isMySQL) ? true : false,
    },
    lat: {
      type: DataTypes.DECIMAL(10, 8),
      allowNull: false,
      validate: {
        isDecimal: true,
        min: -90,
        max: 90,
      },
    },
    lng: {
      type: DataTypes.DECIMAL(11, 8),
      allowNull: false,
      validate: {
        isDecimal: true,
        min: -180,
        max: 180,
      },
    },
    address: {
      type: DataTypes.TEXT,
      allowNull: false,
      validate: {
        notEmpty: true,
      },
    },
    images: {
      type: DataTypes.JSON,
      allowNull: true,
      defaultValue: [],
      validate: {
        isArray(value) {
          if (!Array.isArray(value)) {
            throw new Error('Images must be an array');
          }
        },
      },
    },
    sell_price: {
      type: DataTypes.INTEGER,
      allowNull: true,
      validate: {
        min: 0,
      },
    },
    rent_price: {
      type: DataTypes.INTEGER,
      allowNull: true,
      validate: {
        min: 0,
      },
    },
    rent_type: {
      type: DataTypes.ENUM('daily', 'monthly', 'yearly'),
      allowNull: true,
    },
    description: {
      type: DataTypes.TEXT,
      allowNull: true,
    },
    availability: {
      type: DataTypes.ENUM('1', '2'),
      allowNull: false,
      defaultValue: '1',
    },
    createdAt: {
      type: DataTypes.DATE,
      defaultValue: DataTypes.NOW,
    },
    updatedAt: {
      type: DataTypes.DATE,
      defaultValue: DataTypes.NOW,
    },
  }, {
    tableName: 'listings',
    hooks: {
      beforeCreate: (listing, options) => {
        if (process.env.NODE_ENV === 'test' || isMySQL) {
          listing.location = { type: 'Point', coordinates: [parseFloat(listing.lng), parseFloat(listing.lat)] };
        } else {
          listing.location = sequelize.fn('ST_SetSRID', sequelize.fn('ST_MakePoint', listing.lng, listing.lat), 4326);
        }
      },
      beforeUpdate: (listing, options) => {
        if (listing.changed('lat') || listing.changed('lng')) {
          if (process.env.NODE_ENV === 'test' || isMySQL) {
            listing.location = { type: 'Point', coordinates: [parseFloat(listing.lng), parseFloat(listing.lat)] };
          } else {
            listing.location = sequelize.fn('ST_SetSRID', sequelize.fn('ST_MakePoint', listing.lng, listing.lat), 4326);
          }
        }
      },
      beforeBulkCreate: (listings, options) => {
        listings.forEach(listing => {
          if (process.env.NODE_ENV === 'test' || isMySQL) {
            listing.location = { type: 'Point', coordinates: [parseFloat(listing.lng), parseFloat(listing.lat)] };
          } else {
            listing.location = sequelize.fn('ST_SetSRID', sequelize.fn('ST_MakePoint', listing.lng, listing.lat), 4326);
          }
        });
      }
    },
    indexes: [
      // Foreign key index
      {
        fields: ['user_id'],
      },
      // PostGIS spatial index (PostgreSQL only; MySQL uses lat/lng for distance)
      ...(process.env.NODE_ENV !== 'test' && !isMySQL ? [{
        fields: ['location'],
        using: 'GIST',
      }] : []),
      // Location index for non-spatial queries
      {
        fields: ['lat', 'lng'],
      },
      // Price indexes for filtering
      {
        fields: ['sell_price'],
      },
      {
        fields: ['rent_price'],
      },
      // Type indexes
      {
        fields: ['rent_type'],
      },
      {
        fields: ['availability'],
      },
      // Date index for sorting
      {
        fields: ['createdAt'],
      },
    ],
  });

  // Associations
  Listing.associate = (models) => {
    Listing.belongsTo(models.User, {
      foreignKey: 'user_id',
      as: 'user',
    });
    Listing.belongsToMany(models.ListingType, {
      through: models.TypeListing,
      foreignKey: 'listing_id',
      otherKey: 'listing_type_id',
      as: 'listingTypes',
    });
    Listing.belongsToMany(models.PropertyCategory, {
      through: models.ListingCategory,
      foreignKey: 'listing_id',
      otherKey: 'property_category_id',
      as: 'propertyCategories',
    });
    Listing.hasMany(models.ListingFeature, {
      foreignKey: 'listing_id',
      as: 'listingFeatures',
    });
    Listing.hasMany(models.ListingFacility, {
      foreignKey: 'listing_id',
      as: 'listingFacilities',
    });
    Listing.hasMany(models.ListingPlace, {
      foreignKey: 'listing_id',
      as: 'listingPlaces',
    });
    Listing.hasMany(models.ListingReview, {
      foreignKey: 'listing_id',
      as: 'listingReviews',
    });
    Listing.hasMany(models.ListingVisit, {
      foreignKey: 'listing_id',
      as: 'listingVisits',
    });
    Listing.hasMany(models.ListingRental, {
      foreignKey: 'list_id',
      as: 'listingRentals',
    });
    Listing.hasMany(models.ListingBuying, {
      foreignKey: 'listing_id',
      as: 'listingBuyings',
    });
    Listing.hasMany(models.Favourite, {
      foreignKey: 'listing_id',
      as: 'favourites',
    });
  };

  return Listing;
};
