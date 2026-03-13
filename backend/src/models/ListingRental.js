const { DataTypes } = require('sequelize');

module.exports = (sequelize) => {
  const ListingRental = sequelize.define('ListingRental', {
    id: {
      type: DataTypes.INTEGER,
      primaryKey: true,
      autoIncrement: true,
    },
    list_id: {
      type: DataTypes.INTEGER,
      allowNull: false,
      references: {
        model: 'listings',
        key: 'id',
      },
    },
    renter_id: {
      type: DataTypes.INTEGER,
      allowNull: false,
      references: {
        model: 'users',
        key: 'id',
      },
    },
    start_date: {
      type: DataTypes.DATE,
      allowNull: false,
      validate: {
        isDate: true,
      },
    },
    end_date: {
      type: DataTypes.DATE,
      allowNull: false,
      validate: {
        isDate: true,
        isAfterStartDate(value) {
          if (value && this.start_date && new Date(value) <= new Date(this.start_date)) {
            throw new Error('End date must be after start date');
          }
        },
      },
    },
    rent_type: {
      type: DataTypes.ENUM('daily', 'monthly', 'yearly'),
      allowNull: false,
      validate: {
        isIn: [['daily', 'monthly', 'yearly']],
      },
    },
    status: {
      type: DataTypes.ENUM('pending', 'confirmed', 'cancelled', 'completed'),
      allowNull: false,
      defaultValue: 'pending',
      validate: {
        isIn: [['pending', 'confirmed', 'cancelled', 'completed']],
      },
    },
    date: {
      type: DataTypes.DATE,
      allowNull: false,
      defaultValue: DataTypes.NOW,
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
    subtotal: {
      type: DataTypes.DECIMAL(15, 2),
      allowNull: false,
      validate: {
        isDecimal: true,
        min: 0,
      },
    },
    coupon_code: {
      type: DataTypes.STRING(50),
      allowNull: true,
    },
    coupon_id: {
      type: DataTypes.INTEGER,
      allowNull: true,
      references: {
        model: 'coupons',
        key: 'id',
      },
    },
    discount: {
      type: DataTypes.DECIMAL(15, 2),
      allowNull: false,
      defaultValue: 0,
      validate: {
        isDecimal: true,
        min: 0,
      },
    },
    total: {
      type: DataTypes.DECIMAL(15, 2),
      allowNull: false,
      validate: {
        isDecimal: true,
        min: 0,
      },
    },
    commission: {
      type: DataTypes.DECIMAL(15, 2),
      allowNull: false,
      defaultValue: 0,
      validate: {
        isDecimal: true,
        min: 0,
      },
    },
    sellers_value: {
      type: DataTypes.DECIMAL(15, 2),
      allowNull: false,
      validate: {
        isDecimal: true,
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
    tableName: 'listing_rentals',
    indexes: [
      // Foreign key indexes
      {
        fields: ['list_id'],
      },
      {
        fields: ['renter_id'],
      },
      {
        fields: ['coupon_id'],
      },
      // Status and type indexes for filtering
      {
        fields: ['status'],
      },
      {
        fields: ['rent_type'],
      },
      // Date indexes for filtering and sorting
      {
        fields: ['start_date'],
      },
      {
        fields: ['end_date'],
      },
      {
        fields: ['date'],
      },
      {
        fields: ['createdAt'],
      },
      // Composite indexes for common queries
      {
        fields: ['list_id', 'status'],
      },
      {
        fields: ['renter_id', 'status'],
      },
      {
        fields: ['list_id', 'start_date'],
      },
      {
        fields: ['list_id', 'end_date'],
      },
      {
        fields: ['renter_id', 'createdAt'],
      },
      // Index for date range queries
      {
        fields: ['start_date', 'end_date'],
      },
    ],
    hooks: {
      beforeCreate: async (rental) => {
        // Validate date logic
        if (rental.start_date && rental.end_date) {
          if (new Date(rental.end_date) <= new Date(rental.start_date)) {
            throw new Error('End date must be after start date');
          }
        }

        // Validate total calculation (basic check)
        if (rental.subtotal && rental.discount && rental.total) {
          const expectedTotal = parseFloat(rental.subtotal) - parseFloat(rental.discount);
          if (Math.abs(parseFloat(rental.total) - expectedTotal) > 0.01) {
            throw new Error('Total must equal subtotal minus discount');
          }
        }
      },
      beforeUpdate: async (rental) => {
        // Validate date logic on update
        if (rental.start_date && rental.end_date) {
          if (new Date(rental.end_date) <= new Date(rental.start_date)) {
            throw new Error('End date must be after start date');
          }
        }

        // Validate total calculation on update
        if (rental.subtotal && rental.discount && rental.total) {
          const expectedTotal = parseFloat(rental.subtotal) - parseFloat(rental.discount);
          if (Math.abs(parseFloat(rental.total) - expectedTotal) > 0.01) {
            throw new Error('Total must equal subtotal minus discount');
          }
        }
      },
    },
  });

  // Associations
  ListingRental.associate = (models) => {
    ListingRental.belongsTo(models.Listing, {
      foreignKey: 'list_id',
      as: 'listing',
    });
    ListingRental.belongsTo(models.User, {
      foreignKey: 'renter_id',
      as: 'renter',
    });
    ListingRental.belongsTo(models.Coupon, {
      foreignKey: 'coupon_id',
      as: 'coupon',
    });
  };

  return ListingRental;
};
