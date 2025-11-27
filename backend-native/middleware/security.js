const rateLimit = require('express-rate-limit');
const helmet = require('helmet');
const mongoSanitize = require('express-mongo-sanitize');
const xss = require('xss-clean');

// Rate limiting pour prévenir les attaques DDoS
const limiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 100, // Limite à 100 requêtes par IP
    message: 'Trop de requêtes depuis cette IP, veuillez réessayer plus tard.',
    standardHeaders: true,
    legacyHeaders: false,
});

// Rate limiting strict pour l'authentification
const authLimiter = rateLimit({
    windowMs: 15 * 60 * 1000,
    max: 5, // 5 tentatives de connexion max
    message: 'Trop de tentatives de connexion, veuillez réessayer dans 15 minutes.',
    skipSuccessfulRequests: true,
});

// Middleware de sécurité global
const securityMiddleware = [
    helmet({
        contentSecurityPolicy: false, // Désactivé pour permettre le chargement de ressources
        crossOriginEmbedderPolicy: false,
    }),
    mongoSanitize(), // Prévient les injections NoSQL
    xss(), // Prévient les attaques XSS
];

module.exports = {
    limiter,
    authLimiter,
    securityMiddleware,
};
