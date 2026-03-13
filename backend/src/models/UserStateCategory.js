const { DataTypes } = require('sequelize');

module.exports = (sequelize) => {
  const UserStateCategory = sequelize.define('UserStateCategory', {
    id: {
      type: DataTypes.INTEGER,
      primaryKey: true,
      autoIncrement: true,
    },
    user_id: {
      type: DataTypes.INTEGER,
      allowNull: false,
      references: {
        model: 'users',
        key: 'id',
      },
      onDelete: 'CASCADE',
      onUpdate: 'CASCADE',
    },
    state_categories_id: {
      type: DataTypes.INTEGER,
      allowNull: false,
      references: {
        model: 'state_categories',
        key: 'id',
      },
      onDelete: 'CASCADE',
      onUpdate: 'CASCADE',
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
    tableName: 'user_state_categories',
    indexes: [
      // Composite unique index to prevent duplicate user-category pairs
      {
        unique: true,
        fields: ['user_id', 'state_categories_id'],
      },
      // Index for user lookups
      {
        fields: ['user_id'],
      },
      // Index for state category lookups
      {
        fields: ['state_categories_id'],
      },
      // Index for created date sorting
      {
        fields: ['createdAt'],
      },
    ],
  });

  // Associations
  UserStateCategory.associate = (models) => {
    UserStateCategory.belongsTo(models.User, {
      foreignKey: 'user_id',
      as: 'user',
    });
    UserStateCategory.belongsTo(models.StateCategory, {
      foreignKey: 'state_categories_id',
      as: 'stateCategory',
    });
  };

  return UserStateCategory;
};
