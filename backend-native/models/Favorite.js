const { DataTypes } = require('sequelize');
const sequelize = require('../database');

const Favorite = sequelize.define('Favorite', {
    userId: {
        type: DataTypes.INTEGER,
        allowNull: false,
        references: {
            model: 'Users',
            key: 'id'
        }
    },
    publicationId: {
        type: DataTypes.INTEGER,
        allowNull: false,
        references: {
            model: 'Publications',
            key: 'id'
        }
    }
});

module.exports = Favorite;
