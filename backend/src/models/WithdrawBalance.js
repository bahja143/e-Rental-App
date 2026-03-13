const { DataTypes } = require('sequelize');

module.exports = (sequelize) => {
  const WithdrawBalance = sequelize.define('WithdrawBalance', {
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
    amount: {
      type: DataTypes.DECIMAL(15, 2),
      allowNull: false,
      validate: {
        min: 0.01,
      },
    },
    status: {
      type: DataTypes.ENUM('requested', 'success', 'failed', 'cancelled'),
      allowNull: false,
      defaultValue: 'requested',
    },
    date: {
      type: DataTypes.DATE,
      allowNull: false,
      defaultValue: DataTypes.NOW,
    },
    before_balance: {
      type: DataTypes.DECIMAL(15, 2),
      allowNull: false,
      validate: {
        min: 0,
      },
    },
    after_balance: {
      type: DataTypes.DECIMAL(15, 2),
      allowNull: false,
      validate: {
        min: 0,
      },
    },
    bank_name: {
      type: DataTypes.STRING(255),
      allowNull: true,
    },
    branch: {
      type: DataTypes.STRING(255),
      allowNull: true,
    },
    bank_account: {
      type: DataTypes.STRING(255),
      allowNull: true,
    },
    account_holder_name: {
      type: DataTypes.STRING(255),
      allowNull: true,
    },
    swift: {
      type: DataTypes.STRING(50),
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
    tableName: 'withdraw_balances',
    indexes: [
      // Index for user_id lookups
      {
        fields: ['user_id'],
      },
      // Index for status filtering
      {
        fields: ['status'],
      },
      // Index for date filtering and sorting
      {
        fields: ['date'],
      },
      // Composite index for user and status filtering
      {
        fields: ['user_id', 'status'],
      },
      // Composite index for user and date filtering
      {
        fields: ['user_id', 'date'],
      },
      // Index for created date sorting
      {
        fields: ['createdAt'],
      },
    ],
  });

  // Associations
  WithdrawBalance.associate = (models) => {
    WithdrawBalance.belongsTo(models.User, {
      foreignKey: 'user_id',
      as: 'user',
    });
  };

  return WithdrawBalance;
};
