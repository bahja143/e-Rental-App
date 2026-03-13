const { DataTypes } = require('sequelize');

module.exports = (sequelize) => {
  const CompanyEarning = sequelize.define('CompanyEarning', {
    id: {
      type: DataTypes.INTEGER,
      primaryKey: true,
      autoIncrement: true,
    },
    date: {
      type: DataTypes.DATEONLY,
      allowNull: false,
      validate: {
        isDate: true,
        notNull: true,
      },
    },
    commission: {
      type: DataTypes.DECIMAL(10, 2),
      allowNull: false,
      defaultValue: 0.00,
      validate: {
        isDecimal: true,
        min: 0,
        max: 99999999.99,
      },
    },
    listing: {
      type: DataTypes.DECIMAL(10, 2),
      allowNull: false,
      defaultValue: 0.00,
      validate: {
        isDecimal: true,
        min: 0,
        max: 99999999.99,
      },
    },
    promotion: {
      type: DataTypes.DECIMAL(10, 2),
      allowNull: false,
      defaultValue: 0.00,
      validate: {
        isDecimal: true,
        min: 0,
        max: 99999999.99,
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
    tableName: 'company_earnings',
    indexes: [
      // Index for date-based queries
      {
        fields: ['date'],
      },
      // Index for created date sorting
      {
        fields: ['createdAt'],
      },
      // Composite index for date range queries
      {
        fields: ['date', 'createdAt'],
      },
    ],
  });

  // Instance methods
  CompanyEarning.prototype.toJSON = function() {
    const values = { ...this.get() };
    return values;
  };

  // Class methods for calculations
  CompanyEarning.getTotalEarnings = async function(startDate, endDate) {
    const whereClause = {};
    if (startDate && endDate) {
      whereClause.date = {
        [sequelize.Sequelize.Op.between]: [startDate, endDate],
      };
    }

    const result = await this.findAll({
      where: whereClause,
      attributes: [
        [sequelize.fn('SUM', sequelize.col('commission')), 'totalCommission'],
        [sequelize.fn('SUM', sequelize.col('listing')), 'totalListing'],
        [sequelize.fn('SUM', sequelize.col('promotion')), 'totalPromotion'],
        [sequelize.literal('SUM(commission) + SUM(listing) + SUM(promotion)'), 'totalEarnings'],
      ],
      raw: true,
    });

    return result[0] || {
      totalCommission: 0,
      totalListing: 0,
      totalPromotion: 0,
      totalEarnings: 0,
    };
  };

  // Associations (if needed in future)
  CompanyEarning.associate = (models) => {
    // Add associations here if needed
  };

  return CompanyEarning;
};
