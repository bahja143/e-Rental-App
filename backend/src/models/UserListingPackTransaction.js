'use strict';
const {
  Model
} = require('sequelize');
module.exports = (sequelize, DataTypes) => {
  class UserListingPackTransaction extends Model {
    /**
     * Helper method for defining associations.
     * This method is not a part of Sequelize lifecycle.
     * The `models/index` file will call this method automatically.
     */
    static associate(models) {
      // define association here
      UserListingPackTransaction.belongsTo(models.User, {
        foreignKey: 'user_id',
        as: 'user'
      });
      UserListingPackTransaction.belongsTo(models.ListingPack, {
        foreignKey: 'listing_pack_id',
        as: 'listingPack'
      });
      UserListingPackTransaction.belongsTo(models.Coupon, {
        foreignKey: 'coupon_id',
        as: 'coupon'
      });
      UserListingPackTransaction.belongsTo(models.ListingPack, {
        foreignKey: 'previous_pack_id',
        as: 'previousPack'
      });
    }
  }
  UserListingPackTransaction.init({
    user_id: {
      type: DataTypes.INTEGER,
      allowNull: false,
      references: {
        model: 'users',
        key: 'id'
      }
    },
    listing_pack_id: {
      type: DataTypes.INTEGER,
      allowNull: false,
      references: {
        model: 'listing_packs',
        key: 'id'
      }
    },
    type: {
      type: DataTypes.ENUM('buy', 'upgrade', 'downgrade', 'renew', 'refund', 'adjustment'),
      allowNull: false
    },
    subtotal: {
      type: DataTypes.DECIMAL(10, 2),
      allowNull: false
    },
    coupon_id: {
      type: DataTypes.INTEGER,
      allowNull: true,
      references: {
        model: 'coupons',
        key: 'id'
      }
    },
    discount: {
      type: DataTypes.DECIMAL(10, 2),
      allowNull: true
    },
    total: {
      type: DataTypes.DECIMAL(10, 2),
      allowNull: true
    },
    coupon_code: {
      type: DataTypes.STRING(50),
      allowNull: true
    },
    previous_pack_id: {
      type: DataTypes.INTEGER,
      allowNull: true,
      references: {
        model: 'listing_packs',
        key: 'id'
      }
    },
    adjusted_amount: {
      type: DataTypes.DECIMAL(10, 2),
      allowNull: true
    },
    payment_method: {
      type: DataTypes.ENUM('bank', 'card', 'wallet', 'admin'),
      allowNull: false
    },
    transaction_ref: {
      unique: true,
      type: DataTypes.STRING(255),
      allowNull: false
    },
    status: {
      type: DataTypes.ENUM('pending', 'success', 'failed'),
      allowNull: false,
      defaultValue: 'pending'
    },
    note: {
      type: DataTypes.TEXT,
      allowNull: true
    },
    bank_name: {
      type: DataTypes.STRING(100),
      allowNull: true
    },
    branch: {
      type: DataTypes.STRING(100),
      allowNull: true
    },
    bank_account: {
      type: DataTypes.STRING(50),
      allowNull: true
    },
    account_holder_name: {
      type: DataTypes.STRING(100),
      allowNull: true
    },
    swift: {
      type: DataTypes.STRING(20),
      allowNull: true
    }
  }, {
    sequelize,
    modelName: 'UserListingPackTransaction',
    tableName: 'user_listing_pack_transactions',
    timestamps: true,
    indexes: [
      {
        fields: ['user_id']
      },
      {
        fields: ['listing_pack_id']
      },
      {
        fields: ['coupon_id']
      },
      {
        fields: ['status']
      },
      {
        fields: ['type']
      },
      {
        fields: ['createdAt']
      }
    ]
  });
  return UserListingPackTransaction;
};
