const { DataTypes, Op } = require('sequelize');

module.exports = (sequelize) => {
  const Company = sequelize.define('Company', {
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
        len: [2, 255],
      },
    },
    name_so: {
      type: DataTypes.STRING,
      allowNull: true,
      validate: {
        len: [0, 255],
      },
    },
    address_en: {
      type: DataTypes.TEXT,
      allowNull: false,
      validate: {
        notEmpty: true,
      },
    },
    address_so: {
      type: DataTypes.TEXT,
      allowNull: true,
    },
    emails: {
      type: DataTypes.JSON,
      allowNull: true,
      validate: {
        isValidEmails(value) {
          if (value !== null && value !== undefined) {
            if (!Array.isArray(value)) {
              throw new Error('Emails must be an array');
            }
            const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
            for (const email of value) {
              if (typeof email !== 'string' || !emailRegex.test(email)) {
                throw new Error('Invalid email format in emails array');
              }
            }
          }
        },
      },
    },
    phones: {
      type: DataTypes.JSON,
      allowNull: true,
      validate: {
        isValidPhones(value) {
          if (value !== null && value !== undefined) {
            if (!Array.isArray(value)) {
              throw new Error('Phones must be an array');
            }
            const phoneRegex = /^[\+]?[1-9][\d]{0,15}$/;
            for (const phone of value) {
              if (typeof phone !== 'string' || !phoneRegex.test(phone)) {
                throw new Error('Invalid phone format in phones array');
              }
            }
          }
        },
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
    tableName: 'companies',
    indexes: [
      // Index for name_en searches
      {
        fields: ['name_en'],
      },
      // Index for name_so searches (nullable)
      {
        fields: ['name_so'],
        where: {
          name_so: {
            [Op.ne]: null,
          },
        },
      },
      // Index for created date sorting
      {
        fields: ['createdAt'],
      },
    ],
  });

  // Instance methods
  Company.prototype.toJSON = function() {
    const values = { ...this.get() };
    return values;
  };

  // Associations (if needed in future)
  Company.associate = (models) => {
    // Add associations here if needed
  };

  return Company;
};
