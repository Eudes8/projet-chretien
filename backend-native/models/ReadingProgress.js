const { DataTypes } = require('sequelize');
const sequelize = require('../database');

const ReadingProgress = sequelize.define('ReadingProgress', {
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
    },
    progress: {
        type: DataTypes.FLOAT,
        defaultValue: 0,
        validate: {
            min: 0,
            max: 100
        }
    },
    lastPosition: {
        type: DataTypes.INTEGER,
        defaultValue: 0
    },
    completed: {
        type: DataTypes.BOOLEAN,
        defaultValue: false
    },
    lastReadAt: {
        type: DataTypes.DATE,
        defaultValue: DataTypes.NOW
    }
});

module.exports = ReadingProgress;
