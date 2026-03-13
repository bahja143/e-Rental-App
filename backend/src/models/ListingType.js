module.exports = (sequelize, DataTypes) => {
  const ListingType = sequelize.define('ListingType', {
    id: {
      type: DataTypes.INTEGER,
      primaryKey: true,
      autoIncrement: true,
    },
    name_en: {
      type: DataTypes.STRING,
      allowNull: false,
      unique: true,
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
  }, {
    tableName: 'listing_types',
    timestamps: true,
    indexes: [
      {
        unique: true,
        fields: ['name_en'],
      },
      {
        fields: ['createdAt'],
      },
    ],
  });

  // Associations
  ListingType.associate = (models) => {
    ListingType.belongsToMany(models.Listing, {
      through: models.TypeListing,
      foreignKey: 'listing_type_id',
      otherKey: 'listing_id',
      as: 'listings',
    });
  };

  return ListingType;
};
