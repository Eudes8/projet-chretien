const { logger } = require('../utils/logger');

// Classe d'erreur personnalisée
class AppError extends Error {
    constructor(message, statusCode) {
        super(message);
        this.statusCode = statusCode;
        this.isOperational = true;
        Error.captureStackTrace(this, this.constructor);
    }
}

// Gestionnaire d'erreurs global
const errorHandler = (err, req, res, next) => {
    err.statusCode = err.statusCode || 500;
    err.status = err.status || 'error';

    // Log de l'erreur
    if (err.statusCode >= 500) {
        logger.error(`${err.statusCode} - ${err.message} - ${req.originalUrl} - ${req.method} - ${req.ip}`);
        logger.error(err.stack);
    } else {
        logger.warn(`${err.statusCode} - ${err.message} - ${req.originalUrl}`);
    }

    // Environnement de développement : envoyer tous les détails
    if (process.env.NODE_ENV === 'development') {
        return res.status(err.statusCode).json({
            success: false,
            status: err.status,
            error: err,
            message: err.message,
            stack: err.stack,
        });
    }

    // Environnement de production : masquer les détails sensibles
    if (err.isOperational) {
        return res.status(err.statusCode).json({
            success: false,
            message: err.message,
        });
    }

    // Erreur de programmation : ne pas divulguer les détails
    return res.status(500).json({
        success: false,
        message: 'Une erreur est survenue. Veuillez réessayer plus tard.',
    });
};

// Gestionnaire pour les routes non trouvées
const notFound = (req, res, next) => {
    const error = new AppError(`Route non trouvée: ${req.originalUrl}`, 404);
    next(error);
};

// Gestionnaire pour les erreurs non capturées
const uncaughtExceptionHandler = () => {
    process.on('uncaughtException', (err) => {
        logger.error('UNCAUGHT EXCEPTION! 💥 Arrêt du serveur...');
        logger.error(err.name, err.message);
        logger.error(err.stack);
        process.exit(1);
    });
};

const unhandledRejectionHandler = (server) => {
    process.on('unhandledRejection', (err) => {
        logger.error('UNHANDLED REJECTION! 💥 Arrêt gracieux du serveur...');
        logger.error(err.name, err.message);
        server.close(() => {
            process.exit(1);
        });
    });
};

module.exports = {
    AppError,
    errorHandler,
    notFound,
    uncaughtExceptionHandler,
    unhandledRejectionHandler,
};
