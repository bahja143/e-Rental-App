const { DataTypes } = require('sequelize');

module.exports = (sequelize) => {
  const TypeListing = sequelize.define('TypeListing', {
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
    listing_type_id: {
      type: DataTypes.INTEGER,
      allowNull: false,
      references: {
        model: 'listing_types',
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
    tableName: 'type_listings',
    indexes: [
      // Foreign key indexes
      {
        fields: ['listing_id'],
      },
      {
        fields: ['listing_type_id'],
      },
      // Unique composite index to prevent duplicates
      {
        unique: true,
        fields: ['listing_id', 'listing_type_id'],
      },
      // Date index for sorting
      {
        fields: ['createdAt'],
      },
    ],
  });

  // Associations
  TypeListing.associate = (models) => {
    TypeListing.belongsTo(models.Listing, {
      foreignKey: 'listing_id',
      as: 'listing',
    });
    TypeListing.belongsTo(models.ListingType, {
      foreignKey: 'listing_type_id',
      as: 'listingType',
    });
  };

  return TypeListing;
};
