const { DataTypes } = require('sequelize');

module.exports = (sequelize) => {
  const Promotion = sequelize.define('Promotion', {
    id: {
      type: DataTypes.INTEGER,
      primaryKey: true,
      autoIncrement: true,
    },
    listing_id: {
      type: DataTypes.INTEGER,
      allowNull: false,
      references: {
        model: 'listings',
        key: 'id'
      },
      onUpdate: 'CASCADE',
      onDelete: 'CASCADE'
    },
    subtotal: {
      type: DataTypes.DECIMAL(10, 2),
      allowNull: false,
      validate: {
        min: 0,
      },
    },
    coupon_code: {
      type: DataTypes.STRING,
      allowNull: true,
      validate: {
        len: [0, 50],
      },
    },
    discount: {
      type: DataTypes.DECIMAL(10, 2),
      allowNull: false,
      defaultValue: 0.00,
      validate: {
        min: 0,
      },
    },
    total: {
      type: DataTypes.DECIMAL(10, 2),
      allowNull: false,
      validate: {
        min: 0,
      },
    },
    start_date: {
      type: DataTypes.DATE,
      allowNull: false,
    },
    end_date: {
      type: DataTypes.DATE,
      allowNull: false,
    },
    coupon_id: {
      type: DataTypes.INTEGER,
      allowNull: true,
      references: {
        model: 'coupons',
        key: 'id'
      },
      onUpdate: 'CASCADE',
      onDelete: 'SET NULL'
    },
    promotion_package_id: {
      type: DataTypes.INTEGER,
      allowNull: true,
      references: {
        model: 'promotion_packs',
        key: 'id'
      },
      onUpdate: 'CASCADE',
      onDelete: 'SET NULL'
    },
    date: {
      type: DataTypes.DATE,
      allowNull: false,
      defaultValue: DataTypes.NOW,
    },
    status: {
      type: DataTypes.ENUM('active', 'expired'),
      allowNull: false,
      defaultValue: 'active',
      validate: {
        isIn: [['active', 'expired']],
      },
    },
    bank_name: {
      type: DataTypes.STRING(255),
      allowNull: true,
    },
    branch: {
      type: DataTypes.STRING(255),
      allowNull: true,
    },
    bank_account: {
      type: DataTypes.STRING(255),
      allowNull: true,
    },
    account_holder_name: {
      type: DataTypes.STRING(255),
      allowNull: true,
    },
    swift: {
      type: DataTypes.STRING(50),
      allowNull: true,
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
    tableName: 'promotions',
    indexes: [
      // Foreign key indexes
      {
        fields: ['listing_id'],
      },
      {
        fields: ['coupon_id'],
      },
      {
        fields: ['promotion_package_id'],
      },
      // Status index
      {
        fields: ['status'],
      },
      // Date indexes
      {
        fields: ['start_date'],
      },
      {
        fields: ['end_date'],
      },
      {
        fields: ['date'],
      },
      // Composite indexes for common queries
      {
        fields: ['listing_id', 'status'],
      },
      {
        fields: ['status', 'start_date', 'end_date'],
      },
      {
        fields: ['coupon_id', 'status'],
      },
      {
        fields: ['promotion_package_id', 'status'],
      },
      // Index for sorting by creation date
      {
        fields: ['createdAt'],
      },
      // Composite index for date range queries
      {
        fields: ['start_date', 'end_date'],
      },
    ],
    hooks: {
      beforeCreate: async (promotion) => {
        // Validate date ranges
        if (promotion.start_date && promotion.end_date) {
          if (promotion.start_date >= promotion.end_date) {
            throw new Error('Start date must be before end date');
          }
        }

        // Auto-set status based on dates
        const now = new Date();
        if (promotion.end_date && promotion.end_date < now) {
          promotion.status = 'expired';
        } else {
          promotion.status = 'active';
        }

        // Validate total calculation if all values are present
        if (promotion.subtotal && promotion.discount !== undefined) {
          const calculatedTotal = parseFloat(promotion.subtotal) - parseFloat(promotion.discount);
          if (calculatedTotal < 0) {
            throw new Error('Discount cannot exceed subtotal');
          }
          if (promotion.total && parseFloat(promotion.total) !== calculatedTotal) {
            throw new Error('Total must equal subtotal minus discount');
          }
          promotion.total = calculatedTotal.toFixed(2);
        }
      },
      beforeUpdate: async (promotion) => {
        // Validate date ranges on update
        if (promotion.start_date && promotion.end_date) {
          if (promotion.start_date >= promotion.end_date) {
            throw new Error('Start date must be before end date');
          }
        }

        // Auto-update status based on dates
        const now = new Date();
        if (promotion.end_date && promotion.end_date < now) {
          promotion.status = 'expired';
        } else if (promotion.start_date && promotion.start_date > now) {
          promotion.status = 'active'; // Future promotions are active
        }

        // Validate total calculation if values changed
        if (promotion.changed('subtotal') || promotion.changed('discount')) {
          const subtotal = parseFloat(promotion.subtotal);
          const discount = parseFloat(promotion.discount || 0);
          const calculatedTotal = subtotal - discount;
          if (calculatedTotal < 0) {
            throw new Error('Discount cannot exceed subtotal');
          }
          promotion.total = calculatedTotal.toFixed(2);
        }
      },
    },
  });

  // Instance methods
  Promotion.prototype.isActive = function() {
    const now = new Date();
    return this.status === 'active' &&
           this.start_date <= now &&
           this.end_date > now;
  };

  Promotion.prototype.isExpired = function() {
    const now = new Date();
    return this.status === 'expired' || this.end_date <= now;
  };

  Promotion.prototype.getDuration = function() {
    const diffTime = Math.abs(this.end_date - this.start_date);
    return Math.ceil(diffTime / (1000 * 60 * 60 * 24)); // days
  };

  // Associations
  Promotion.associate = (models) => {
    Promotion.belongsTo(models.Listing, {
      foreignKey: 'listing_id',
      as: 'listing',
    });
    Promotion.belongsTo(models.Coupon, {
      foreignKey: 'coupon_id',
      as: 'coupon',
    });
    Promotion.belongsTo(models.PromotionPack, {
      foreignKey: 'promotion_package_id',
      as: 'promotionPack',
    });
  };

  return Promotion;
};
