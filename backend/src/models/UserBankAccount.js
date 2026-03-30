const { DataTypes } = require('sequelize');

module.exports = (sequelize) => {
  const UserBankAccount = sequelize.define('UserBankAccount', {
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
    bank_name: {
      type: DataTypes.STRING,
      allowNull: false,
      validate: {
        notEmpty: true,
        len: [2, 100],
      },
    },
    branch: {
      type: DataTypes.STRING,
      allowNull: false,
      validate: {
        notEmpty: true,
        len: [2, 100],
      },
    },
    account_no: {
      type: DataTypes.STRING,
      allowNull: false,
      unique: true,
      validate: {
        notEmpty: true,
        len: [3, 120],
        is: /^[A-Za-z0-9@._-]+$/,
      },
    },
    account_holder_name: {
      type: DataTypes.STRING,
      allowNull: false,
      validate: {
        notEmpty: true,
        len: [2, 100],
      },
    },
    swift_code: {
      type: DataTypes.STRING,
      allowNull: true,
      validate: {
        len: [8, 11], // SWIFT codes are 8 or 11 characters
        is: /^[A-Z]{4}[A-Z]{2}[A-Z0-9]{2}([A-Z0-9]{3})?$/, // SWIFT code format
      },
    },
    is_default: {
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
    tableName: 'user_bank_accounts',
    indexes: [
      // Foreign key index for user lookups
      {
        fields: ['user_id'],
      },
      // Unique index for account numbers
      {
        unique: true,
        fields: ['account_no'],
      },
      // Index for default account lookups
      {
        fields: ['user_id', 'is_default'],
      },
      // Index for created date sorting
      {
        fields: ['createdAt'],
      },
    ],
  });

  // Associations
  UserBankAccount.associate = (models) => {
    UserBankAccount.belongsTo(models.User, {
      foreignKey: 'user_id',
      as: 'user',
    });
  };

  return UserBankAccount;
};
