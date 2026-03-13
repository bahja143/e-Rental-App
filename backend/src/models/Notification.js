const { DataTypes } = require('sequelize');

module.exports = (sequelize) => {
  const Notification = sequelize.define('Notification', {
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
    },
    type: {
      type: DataTypes.STRING(255),
      allowNull: false,
      validate: {
        notEmpty: true,
        len: [1, 255],
      },
    },
    title: {
      type: DataTypes.STRING(255),
      allowNull: false,
      validate: {
        notEmpty: true,
        len: [1, 255],
      },
    },
    message: {
      type: DataTypes.TEXT,
      allowNull: false,
      validate: {
        notEmpty: true,
      },
    },
    data: {
      type: DataTypes.JSON,
      allowNull: true,
      defaultValue: null,
    },
    is_read: {
      type: DataTypes.BOOLEAN,
      allowNull: false,
      defaultValue: false,
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
    tableName: 'notifications',
    indexes: [
      // Index for user_id lookups
      {
        fields: ['user_id'],
      },
      // Index for type filtering
      {
        fields: ['type'],
      },
      // Index for is_read filtering
      {
        fields: ['is_read'],
      },
      // Index for created date sorting
      {
        fields: ['createdAt'],
      },
      // Composite index for user notifications filtering by read status
      {
        fields: ['user_id', 'is_read'],
      },
      // Composite index for user notifications sorting by date
      {
        fields: ['user_id', 'createdAt'],
      },
    ],
  });

  // Instance methods
  Notification.prototype.toJSON = function() {
    const values = { ...this.get() };
    return values;
  };

  // Associations
  Notification.associate = (models) => {
    Notification.belongsTo(models.User, {
      foreignKey: 'user_id',
      as: 'user',
    });
  };

  return Notification;
};
