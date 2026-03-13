const { DataTypes } = require('sequelize');

module.exports = (sequelize) => {
  const Faq = sequelize.define('Faq', {
    id: {
      type: DataTypes.INTEGER,
      primaryKey: true,
      autoIncrement: true,
    },
    title_en: {
      type: DataTypes.STRING,
      allowNull: false,
      validate: {
        notEmpty: true,
        len: [1, 255],
      },
    },
    title_so: {
      type: DataTypes.STRING,
      allowNull: true,
      validate: {
        len: [0, 255],
      },
    },
    description_en: {
      type: DataTypes.TEXT,
      allowNull: true,
    },
    description_so: {
      type: DataTypes.TEXT,
      allowNull: true,
    },
    type: {
      type: DataTypes.ENUM('buyer', 'seller'),
      allowNull: false,
      validate: {
        isIn: [['buyer', 'seller']],
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
    tableName: 'faqs',
    indexes: [
      // Index for title_en searches
      {
        fields: ['title_en'],
      },
      // Index for title_so searches (nullable)
      {
        fields: ['title_so'],
        where: {
          title_so: {
            [sequelize.Sequelize.Op.ne]: null,
          },
        },
      },
      // Index for type filtering
      {
        fields: ['type'],
      },
      // Index for created date sorting
      {
        fields: ['createdAt'],
      },
      // Composite index for type and created date
      {
        fields: ['type', 'createdAt'],
      },
    ],
  });

  // Instance methods
  Faq.prototype.toJSON = function() {
    const values = { ...this.get() };
    return values;
  };

  // Associations (if needed in future)
  Faq.associate = (models) => {
    // Add associations here if needed
  };

  return Faq;
};
