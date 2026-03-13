'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('faqs', {
      id: {
        type: Sequelize.INTEGER,
        primaryKey: true,
        autoIncrement: true,
      },
      title_en: {
        type: Sequelize.STRING,
        allowNull: false,
        validate: {
          notEmpty: true,
          len: [1, 255],
        },
      },
      title_so: {
        type: Sequelize.STRING,
        allowNull: true,
        validate: {
          len: [0, 255],
        },
      },
      description_en: {
        type: Sequelize.TEXT,
        allowNull: true,
      },
      description_so: {
        type: Sequelize.TEXT,
        allowNull: true,
      },
      type: {
        type: Sequelize.ENUM('buyer', 'seller'),
        allowNull: false,
        validate: {
          isIn: [['buyer', 'seller']],
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

    // Add indexes for performance
    await queryInterface.addIndex('faqs', ['title_en']);
    await queryInterface.addIndex('faqs', ['title_so'], {
      where: {
        title_so: {
          [Sequelize.Op.ne]: null,
        },
      },
    });
    await queryInterface.addIndex('faqs', ['type']);
    await queryInterface.addIndex('faqs', ['createdAt']);
    await queryInterface.addIndex('faqs', ['type', 'createdAt']);
  },

  async down(queryInterface, Sequelize) {
    await queryInterface.dropTable('faqs');
  }
};
