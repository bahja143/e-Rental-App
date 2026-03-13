'use strict';
/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('user_listing_packs', {
      id: {
        allowNull: false,
        autoIncrement: true,
        primaryKey: true,
        type: Sequelize.INTEGER
      },
      user_id: {
        type: Sequelize.INTEGER,
        references: {
          model: 'users',
          key: 'id'
        },
        onUpdate: 'CASCADE',
        onDelete: 'SET NULL'
      },
      listing_pack_id: {
        type: Sequelize.INTEGER,
        references: {
          model: 'listing_packs',
          key: 'id'
        },
        onUpdate: 'CASCADE',
        onDelete: 'SET NULL'
      },
      start: {
        type: Sequelize.DATE
      },
      end: {
        type: Sequelize.DATE
      },
      status: {
        type: Sequelize.ENUM('active', 'expired', 'cancelled', 'upgraded', 'downgraded')
      },
      total_paid: {
        type: Sequelize.DECIMAL(10, 2)
      },
      remain_balance: {
        type: Sequelize.DECIMAL(10, 2),
        defaultValue: 0
      },
      upgrade_from_pack_id: {
        type: Sequelize.INTEGER,
        references: {
          model: 'listing_packs',
          key: 'id'
        },
        onUpdate: 'CASCADE',
        onDelete: 'SET NULL',
        allowNull: true
      },
      downgrade_to_pack_id: {
        type: Sequelize.INTEGER,
        references: {
          model: 'listing_packs',
          key: 'id'
        },
        onUpdate: 'CASCADE',
        onDelete: 'SET NULL',
        allowNull: true
      },
      date: {
        type: Sequelize.DATE
      },
      createdAt: {
        allowNull: false,
        type: Sequelize.DATE
      },
      updatedAt: {
        allowNull: false,
        type: Sequelize.DATE
      }
    });

    await queryInterface.addIndex('user_listing_packs', ['user_id']);
    await queryInterface.addIndex('user_listing_packs', ['listing_pack_id']);
    await queryInterface.addIndex('user_listing_packs', ['upgrade_from_pack_id']);
    await queryInterface.addIndex('user_listing_packs', ['downgrade_to_pack_id']);
  },
  async down(queryInterface, Sequelize) {
    await queryInterface.dropTable('user_listing_packs');
  }
};
