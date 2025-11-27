const { body, param, validationResult } = require('express-validator');

// Middleware pour vérifier les erreurs de validation
const validate = (req, res, next) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
        return res.status(400).json({
            success: false,
            errors: errors.array().map(err => ({
                field: err.param,
                message: err.msg
            }))
        });
    }
    next();
};

// Validations pour l'authentification
const authValidation = {
    register: [
        body('name')
            .trim()
            .notEmpty().withMessage('Le nom est requis')
            .isLength({ min: 2, max: 100 }).withMessage('Le nom doit contenir entre 2 et 100 caractères'),
        body('email')
            .trim()
            .notEmpty().withMessage('L\'email est requis')
            .isEmail().withMessage('Email invalide')
            .normalizeEmail(),
        body('password')
            .notEmpty().withMessage('Le mot de passe est requis')
            .isLength({ min: 6 }).withMessage('Le mot de passe doit contenir au moins 6 caractères')
            .matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/).withMessage('Le mot de passe doit contenir au moins une majuscule, une minuscule et un chiffre'),
    ],
    login: [
        body('username')
            .trim()
            .notEmpty().withMessage('Le nom d\'utilisateur est requis'),
        body('password')
            .notEmpty().withMessage('Le mot de passe est requis'),
    ],
};

// Validations pour les publications
const publicationValidation = {
    create: [
        body('title')
            .trim()
            .notEmpty().withMessage('Le titre est requis')
            .isLength({ min: 3, max: 200 }).withMessage('Le titre doit contenir entre 3 et 200 caractères'),
        body('content')
            .notEmpty().withMessage('Le contenu est requis'),
        body('type')
            .isIn(['Méditation', 'Livret', 'Livre']).withMessage('Type invalide'),
        body('isPaid')
            .optional()
            .isBoolean().withMessage('isPaid doit être un booléen'),
    ],
    update: [
        param('id')
            .isInt({ min: 1 }).withMessage('ID invalide'),
        body('title')
            .optional()
            .trim()
            .isLength({ min: 3, max: 200 }).withMessage('Le titre doit contenir entre 3 et 200 caractères'),
        body('type')
            .optional()
            .isIn(['Méditation', 'Livret', 'Livre']).withMessage('Type invalide'),
    ],
};

// Validations pour les paiements
const paymentValidation = {
    initiate: [
        body('amount')
            .isFloat({ min: 0.01 }).withMessage('Montant invalide'),
        body('plan')
            .isIn(['monthly', 'yearly']).withMessage('Plan invalide'),
    ],
};

module.exports = {
    validate,
    authValidation,
    publicationValidation,
    paymentValidation,
};
