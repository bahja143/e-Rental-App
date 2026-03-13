'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('companies', {
      id: {
        type: Sequelize.INTEGER,
        primaryKey: true,
        autoIncrement: true,
      },
      name_en: {
        type: Sequelize.STRING,
        allowNull: false,
        validate: {
          notEmpty: true,
          len: [2, 255],
        },
      },
      name_so: {
        type: Sequelize.STRING,
        allowNull: true,
        validate: {
          len: [0, 255],
        },
      },
      address_en: {
        type: Sequelize.TEXT,
        allowNull: false,
        validate: {
          notEmpty: true,
        },
      },
      address_so: {
        type: Sequelize.TEXT,
        allowNull: true,
      },
      emails: {
        type: Sequelize.JSON,
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
        type: Sequelize.JSON,
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
        type: Sequelize.DATE,
        defaultValue: Sequelize.NOW,
      },
      updatedAt: {
        type: Sequelize.DATE,
        defaultValue: Sequelize.NOW,
      },
    });

    // Add indexes
    await queryInterface.addIndex('companies', ['name_en']);
    await queryInterface.addIndex('companies', ['name_so'], {
      where: {
        name_so: {
          [Sequelize.Op.ne]: null,
        },
      },
    });
    await queryInterface.addIndex('companies', ['createdAt']);
  },

  async down(queryInterface, Sequelize) {
    await queryInterface.dropTable('companies');
  }
};
