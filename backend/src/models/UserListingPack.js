const { DataTypes } = require('sequelize');

module.exports = (sequelize) => {
  const UserListingPack = sequelize.define('UserListingPack', {
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
        key: 'id'
      },
      onUpdate: 'CASCADE',
      onDelete: 'CASCADE'
    },
    listing_pack_id: {
      type: DataTypes.INTEGER,
      allowNull: false,
      references: {
        model: 'listing_packs',
        key: 'id'
      },
      onUpdate: 'CASCADE',
      onDelete: 'CASCADE'
    },
    start: {
      type: DataTypes.DATE,
      allowNull: false,
      validate: {
        isDate: true,
      },
    },
    end: {
      type: DataTypes.DATE,
      allowNull: false,
      validate: {
        isDate: true,
      },
    },
    status: {
      type: DataTypes.ENUM('active', 'expired', 'cancelled', 'upgraded', 'downgraded'),
      allowNull: false,
      defaultValue: 'active',
      validate: {
        isIn: [['active', 'expired', 'cancelled', 'upgraded', 'downgraded']],
      },
    },
    total_paid: {
      type: DataTypes.DECIMAL(10, 2),
      allowNull: false,
      validate: {
        min: 0,
      },
    },
    remain_balance: {
      type: DataTypes.DECIMAL(10, 2),
      allowNull: false,
      defaultValue: 0,
      validate: {
        min: 0,
      },
    },
    upgrade_from_pack_id: {
      type: DataTypes.INTEGER,
      allowNull: true,
      references: {
        model: 'listing_packs',
        key: 'id'
      },
      onUpdate: 'CASCADE',
      onDelete: 'SET NULL'
    },
    downgrade_to_pack_id: {
      type: DataTypes.INTEGER,
      allowNull: true,
      references: {
        model: 'listing_packs',
        key: 'id'
      },
      onUpdate: 'CASCADE',
      onDelete: 'SET NULL'
    },
    date: {
      type: DataTypes.DATE,
      allowNull: true,
      validate: {
        isDate: true,
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
    tableName: 'user_listing_packs',
    indexes: [
      // Foreign key indexes
      {
        fields: ['user_id'],
      },
      {
        fields: ['listing_pack_id'],
      },
      {
        fields: ['upgrade_from_pack_id'],
      },
      {
        fields: ['downgrade_to_pack_id'],
      },
      // Status index for filtering
      {
        fields: ['status'],
      },
      // Date indexes for sorting and filtering
      {
        fields: ['start'],
      },
      {
        fields: ['end'],
      },
      {
        fields: ['createdAt'],
      },
      // Composite indexes for common queries
      {
        fields: ['user_id', 'status'],
      },
      {
        fields: ['user_id', 'createdAt'],
      },
    ],
  });

  // Instance methods
  UserListingPack.prototype.toJSON = function() {
    const values = { ...this.get() };
    return values;
  };

  // Associations
  UserListingPack.associate = (models) => {
    UserListingPack.belongsTo(models.User, {
      foreignKey: 'user_id',
      as: 'user'
    });
    UserListingPack.belongsTo(models.ListingPack, {
      foreignKey: 'listing_pack_id',
      as: 'listingPack'
    });
    UserListingPack.belongsTo(models.ListingPack, {
      foreignKey: 'upgrade_from_pack_id',
      as: 'upgradedFrom'
    });
    UserListingPack.belongsTo(models.ListingPack, {
      foreignKey: 'downgrade_to_pack_id',
      as: 'downgradedTo'
    });
  };

  return UserListingPack;
};
