const { DataTypes } = require('sequelize');
const sequelize = require('../database');

const Publication = sequelize.define('Publication', {
    title: {
        type: DataTypes.STRING,
        allowNull: false
    },
    content: {
        type: DataTypes.TEXT,
        allowNull: false
    },
    coverImage: {
        type: DataTypes.STRING, // URL or Base64
        allowNull: true
    },
    type: {
        type: DataTypes.ENUM('Meditation', 'Livret', 'Livre'),
        defaultValue: 'Meditation'
    },
    isPaid: {
        type: DataTypes.BOOLEAN,
        defaultValue: false
    },
    productId: {
        type: DataTypes.STRING,
        allowNull: true
    },
    excerpt: {
        type: DataTypes.TEXT,
        allowNull: true
    }
});

module.exports = Publication;
