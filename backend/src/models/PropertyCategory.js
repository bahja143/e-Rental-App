const { DataTypes } = require('sequelize');

module.exports = (sequelize) => {
  const PropertyCategory = sequelize.define('PropertyCategory', {
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
    createdAt: {
      type: DataTypes.DATE,
      defaultValue: DataTypes.NOW,
    },
    updatedAt: {
      type: DataTypes.DATE,
      defaultValue: DataTypes.NOW,
    },
  }, {
    tableName: 'property_categories',
  });

  // Associations
  PropertyCategory.associate = (models) => {
    PropertyCategory.belongsToMany(models.Listing, {
      through: models.ListingCategory,
      foreignKey: 'property_category_id',
      otherKey: 'listing_id',
      as: 'listings',
    });
  };

  return PropertyCategory;
};
