const { DataTypes } = require('sequelize');

module.exports = (sequelize) => {
  const PromotionPack = sequelize.define('PromotionPack', {
    id: {
      type: DataTypes.INTEGER,
      primaryKey: true,
      autoIncrement: true,
    },
    name_en: {
      type: DataTypes.STRING,
      allowNull: false,
      validate: {
        notEmpty: true,
        len: [1, 255],
      },
    },
    name_so: {
      type: DataTypes.STRING,
      allowNull: false,
      validate: {
        notEmpty: true,
        len: [1, 255],
      },
    },
    duration: {
      type: DataTypes.INTEGER,
      allowNull: false,
      validate: {
        min: 1,
      },
    },
    price: {
      type: DataTypes.DECIMAL(10, 2),
      allowNull: false,
      validate: {
        min: 0,
      },
    },
    availability: {
      type: DataTypes.TINYINT,
      allowNull: false,
      defaultValue: 1,
      validate: {
        isIn: [[0, 1]],
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
    tableName: 'promotion_packs',
    indexes: [
      // Index for name_en searches
      {
        fields: ['name_en'],
      },
      // Index for name_so searches
      {
        fields: ['name_so'],
      },
      // Index for duration filtering
      {
        fields: ['duration'],
      },
      // Index for price filtering and sorting
      {
        fields: ['price'],
      },
      // Index for availability filtering
      {
        fields: ['availability'],
      },
      // Index for created date sorting
      {
        fields: ['createdAt'],
      },
    ],
  });

  // Instance methods
  PromotionPack.prototype.toJSON = function() {
    const values = { ...this.get() };
    return values;
  };

  // Associations (if needed in future)
  PromotionPack.associate = (models) => {
    // Add associations here if needed
  };

  return PromotionPack;
};
