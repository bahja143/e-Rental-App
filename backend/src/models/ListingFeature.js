const { DataTypes } = require('sequelize');

module.exports = (sequelize) => {
  const ListingFeature = sequelize.define('ListingFeature', {
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
    property_feature_id: {
      type: DataTypes.INTEGER,
      allowNull: false,
      references: {
        model: 'property_features',
        key: 'id'
      },
      onUpdate: 'CASCADE',
      onDelete: 'CASCADE'
    },
    value: {
      type: DataTypes.TEXT,
      allowNull: false,
      validate: {
        notEmpty: true,
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
    tableName: 'listing_features',
    indexes: [
      // Foreign key indexes
      {
        fields: ['listing_id'],
      },
      {
        fields: ['property_feature_id'],
      },
      // Composite unique index to prevent duplicate features per listing
      {
        unique: true,
        fields: ['listing_id', 'property_feature_id'],
      },
      // Date index for sorting
      {
        fields: ['createdAt'],
      },
    ],
  });

  // Associations
  ListingFeature.associate = (models) => {
    ListingFeature.belongsTo(models.Listing, {
      foreignKey: 'listing_id',
      as: 'listing',
    });
    ListingFeature.belongsTo(models.PropertyFeatures, {
      foreignKey: 'property_feature_id',
      as: 'propertyFeature',
    });
  };

  return ListingFeature;
};
