const { DataTypes } = require('sequelize');
const sequelize = require('../database');

const User = sequelize.define('User', {
    email: {
        type: DataTypes.STRING,
        allowNull: false,
        unique: true
    },
    name: {
        type: DataTypes.STRING,
        allowNull: false
    },
    passwordHash: {
        type: DataTypes.STRING,
        allowNull: false
    },
    avatar: {
        type: DataTypes.STRING,
        allowNull: true
    },
    preferences: {
        type: DataTypes.JSON,
        defaultValue: {
            darkMode: false,
            fontSize: 'medium',
            fontFamily: 'Lato',
            autoPlay: false
        }
    },
    isPremium: {
        type: DataTypes.BOOLEAN,
        defaultValue: false
    },
    subscriptionEndsAt: {
        type: DataTypes.DATE,
        allowNull: true
    }
});

module.exports = User;
