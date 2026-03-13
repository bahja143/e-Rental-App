const { DataTypes } = require('sequelize');

module.exports = (sequelize) => {
  const Favourite = sequelize.define('Favourite', {
    user_id: {
      type: DataTypes.INTEGER,
      allowNull: false,
      primaryKey: true,
      references: {
        model: 'users',
        key: 'id',
      },
    },
    listing_id: {
      type: DataTypes.INTEGER,
      allowNull: false,
      primaryKey: true,
      references: {
        model: 'listings',
        key: 'id',
      },
    },
    add_date: {
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
    tableName: 'favourites',
    indexes: [
      // Index for user_id lookups
      {
        fields: ['user_id'],
      },
      // Index for listing_id lookups
      {
        fields: ['listing_id'],
      },
      // Index for add_date sorting
      {
        fields: ['add_date'],
      },
      // Composite unique index for user_id and listing_id
      {
        unique: true,
        fields: ['user_id', 'listing_id'],
      },
    ],
  });

  // Instance methods
  Favourite.prototype.toJSON = function() {
    const values = { ...this.get() };
    return values;
  };

  // Associations
  Favourite.associate = (models) => {
    Favourite.belongsTo(models.User, {
      foreignKey: 'user_id',
      as: 'user',
    });
    Favourite.belongsTo(models.Listing, {
      foreignKey: 'listing_id',
      as: 'listing',
    });
  };

  return Favourite;
};
