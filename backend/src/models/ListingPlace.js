const { DataTypes } = require('sequelize');

module.exports = (sequelize) => {
  const ListingPlace = sequelize.define('ListingPlace', {
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
    nearby_place_id: {
      type: DataTypes.INTEGER,
      allowNull: false,
      references: {
        model: 'nearby_places',
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
    tableName: 'listing_places',
    indexes: [
      // Foreign key indexes
      {
        fields: ['listing_id'],
      },
      {
        fields: ['nearby_place_id'],
      },
      // Composite unique index to prevent duplicate places per listing
      {
        unique: true,
        fields: ['listing_id', 'nearby_place_id'],
      },
      // Date index for sorting
      {
        fields: ['createdAt'],
      },
    ],
  });

  // Associations
  ListingPlace.associate = (models) => {
    ListingPlace.belongsTo(models.Listing, {
      foreignKey: 'listing_id',
      as: 'listing',
    });
    ListingPlace.belongsTo(models.NearbyPlace, {
      foreignKey: 'nearby_place_id',
      as: 'nearbyPlace',
    });
  };

  return ListingPlace;
};
