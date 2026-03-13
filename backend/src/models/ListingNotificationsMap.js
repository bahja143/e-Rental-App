const { DataTypes } = require('sequelize');

module.exports = (sequelize) => {
  const ListingNotificationsMap = sequelize.define('ListingNotificationsMap', {
    id: {
      type: DataTypes.INTEGER,
      primaryKey: true,
      autoIncrement: true,
    },
    listing_id: {
      type: DataTypes.INTEGER,
      allowNull: false,
      references: {
        model: 'listings',
        key: 'id',
      },
      onUpdate: 'CASCADE',
      onDelete: 'CASCADE',
    },
    user_id: {
      type: DataTypes.INTEGER,
      allowNull: false,
      references: {
        model: 'users',
        key: 'id',
      },
      onUpdate: 'CASCADE',
      onDelete: 'CASCADE',
    },
    sent_at: {
      type: DataTypes.DATE,
      allowNull: false,
      defaultValue: DataTypes.NOW,
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
    tableName: 'listing_notifications_maps',
    indexes: [
      // Foreign key indexes
      {
        fields: ['listing_id'],
      },
      {
        fields: ['user_id'],
      },
      // Date index for sent_at filtering
      {
        fields: ['sent_at'],
      },
      // Composite indexes for common queries
      {
        fields: ['listing_id', 'user_id'],
        unique: true, // Prevent duplicate notifications for same listing-user pair
      },
      {
        fields: ['user_id', 'sent_at'],
      },
      // Date index for sorting
      {
        fields: ['createdAt'],
      },
    ],
  });

  // Instance methods
  ListingNotificationsMap.prototype.toJSON = function() {
    const values = { ...this.get() };
    return values;
  };

  // Associations
  ListingNotificationsMap.associate = (models) => {
    ListingNotificationsMap.belongsTo(models.Listing, {
      foreignKey: 'listing_id',
      as: 'listing',
    });
    ListingNotificationsMap.belongsTo(models.User, {
      foreignKey: 'user_id',
      as: 'user',
    });
  };

  return ListingNotificationsMap;
};
