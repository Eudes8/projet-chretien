const bcrypt = require('bcryptjs');
const sequelize = require('./database');
const Admin = require('./models/Admin');

async function testAuth() {
    try {
        await sequelize.sync();

        // Vérifier si l'admin existe
        const admin = await Admin.findOne({ where: { username: 'admin' } });

        if (!admin) {
            console.log('❌ Aucun admin trouvé dans la base de données');
            return;
        }

        console.log('✅ Admin trouvé:', admin.username);
        console.log('Hash stocké:', admin.passwordHash);

        // Tester le mot de passe
        const testPassword = 'Admin@2024!';
        const isValid = await bcrypt.compare(testPassword, admin.passwordHash);

        console.log('\n🔐 Test du mot de passe:', testPassword);
        console.log('Résultat:', isValid ? '✅ VALIDE' : '❌ INVALIDE');

        // Tester aussi avec un hash frais
        const freshHash = await bcrypt.hash(testPassword, 10);
        const freshTest = await bcrypt.compare(testPassword, freshHash);
        console.log('\n🔐 Test avec hash frais:', freshTest ? '✅ OK' : '❌ ERREUR');

    } catch (error) {
        console.error('❌ Erreur:', error);
    } finally {
        process.exit(0);
    }
}

testAuth();
