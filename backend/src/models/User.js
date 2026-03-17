const { DataTypes } = require('sequelize');
const config = require('../config/config');
const bcrypt = require('bcryptjs');

const isMySQL = config.isMySQL;
const isTest = process.env.NODE_ENV === 'test';

module.exports = (sequelize) => {
  const User = sequelize.define('User', {
    id: {
      type: DataTypes.INTEGER,
      primaryKey: true,
      autoIncrement: true,
    },
    name: {
      type: DataTypes.STRING,
      allowNull: false,
      validate: {
        notEmpty: true,
        len: [2, 100],
      },
    },
    email: {
      type: DataTypes.STRING,
      allowNull: false,
      unique: true,
      validate: {
        isEmail: true,
      },
    },
    phone: {
      type: DataTypes.STRING,
      allowNull: true,
      unique: true,
      validate: {
        is: /^[\+]?[1-9][\d]{0,15}$/, // Basic phone validation
      },
    },
    password: {
      type: DataTypes.STRING,
      allowNull: false,
      validate: {
        len: [6, 255], // Minimum 6 characters
      },
    },
    city: {
      type: DataTypes.STRING(255),
      allowNull: true,
    },
    ...(!isTest && {
      location: {
        type: isMySQL ? DataTypes.JSON : DataTypes.GEOMETRY('POINT', 4326),
        allowNull: true,
      },
    }),
    lat: {
      type: DataTypes.DECIMAL(10, 8),
      allowNull: true,
    },
    lng: {
      type: DataTypes.DECIMAL(11, 8),
      allowNull: true,
    },
    two_factor_code: {
      type: DataTypes.STRING,
      allowNull: true,
    },
    two_factor_expire: {
      type: DataTypes.DATE,
      allowNull: true,
    },
    looking_for: {
      type: DataTypes.ENUM('buy', 'sale', 'rent', 'monitor_my_property', 'just_look_around'),
      allowNull: true,
      defaultValue: 'just_look_around',
    },
    looking_for_options: {
      type: DataTypes.JSON,
      allowNull: true,
      comment: 'Array of intents e.g. ["buy","rent","sale"]',
    },
    profile_picture_url: {
      type: DataTypes.TEXT,
      allowNull: true,
      validate: {
        isValidUrl(value) {
          if (value == null || value === '') return;
          if (typeof value !== 'string' || !/^https?:\/\/.+/.test(value.trim())) {
            throw new Error('profile_picture_url must be a valid http(s) URL');
          }
        },
      },
    },
    pending_balance: {
      type: DataTypes.INTEGER,
      allowNull: false,
      defaultValue: 0,
    },
    available_balance: {
      type: DataTypes.INTEGER,
      allowNull: false,
      defaultValue: 0,
    },
    looking_for_set: {
      type: DataTypes.BOOLEAN,
      allowNull: false,
      defaultValue: false,
    },
    category_set: {
      type: DataTypes.BOOLEAN,
      allowNull: false,
      defaultValue: false,
    },
    preferred_property_types: {
      type: DataTypes.JSON,
      allowNull: true,
      comment: 'Array of property type names e.g. ["Apartment","Villa","House","Cottage"]',
    },
    role: {
      type: DataTypes.ENUM('admin', 'user'),
      allowNull: false,
      defaultValue: 'user',
    },
    user_type: {
      type: DataTypes.ENUM('buyer', 'seller'),
      allowNull: false,
      defaultValue: 'buyer',
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
    tableName: 'users',
    indexes: [
      // Index for email lookups
      {
        unique: true,
        fields: ['email'],
      },
      // Index for phone lookups (nullable unique)
      {
        unique: true,
        fields: ['phone'],
        where: {
          phone: {
            [sequelize.Sequelize.Op.ne]: null,
          },
        },
      },
      // PostGIS spatial index (PostgreSQL only)
      ...(!isTest && !isMySQL ? [{
        fields: ['location'],
        using: 'GIST',
      }] : []),
      // Index for city searches
      {
        fields: ['city'],
      },
      // Index for looking_for filter
      {
        fields: ['looking_for'],
      },
      // Index for balance queries
      {
        fields: ['available_balance'],
      },
      // Composite index for common filters
      {
        fields: ['city', 'looking_for'],
      },
      // Index for created date sorting
      {
        fields: ['createdAt'],
      },
    ],
    hooks: {
      beforeCreate: async (user) => {
        if (!isTest && user.password) {
          const saltRounds = 12;
          user.password = await bcrypt.hash(user.password, saltRounds);
        }
        if (isMySQL && user.lat != null && user.lng != null) {
          user.location = { type: 'Point', coordinates: [parseFloat(user.lng), parseFloat(user.lat)] };
        }
      },
      beforeUpdate: async (user) => {
        if (!isTest && user.changed('password')) {
          const saltRounds = 12;
          user.password = await bcrypt.hash(user.password, saltRounds);
        }
        if (isMySQL && (user.changed('lat') || user.changed('lng')) && user.lat != null && user.lng != null) {
          user.location = { type: 'Point', coordinates: [parseFloat(user.lng), parseFloat(user.lat)] };
        }
      },
    },
  });

  // Instance methods
  User.prototype.checkPassword = async function(password) {
    return await bcrypt.compare(password, this.password);
  };

  User.prototype.toJSON = function() {
    const values = { ...this.get() };
    delete values.password;
    delete values.two_factor_code;
    delete values.two_factor_expire;
    return values;
  };

  // Associations
  User.associate = (models) => {
    User.belongsToMany(models.StateCategory, {
      through: models.UserStateCategory,
      foreignKey: 'user_id',
      otherKey: 'state_categories_id',
      as: 'stateCategories',
    });
    User.hasMany(models.UserBankAccount, {
      foreignKey: 'user_id',
      as: 'bankAccounts',
    });
    User.hasMany(models.ListingReview, {
      foreignKey: 'user_id',
      as: 'listingReviews',
    });
    User.hasMany(models.WithdrawBalance, {
      foreignKey: 'user_id',
      as: 'withdrawBalances',
    });
    User.hasMany(models.ListingRental, {
      foreignKey: 'renter_id',
      as: 'listingRentals',
    });
    User.hasMany(models.ListingBuying, {
      foreignKey: 'buyer_id',
      as: 'listingBuyings',
    });
    User.hasMany(models.Favourite, {
      foreignKey: 'user_id',
      as: 'favourites',
    });
    User.hasMany(models.Notification, {
      foreignKey: 'user_id',
      as: 'notifications',
    });
    User.hasMany(models.UserDevice, {
      foreignKey: 'user_id',
      as: 'userDevices',
    });
  };

  return User;
};
