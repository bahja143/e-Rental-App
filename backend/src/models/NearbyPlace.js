const { DataTypes } = require('sequelize');

module.exports = (sequelize) => {
  const NearbyPlace = sequelize.define('NearbyPlace', {
    id: {
      type: DataTypes.INTEGER,
      primaryKey: true,
      autoIncrement: true,
    },
    name_en: {
      type: DataTypes.STRING(255),
      allowNull: false,
      unique: true,
      validate: {
        notEmpty: true,
        len: [1, 255],
      },
    },
    name_so: {
      type: DataTypes.STRING(255),
      allowNull: false,
      validate: {
        notEmpty: true,
        len: [1, 255],
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
    tableName: 'nearby_places',
    indexes: [
      // Unique index for name_en
      {
        unique: true,
        fields: ['name_en'],
      },
      // Index for created date sorting
      {
        fields: ['createdAt'],
      },
    ],
  });

  return NearbyPlace;
};
