const { DataTypes } = require('sequelize');

module.exports = (sequelize) => {
  const PropertyFeatures = sequelize.define('PropertyFeatures', {
    id: {
      type: DataTypes.INTEGER,
      primaryKey: true,
      autoIncrement: true,
    },
    name_en: {
      type: DataTypes.STRING,
      allowNull: false,
      unique: true,
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
    type: {
      type: DataTypes.ENUM('number', 'string'),
      allowNull: false,
      defaultValue: 'string',
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
    tableName: 'property_features',
  });

  // Associations
  PropertyFeatures.associate = (models) => {
    PropertyFeatures.hasMany(models.ListingFeature, {
      foreignKey: 'property_feature_id',
      as: 'listingFeatures',
    });
  };

  return PropertyFeatures;
};
