const { DataTypes } = require('sequelize');

module.exports = (sequelize) => {
  const UserDevice = sequelize.define('UserDevice', {
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
    device_type: {
      type: DataTypes.STRING(20),
      allowNull: false,
      validate: {
        notEmpty: true,
        len: [1, 20],
      },
    },
    fcm_token: {
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
    tableName: 'user_devices',
    indexes: [
      // Index for user_id lookups
      {
        fields: ['user_id'],
      },
      // Index for device_type filtering
      {
        fields: ['device_type'],
      },
      // Index for created date sorting
      {
        fields: ['createdAt'],
      },
      // Composite index for user device type combinations
      {
        fields: ['user_id', 'device_type'],
      },
    ],
  });

  // Instance methods
  UserDevice.prototype.toJSON = function() {
    const values = { ...this.get() };
    return values;
  };

  // Associations
  UserDevice.associate = (models) => {
    UserDevice.belongsTo(models.User, {
      foreignKey: 'user_id',
      as: 'user',
    });
  };

  return UserDevice;
};
