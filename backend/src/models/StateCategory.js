const { DataTypes } = require('sequelize');

module.exports = (sequelize) => {
  const StateCategory = sequelize.define('StateCategory', {
    id: {
      type: DataTypes.INTEGER,
      primaryKey: true,
      autoIncrement: true,
    },
    name_en: {
      type: DataTypes.STRING,
      allowNull: false,
    },
    name_so: {
      type: DataTypes.STRING,
      allowNull: false,
    },
    thumb_url: {
      type: DataTypes.STRING,
      allowNull: true,
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
    tableName: 'state_categories',
  });

  // Associations
  StateCategory.associate = (models) => {
    StateCategory.belongsToMany(models.User, {
      through: models.UserStateCategory,
      foreignKey: 'state_categories_id',
      otherKey: 'user_id',
      as: 'users',
    });
  };

  return StateCategory;
};
