const { DataTypes } = require('sequelize');

module.exports = (sequelize) => {
  const ListingCategory = sequelize.define('ListingCategory', {
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
    property_category_id: {
      type: DataTypes.INTEGER,
      allowNull: false,
      references: {
        model: 'property_categories',
        key: 'id'
      },
      onUpdate: 'CASCADE',
      onDelete: 'CASCADE'
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
    tableName: 'listing_categories',
    indexes: [
      // Foreign key indexes
      {
        fields: ['listing_id'],
      },
      {
        fields: ['property_category_id'],
      },
      // Unique composite index to prevent duplicate listing-category pairs
      {
        unique: true,
        fields: ['listing_id', 'property_category_id'],
      },
      // Date index for sorting
      {
        fields: ['createdAt'],
      },
    ],
  });

  // Associations
  ListingCategory.associate = (models) => {
    ListingCategory.belongsTo(models.Listing, {
      foreignKey: 'listing_id',
      as: 'listing',
    });
    ListingCategory.belongsTo(models.PropertyCategory, {
      foreignKey: 'property_category_id',
      as: 'propertyCategory',
    });
  };

  return ListingCategory;
};
