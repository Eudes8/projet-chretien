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

const app = express();
const PORT = 3000;
const BASE_URL = process.env.BASE_URL || 'http://192.168.1.8:3000';

// Middleware
app.use(cors());
app.use(bodyParser.json({ limit: '50mb' }));

// Configure Multer
const uploadDir = path.join(__dirname, 'uploads');
if (!fs.existsSync(uploadDir)) {
    fs.mkdirSync(uploadDir);
}

const storage = multer.diskStorage({
    destination: function (req, file, cb) {
        cb(null, 'uploads/');
    },
    filename: function (req, file, cb) {
        const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
        cb(null, uniqueSuffix + path.extname(file.originalname));
    }
});

const upload = multer({ storage: storage });

app.use('/uploads', express.static(path.join(__dirname, 'uploads')));
// Initialize database and start server
async function startServer() {
    try {
        // Sync Database
        await sequelize.sync({ force: false });
        console.log('✅ Database synced');

        // Create default admin if none exists
        const adminCount = await Admin.count();
        if (adminCount === 0) {
            const hashedPassword = await bcrypt.hash('Admin@2024!', 10);
            await Admin.create({
                username: 'admin',
                passwordHash: hashedPassword
            });
            console.log('✅ Admin par défaut créé:');
            console.log('   Username: admin');
            console.log('   Password: Admin@2024!');
            console.log('   ⚠️  Changez ce mot de passe en production!');
        } else {
            console.log('✅ Admin déjà existant');
        }

        // AUTH ROUTES

        // Login
        app.post('/auth/login', async (req, res) => {
            try {
                const { username, password } = req.body;
                console.log('🔐 Tentative de connexion:', username);

                const admin = await Admin.findOne({ where: { username } });
                if (!admin) {
                    console.log('❌ Admin non trouvé:', username);
                    return res.status(401).json({ error: 'Identifiants invalides' });
                }

                const isValid = await bcrypt.compare(password, admin.passwordHash);
                if (!isValid) {
                    console.log('❌ Mot de passe incorrect pour:', username);
                    return res.status(401).json({ error: 'Identifiants invalides' });
                }

                const token = jwt.sign(
                    { id: admin.id, username: admin.username },
                    JWT_SECRET,
                    { expiresIn: '24h' }
                );

                console.log('✅ Connexion réussie:', username);
                res.json({ token, username: admin.username });
            } catch (error) {
                console.error('❌ Erreur login:', error);
                res.status(500).json({ error: error.message });
            }
        });

        // PUBLICATION ROUTES

        // GET all publications (public)
        app.get('/publications', async (req, res) => {
            try {
                const publications = await Publication.findAll();
                res.json(publications);
            } catch (error) {
                res.status(500).json({ error: error.message });
            }
        });

        // GET one publication (public)
        app.get('/publications/:id', async (req, res) => {
            try {
                const publication = await Publication.findByPk(req.params.id);
                if (publication) {
                    res.json(publication);
                } else {
                    res.status(404).json({ error: 'Publication not found' });
                }
            } catch (error) {
                res.status(500).json({ error: error.message });
                res.status(400).json({ error: error.message });
            }
        });

        // DELETE publication (protected)
        app.delete('/publications/:id', authenticateToken, async (req, res) => {
            try {
                const publication = await Publication.findByPk(req.params.id);
                if (publication) {
                    await publication.destroy();
                    console.log('✅ Publication supprimée:', req.params.id);
                    res.json({ message: 'Publication deleted' });
                } else {
                    res.status(404).json({ error: 'Publication not found' });
                }
            } catch (error) {
                console.error('❌ Erreur suppression:', error);
                res.status(500).json({ error: error.message });
            }
        });

        // POST create publication (protected)
        app.post('/publications', authenticateToken, upload.single('coverImage'), async (req, res) => {
            try {
                console.log('📥 Reçu POST /publications');
                console.log('Body:', req.body);
                console.log('File:', req.file);

                const rawData = req.body;

                // Map frontend keys (French) to backend model keys (English)
                const publicationData = {
                    title: rawData.titre,
                    content: rawData.contenuPrincipal,
                    excerpt: rawData.extrait,
                    type: rawData.type,
                    isPaid: rawData.estPayant === 'true' || rawData.estPayant === true,
                };

                // Add image URL if file was uploaded
                if (req.file) {
                    publicationData.coverImage = `${BASE_URL}/uploads/${req.file.filename}`;
                }

                const publication = await Publication.create(publicationData);
                console.log('✅ Publication créée:', publication.id);
                res.status(201).json(publication);
            } catch (error) {
                console.error('❌ Erreur création:', error);
                res.status(400).json({ error: error.message });
            }
        });

        // PUT update publication (protected)
        app.put('/publications/:id', authenticateToken, upload.single('coverImage'), async (req, res) => {
            try {
                console.log('📥 Reçu PUT /publications/' + req.params.id);
                console.log('Body:', req.body);
                console.log('File:', req.file);

                const publication = await Publication.findByPk(req.params.id);
                if (!publication) {
                    return res.status(404).json({ error: 'Publication not found' });
                }

                const rawData = req.body;

                // Map frontend keys to backend model keys
                const updateData = {
                    title: rawData.titre,
                    content: rawData.contenuPrincipal,
                    excerpt: rawData.extrait,
                    type: rawData.type,
                    isPaid: rawData.estPayant === 'true' || rawData.estPayant === true,
                };

                // Add image URL if file was uploaded, otherwise keep existing
                if (req.file) {
                    updateData.coverImage = `${BASE_URL}/uploads/${req.file.filename}`;
                } else if (rawData.imageUrl) {
                    updateData.coverImage = rawData.imageUrl;
                }

                await publication.update(updateData);
                console.log('✅ Publication mise à jour:', publication.id);
                res.json(publication);
            } catch (error) {
                console.error('❌ Erreur mise à jour:', error);
                res.status(400).json({ error: error.message });
            }
        });

        // ADMIN STATS
        app.get('/admin/stats', authenticateToken, async (req, res) => {
            try {
                const totalPublications = await Publication.count();
                const meditationsCount = await Publication.count({ where: { type: 'Meditation' } });
                const livretsCount = await Publication.count({ where: { type: 'Livret' } });
                const livresCount = await Publication.count({ where: { type: 'Livre' } });
                const adminCount = await Admin.count();

                // Mock data for charts (since we don't have a Views model yet)
                const recentActivity = [
                    { day: 'Lun', views: 120 },
                    { day: 'Mar', views: 145 },
                    { day: 'Mer', views: 100 },
                    { day: 'Jeu', views: 180 },
                    { day: 'Ven', views: 220 },
                    { day: 'Sam', views: 250 },
                    { day: 'Dim', views: 300 },
                ];

                res.json({
                    totalPublications,
                    byType: {
                        meditation: meditationsCount,
                        livret: livretsCount,
                        livre: livresCount
                    },
                    admins: adminCount,
                    recentActivity
                });
            } catch (error) {
                console.error('❌ Erreur stats:', error);
                res.status(500).json({ error: error.message });
            }
        });

        // USER ROUTES (Protected)
        app.get('/users', authenticateToken, async (req, res) => {
            try {
                const users = await User.findAll({ attributes: { exclude: ['passwordHash'] } });
                res.json(users);
            } catch (error) {
                res.status(500).json({ error: error.message });
            }
        });

        app.delete('/users/:id', authenticateToken, async (req, res) => {
            try {
                const user = await User.findByPk(req.params.id);
                if (user) {
                    await user.destroy();
                    res.json({ message: 'User deleted' });
                } else {
                    res.status(404).json({ error: 'User not found' });
                }
            } catch (error) {
                res.status(500).json({ error: error.message });
            }
        });

        // Start server
        app.listen(PORT, () => {
            console.log(`🚀 Server is running on http://localhost:${PORT}`);
            console.log('📡 Ready to accept requests');
        });

    } catch (error) {
        console.error('❌ Failed to start server:', error);
        process.exit(1);
    }
}

startServer();
