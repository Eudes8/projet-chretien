const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const sequelize = require('./database');
const Publication = require('./models/Publication');
const Admin = require('./models/Admin');
const User = require('./models/User');
const { authenticateToken, JWT_SECRET } = require('./middleware/auth');

// Import nouveaux middleware
const { logger, httpLogger } = require('./utils/logger');
const { limiter, authLimiter, securityMiddleware } = require('./middleware/security');
const { errorHandler, notFound, uncaughtExceptionHandler, unhandledRejectionHandler } = require('./middleware/errorHandler');

const app = express();
const PORT = process.env.PORT || 3000;
const BASE_URL = process.env.BASE_URL || 'http://localhost:3000';

// Gestion des erreurs non capturées
uncaughtExceptionHandler();

// Middleware de sécurité (doit être en premier)
app.use(securityMiddleware);

// HTTP Request Logging
app.use(httpLogger);

// CORS et Body Parser
app.use(cors());
app.use(bodyParser.json({ limit: '50mb' }));
app.use(bodyParser.urlencoded({ extended: true, limit: '50mb' }));

// Rate limiting global
app.use(limiter);

// Static files
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// Multer configuration for file uploads
const uploadDir = path.join(__dirname, 'uploads');
if (!fs.existsSync(uploadDir)) {
    fs.mkdirSync(uploadDir);
}
const storage = multer.diskStorage({
    destination: (req, file, cb) => cb(null, uploadDir),
    filename: (req, file, cb) => {
        const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1e9);
        cb(null, uniqueSuffix + path.extname(file.originalname));
    },
});
const upload = multer({ storage });

// Initialize database and ensure default admin exists
async function init() {
    try {
        await sequelize.sync({ alter: true });
        const adminCount = await Admin.count();
        if (adminCount === 0) {
            const hashedPassword = await bcrypt.hash('Admin@2024!', 10);
            await Admin.create({ username: 'admin', passwordHash: hashedPassword });
            console.log('✅ Default admin created (username: admin, password: Admin@2024!)');
        }
    } catch (e) {
        console.error('❌ DB init error:', e);
        process.exit(1);
    }
}

// ---------- AUTH ROUTES ----------
// Register
app.post('/auth/register', authLimiter, async (req, res) => {
    try {
        const { name, email, password } = req.body;
        const existing = await User.findOne({ where: { email } });
        if (existing) return res.status(400).json({ error: 'Email already used' });
        const passwordHash = await bcrypt.hash(password, 10);
        const user = await User.create({ name, email, passwordHash });
        const token = jwt.sign({ id: user.id, email: user.email, role: 'user' }, JWT_SECRET, { expiresIn: '24h' });
        logger.info(`New user registered: ${email}`);
        res.status(201).json({ token, user: { id: user.id, name: user.name, email: user.email, role: 'user' } });
    } catch (e) {
        logger.error('Register error:', e);
        res.status(500).json({ error: e.message });
    }
});

// Login (admin or user)
app.post('/auth/login', authLimiter, async (req, res) => {
    try {
        const { username, password } = req.body;
        // Admin attempt
        const admin = await Admin.findOne({ where: { username } });
        if (admin && (await bcrypt.compare(password, admin.passwordHash))) {
            const token = jwt.sign({ id: admin.id, username: admin.username, role: 'admin' }, JWT_SECRET, { expiresIn: '24h' });
            return res.json({ token, user: { id: admin.id, name: admin.username, role: 'admin' } });
        }
        // User attempt (username treated as email)
        const user = await User.findOne({ where: { email: username } });
        if (user && (await bcrypt.compare(password, user.passwordHash))) {
            const token = jwt.sign({ id: user.id, email: user.email, role: 'user' }, JWT_SECRET, { expiresIn: '24h' });
            return res.json({ token, user: { id: user.id, name: user.name, email: user.email, role: 'user' } });
        }
        res.status(401).json({ error: 'Invalid credentials' });
    } catch (e) {
        console.error('Login error:', e);
        res.status(500).json({ error: e.message });
    }
});

