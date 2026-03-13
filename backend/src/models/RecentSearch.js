const { DataTypes } = require('sequelize');

module.exports = (sequelize) => {
  const RecentSearch = sequelize.define('RecentSearch', {
    id: {
      type: DataTypes.INTEGER,
      primaryKey: true,
      autoIncrement: true,
    },
    user_id: {
      type: DataTypes.INTEGER,
      allowNull: true,
      references: {
        model: 'users',
        key: 'id',
      },
    },
    device_id: {
      type: DataTypes.UUID,
      allowNull: true,
      validate: {
        isUUID: 4, // UUID v4
      },
    },
    search_text: {
      type: DataTypes.STRING(255),
      allowNull: false,
      validate: {
        notEmpty: true,
        len: [1, 255],
      },
    },
    category_id: {
      type: DataTypes.INTEGER,
      allowNull: true,
      references: {
        model: 'property_categories',
        key: 'id',
      },
    },
    latitude: {
      type: DataTypes.DOUBLE,
      allowNull: false,
      validate: {
        min: -90,
        max: 90,
      },
    },
    longitude: {
      type: DataTypes.DOUBLE,
      allowNull: false,
      validate: {
        min: -180,
        max: 180,
      },
    },
    radius: {
      type: DataTypes.INTEGER,
      allowNull: false,
      defaultValue: 0,
      validate: {
        min: 0,
      },
    },
    created_at: {
      type: DataTypes.DATE,
      allowNull: false,
      defaultValue: DataTypes.NOW,
    },
  }, {
    tableName: 'recent_searches',
    timestamps: false, // Since we have custom created_at
    indexes: [
      {
        fields: ['user_id'],
      },
      {
        fields: ['device_id'],
      },
      {
        fields: ['category_id'],
      },
      {
        fields: ['created_at'],
      },
      {
        fields: ['search_text'],
      },
      {
        fields: ['latitude', 'longitude'],
      },
    ],
  });

  // Associations
  RecentSearch.associate = (models) => {
    RecentSearch.belongsTo(models.User, {
      foreignKey: 'user_id',
      as: 'user',
    });
    RecentSearch.belongsTo(models.PropertyCategory, {
      foreignKey: 'category_id',
      as: 'category',
    });
  };

  return RecentSearch;
};
