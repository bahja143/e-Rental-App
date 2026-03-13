const { DataTypes } = require('sequelize');

module.exports = (sequelize) => {
  const ListingVisit = sequelize.define('ListingVisit', {
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
        key: 'id'
      },
      onUpdate: 'CASCADE',
      onDelete: 'CASCADE'
    },
    total_impression: {
      type: DataTypes.INTEGER,
      allowNull: true,
      defaultValue: 0,
      validate: {
        min: 0,
        isInt: true,
      },
    },
    app_impression: {
      type: DataTypes.INTEGER,
      allowNull: true,
      defaultValue: 0,
      validate: {
        min: 0,
        isInt: true,
      },
    },
    ad_impression: {
      type: DataTypes.INTEGER,
      allowNull: true,
      defaultValue: 0,
      validate: {
        min: 0,
        isInt: true,
      },
    },
    total_visit: {
      type: DataTypes.INTEGER,
      allowNull: true,
      defaultValue: 0,
      validate: {
        min: 0,
        isInt: true,
      },
    },
    app_visit: {
      type: DataTypes.INTEGER,
      allowNull: true,
      defaultValue: 0,
      validate: {
        min: 0,
        isInt: true,
      },
    },
    ad_visit: {
      type: DataTypes.INTEGER,
      allowNull: true,
      defaultValue: 0,
      validate: {
        min: 0,
        isInt: true,
      },
    },
    share_visit: {
      type: DataTypes.INTEGER,
      allowNull: true,
      defaultValue: 0,
      validate: {
        min: 0,
        isInt: true,
      },
    },
    conversion: {
      type: DataTypes.INTEGER,
      allowNull: true,
      defaultValue: 0,
      validate: {
        min: 0,
        isInt: true,
      },
    },
    date: {
      type: DataTypes.DATEONLY,
      allowNull: false,
      validate: {
        isDate: true,
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
    tableName: 'listing_visits',
    indexes: [
      // Foreign key index
      {
        fields: ['listing_id'],
      },
      // Date index for filtering
      {
        fields: ['date'],
      },
      // Performance indexes for common queries
      {
        fields: ['total_impression'],
      },
      {
        fields: ['total_visit'],
      },
      {
        fields: ['conversion'],
      },
      // Composite unique index to ensure one record per listing per date
      {
        fields: ['listing_id', 'date'],
        unique: true,
      },
      // Composite indexes for common queries
      {
        fields: ['date', 'total_visit'],
      },
      {
        fields: ['listing_id', 'createdAt'],
      },
      // Date range indexes for filtering
      {
        fields: ['createdAt'],
      },
    ],
  });

  // Associations
  ListingVisit.associate = (models) => {
    ListingVisit.belongsTo(models.Listing, {
      foreignKey: 'listing_id',
      as: 'listing',
    });
  };

  return ListingVisit;
};
