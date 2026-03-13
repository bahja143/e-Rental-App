const { DataTypes } = require('sequelize');

module.exports = (sequelize) => {
  const ListingPack = sequelize.define('ListingPack', {
    id: {
      type: DataTypes.INTEGER,
      primaryKey: true,
      autoIncrement: true,
    },
    name_en: {
      type: DataTypes.STRING,
      allowNull: false,
      validate: {
        notEmpty: true,
        len: [1, 255],
      },
    },
    name_so: {
      type: DataTypes.STRING,
      allowNull: false,
      validate: {
        notEmpty: true,
        len: [1, 255],
      },
    },
    price: {
      type: DataTypes.INTEGER,
      allowNull: false,
      validate: {
        min: 0,
      },
    },
    duration: {
      type: DataTypes.INTEGER,
      allowNull: false,
      validate: {
        min: 1,
      },
    },
    features: {
      type: DataTypes.JSON,
      allowNull: true,
      defaultValue: null,
    },
    listing_amount: {
      type: DataTypes.INTEGER,
      allowNull: false,
      validate: {
        min: 0,
      },
    },
    display: {
      type: DataTypes.TINYINT,
      allowNull: false,
      defaultValue: 1,
      validate: {
        isIn: [[0, 1]],
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
    tableName: 'listing_packs',
    indexes: [
      // Index for name_en searches
      {
        fields: ['name_en'],
      },
      // Index for name_so searches
      {
        fields: ['name_so'],
      },
      // Index for price filtering and sorting
      {
        fields: ['price'],
      },
      // Index for duration filtering
      {
        fields: ['duration'],
      },
      // Index for listing_amount filtering
      {
        fields: ['listing_amount'],
      },
      // Index for display filtering
      {
        fields: ['display'],
      },
      // Index for created date sorting
      {
        fields: ['createdAt'],
      },
    ],
  });

  // Instance methods
  ListingPack.prototype.toJSON = function() {
    const values = { ...this.get() };
    return values;
  };

  // Associations (if needed in future)
  ListingPack.associate = (models) => {
    // Add associations here if needed
  };

  return ListingPack;
};
