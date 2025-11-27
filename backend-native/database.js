const { Sequelize } = require('sequelize');
const path = require('path');

// Configuration dynamique : PostgreSQL en production, SQLite en local
const isDatabaseUrlProvided = !!process.env.DATABASE_URL;

const sequelize = new Sequelize(
    process.env.DATABASE_URL || {
        dialect: 'sqlite',
        storage: path.join(__dirname, 'database.sqlite'),
    },
    {
        // Options pour PostgreSQL
        ...(isDatabaseUrlProvided && {
            dialect: 'postgres',
            dialectOptions: {
                ssl: {
                    require: true,
                    rejectUnauthorized: false, // Nécessaire pour Render
                },
            },
            pool: {
                max: 5,
                min: 0,
                acquire: 30000,
                idle: 10000,
            },
        }),
        logging: false,
    }
);

// Test de connexion au démarrage
sequelize
    .authenticate()
    .then(() => {
        console.log(
            `✅ Base de données connectée (${isDatabaseUrlProvided ? 'PostgreSQL' : 'SQLite'})`
        );
    })
    .catch((err) => {
        console.error('❌ Erreur de connexion à la base de données:', err);
    });

module.exports = sequelize;
