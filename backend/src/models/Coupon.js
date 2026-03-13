const { DataTypes } = require('sequelize');

module.exports = (sequelize) => {
  const Coupon = sequelize.define('Coupon', {
    id: {
      type: DataTypes.INTEGER,
      primaryKey: true,
      autoIncrement: true,
    },
    code: {
      type: DataTypes.STRING,
      allowNull: false,
      unique: true,
      validate: {
        notEmpty: true,
        len: [3, 50], // Reasonable length for coupon codes
        isAlphanumeric: true, // Only letters and numbers
      },
    },
    type: {
      type: DataTypes.ENUM('percentage', 'fixed'),
      allowNull: false,
      validate: {
        isIn: [['percentage', 'fixed']],
      },
    },
    value: {
      type: DataTypes.DECIMAL(10, 2),
      allowNull: false,
      validate: {
        min: 0.01, // Minimum value of 0.01
        max: 999999.99, // Reasonable maximum
      },
    },
    use_case: {
      type: DataTypes.ENUM('listing_package', 'promotion_package', 'listing_buy', 'listing_rent'),
      allowNull: false,
      validate: {
        isIn: [['listing_package', 'promotion_package', 'listing_buy', 'listing_rent']],
      },
    },
    min_purchase: {
      type: DataTypes.INTEGER,
      allowNull: true,
      validate: {
        min: 0,
      },
    },
    start_date: {
      type: DataTypes.DATE,
      allowNull: true,
    },
    expire_date: {
      type: DataTypes.DATE,
      allowNull: true,
    },
    usage_limit: {
      type: DataTypes.INTEGER,
      allowNull: true,
      validate: {
        min: 1,
      },
    },
    per_user_limit: {
      type: DataTypes.INTEGER,
      allowNull: true,
      validate: {
        min: 1,
      },
    },
    is_active: {
      type: DataTypes.BOOLEAN,
      allowNull: false,
      defaultValue: true,
    },
    used: {
      type: DataTypes.INTEGER,
      allowNull: false,
      defaultValue: 0,
      validate: {
        min: 0,
      },
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
    tableName: 'coupons',
    indexes: [
      // Unique index for code
      {
        unique: true,
        fields: ['code'],
      },
      // Index for type filtering
      {
        fields: ['type'],
      },
      // Index for use_case filtering
      {
        fields: ['use_case'],
      },
      // Index for active coupons
      {
        fields: ['is_active'],
      },
      // Index for expiration date queries
      {
        fields: ['expire_date'],
      },
      // Composite index for active and non-expired coupons
      {
        fields: ['is_active', 'expire_date'],
      },
      // Index for start_date queries
      {
        fields: ['start_date'],
      },
      // Index for min_purchase filtering
      {
        fields: ['min_purchase'],
      },
      // Index for usage_limit queries
      {
        fields: ['usage_limit'],
      },
      // Index for sorting by creation date
      {
        fields: ['createdAt'],
      },
      // Composite index for common queries
      {
        fields: ['type', 'use_case', 'is_active'],
      },
    ],
    hooks: {
      beforeCreate: async (coupon) => {
        // Convert code to uppercase for consistency
        if (coupon.code) {
          coupon.code = coupon.code.toUpperCase();
        }

        // Validate date ranges
        if (coupon.start_date && coupon.expire_date) {
          if (coupon.start_date >= coupon.expire_date) {
            throw new Error('Start date must be before expire date');
          }
        }

        // Validate percentage type value
        if (coupon.type === 'percentage' && coupon.value > 100) {
          throw new Error('Percentage value cannot exceed 100%');
        }
      },
      beforeUpdate: async (coupon) => {
        // Convert code to uppercase for consistency
        if (coupon.changed('code') && coupon.code) {
          coupon.code = coupon.code.toUpperCase();
        }

        // Validate date ranges on update
        if (coupon.start_date && coupon.expire_date) {
          if (coupon.start_date >= coupon.expire_date) {
            throw new Error('Start date must be before expire date');
          }
        }

        // Validate percentage type value
        if (coupon.type === 'percentage' && coupon.value > 100) {
          throw new Error('Percentage value cannot exceed 100%');
        }
      },
    },
  });

  // Instance methods
  Coupon.prototype.isExpired = function() {
    if (!this.expire_date) return false;
    return new Date() > new Date(this.expire_date);
  };

  Coupon.prototype.isStarted = function() {
    if (!this.start_date) return true;
    return new Date() >= new Date(this.start_date);
  };

  Coupon.prototype.isValid = function() {
    return this.is_active && this.isStarted() && !this.isExpired() &&
           (this.usage_limit === null || this.used < this.usage_limit);
  };

  Coupon.prototype.canApplyToPurchase = function(purchaseAmount) {
    if (this.min_purchase === null) return true;
    return purchaseAmount >= this.min_purchase;
  };

  // Associations
  Coupon.associate = (models) => {
    Coupon.hasMany(models.ListingRental, {
      foreignKey: 'coupon_id',
      as: 'listingRentals',
    });
    Coupon.hasMany(models.ListingBuying, {
      foreignKey: 'coupon_id',
      as: 'listingBuyings',
    });
  };

  return Coupon;
};