// Get current profile
app.get('/auth/me', authenticateToken, async (req, res) => {
    try {
        if (req.user.role === 'admin') {
            const admin = await Admin.findByPk(req.user.id);
            return res.json({ id: admin.id, name: admin.username, role: 'admin' });
        }
        const user = await User.findByPk(req.user.id);
        if (!user) return res.status(404).json({ error: 'User not found' });
        return res.json({ id: user.id, name: user.name, email: user.email, role: 'user', preferences: user.preferences, isPremium: user.isPremium, subscriptionEndsAt: user.subscriptionEndsAt });
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
});

// ---------- PAYMENT ROUTE ----------
app.post('/payments/subscribe', authenticateToken, async (req, res) => {
    try {
        const { plan } = req.body; // expected 'monthly' or 'yearly'
        const user = await User.findByPk(req.user.id);
        if (!user) return res.status(404).json({ error: 'User not found' });
        let endDate = new Date();
        if (plan === 'yearly') endDate.setFullYear(endDate.getFullYear() + 1);
        else endDate.setMonth(endDate.getMonth() + 1);
        user.isPremium = true;
        user.subscriptionEndsAt = endDate;
        await user.save();
        res.json({ success: true, isPremium: true, subscriptionEndsAt: endDate });
    } catch (e) {
        console.error('Payment error:', e);
        res.status(500).json({ error: e.message });
    }
});

// ---------- PUBLICATION ROUTES ----------
// Get all publications (public)
app.get('/publications', async (req, res) => {
    try {
        const pubs = await Publication.findAll();
        res.json(pubs);
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
});

// Get single publication (public)
app.get('/publications/:id', async (req, res) => {
    try {
        const pub = await Publication.findByPk(req.params.id);
        if (!pub) return res.status(404).json({ error: 'Publication not found' });
        res.json(pub);
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
});

// Create publication (protected)
app.post('/publications', authenticateToken, upload.single('coverImage'), async (req, res) => {
    try {
        const data = req.body;
        const publicationData = {
            title: data.titre,
            content: data.contenuPrincipal,
            excerpt: data.extrait,
            type: data.type,
            isPaid: data.estPayant === 'true' || data.estPayant === true,
        };
        if (req.file) publicationData.coverImage = `${BASE_URL}/uploads/${req.file.filename}`;
        const pub = await Publication.create(publicationData);
        res.status(201).json(pub);
    } catch (e) {
        console.error('Create publication error:', e);
        res.status(400).json({ error: e.message });
    }
});

// Update publication (protected)
app.put('/publications/:id', authenticateToken, upload.single('coverImage'), async (req, res) => {
    try {
        const pub = await Publication.findByPk(req.params.id);
        if (!pub) return res.status(404).json({ error: 'Publication not found' });
        const data = req.body;
        const updateData = {
            title: data.titre,
            content: data.contenuPrincipal,
            excerpt: data.extrait,
            type: data.type,
            isPaid: data.estPayant === 'true' || data.estPayant === true,
        };
        if (req.file) updateData.coverImage = `${BASE_URL}/uploads/${req.file.filename}`;
        else if (data.imageUrl) updateData.coverImage = data.imageUrl;
        await pub.update(updateData);
        res.json(pub);
    } catch (e) {
        console.error('Update publication error:', e);
        res.status(400).json({ error: e.message });
    }
});

// Delete publication (protected)
app.delete('/publications/:id', authenticateToken, async (req, res) => {
    try {
        const pub = await Publication.findByPk(req.params.id);
        if (!pub) return res.status(404).json({ error: 'Publication not found' });
        await pub.destroy();
        res.json({ message: 'Publication deleted' });
    } catch (e) {
        console.error('Delete publication error:', e);
        res.status(500).json({ error: e.message });
    }
});

// ---------- ADMIN STATS ----------
app.get('/admin/stats', authenticateToken, async (req, res) => {
    try {
        const totalPublications = await Publication.count();
        const meditations = await Publication.count({ where: { type: 'Meditation' } });
        const livrets = await Publication.count({ where: { type: 'Livret' } });
        const livres = await Publication.count({ where: { type: 'Livre' } });
        const adminCount = await Admin.count();
        const recentActivity = [
            { day: 'Mon', views: 120 },
            { day: 'Tue', views: 145 },
            { day: 'Wed', views: 100 },
            { day: 'Thu', views: 180 },
            { day: 'Fri', views: 220 },
            { day: 'Sat', views: 250 },
            { day: 'Sun', views: 300 },
        ];
        res.json({ totalPublications, byType: { meditation: meditations, livret: livrets, livre: livres }, admins: adminCount, recentActivity });
    } catch (e) {
        console.error('Admin stats error:', e);
        res.status(500).json({ error: e.message });
    }
});

// ---------- USER ROUTES (protected) ----------
app.get('/users', authenticateToken, async (req, res) => {
    try {
        const users = await User.findAll({ attributes: { exclude: ['passwordHash'] } });
        res.json(users);
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
});

app.delete('/users/:id', authenticateToken, async (req, res) => {
    try {
        const user = await User.findByPk(req.params.id);
        if (!user) return res.status(404).json({ error: 'User not found' });
        await user.destroy();
        res.json({ message: 'User deleted' });
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
});

// Gestionnaire 404 - doit être après toutes les routes
app.use(notFound);

// Gestionnaire d'erreurs global - doit être en dernier
app.use(errorHandler);

// Start server after DB init
init().then(() => {
    const server = app.listen(PORT, () => {
        logger.info(`🚀 Veritable Server running at http://localhost:${PORT}`);
        logger.info(`📊 Environment: ${process.env.NODE_ENV || 'development'}`);
        logger.info(`🔒 Security middleware active`);
    });

    // Gestion des rejections non gérées
    unhandledRejectionHandler(server);
});
