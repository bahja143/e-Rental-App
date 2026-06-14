const { DataTypes } = require('sequelize');

module.exports = (sequelize) => {
  const ThirdPartyPayment = sequelize.define('ThirdPartyPayment', {
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
        key: 'id',
      },
    },
    listing_rental_id: {
      type: DataTypes.INTEGER,
      allowNull: true,
      references: {
        model: 'listing_rentals',
        key: 'id',
      },
    },
    provider: {
      type: DataTypes.ENUM('waafi'),
      allowNull: false,
      defaultValue: 'waafi',
    },
    context: {
      type: DataTypes.ENUM('listing_rental'),
      allowNull: false,
      defaultValue: 'listing_rental',
    },
    status: {
      type: DataTypes.ENUM('pending', 'success', 'failed'),
      allowNull: false,
      defaultValue: 'pending',
    },
    amount: {
      type: DataTypes.DECIMAL(15, 2),
      allowNull: false,
      validate: {
        isDecimal: true,
        min: 0,
      },
    },
    currency: {
      type: DataTypes.STRING(10),
      allowNull: false,
      defaultValue: 'USD',
    },
    payer_account: {
      type: DataTypes.STRING(32),
      allowNull: false,
    },
    transaction_ref: {
      type: DataTypes.STRING(255),
      allowNull: false,
      unique: true,
    },
    invoice_id: {
      type: DataTypes.STRING(255),
      allowNull: false,
      unique: true,
    },
    request_id: {
      type: DataTypes.STRING(64),
      allowNull: false,
    },
    response_code: {
      type: DataTypes.STRING(50),
      allowNull: true,
    },
    response_message: {
      type: DataTypes.TEXT,
      allowNull: true,
    },
    raw_response: {
      type: DataTypes.JSON,
      allowNull: true,
    },
    metadata: {
      type: DataTypes.JSON,
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
    tableName: 'third_party_payments',
    indexes: [
      { fields: ['user_id'] },
      { fields: ['listing_rental_id'] },
      { fields: ['provider'] },
      { fields: ['status'] },
      { fields: ['createdAt'] },
    ],
  });

  ThirdPartyPayment.associate = (models) => {
    ThirdPartyPayment.belongsTo(models.User, {
      foreignKey: 'user_id',
      as: 'user',
    });
    ThirdPartyPayment.belongsTo(models.ListingRental, {
      foreignKey: 'listing_rental_id',
      as: 'listingRental',
    });
  };

  return ThirdPartyPayment;
};
