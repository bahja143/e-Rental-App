const { DataTypes } = require('sequelize');

module.exports = (sequelize) => {
  const ListingFacility = sequelize.define('ListingFacility', {
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
    facility_id: {
      type: DataTypes.INTEGER,
      allowNull: false,
      references: {
        model: 'facilities',
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
    tableName: 'listing_facilities',
    indexes: [
      // Foreign key indexes
      {
        fields: ['listing_id'],
      },
      {
        fields: ['facility_id'],
      },
      // Composite unique index to prevent duplicate facilities per listing
      {
        unique: true,
        fields: ['listing_id', 'facility_id'],
      },
      // Date index for sorting
      {
        fields: ['createdAt'],
      },
    ],
  });

  // Associations
  ListingFacility.associate = (models) => {
    ListingFacility.belongsTo(models.Listing, {
      foreignKey: 'listing_id',
      as: 'listing',
    });
    ListingFacility.belongsTo(models.Facility, {
      foreignKey: 'facility_id',
      as: 'facility',
    });
  };

  return ListingFacility;
};
