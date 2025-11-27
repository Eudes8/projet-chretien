import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'admin_screen.dart';
import 'login_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  int _versionTapCount = 0;
  bool _isAdminModeVisible = false;

  void _handleVersionTap() {
    setState(() {
      _versionTapCount++;
      if (_versionTapCount == 10) {
        _isAdminModeVisible = true;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mode Administrateur Activé !'),
            backgroundColor: AppTheme.primaryOrange,
            duration: Duration(seconds: 2),
          ),
        );
      } else if (_versionTapCount > 5 && _versionTapCount < 10) {
        // Optional: Give a hint like Android "You are X steps away from being a developer"
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    // Show admin section if explicitly unlocked OR if already authenticated
    final showAdminSection = _isAdminModeVisible || authService.isAuthenticated;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          image: const DecorationImage(
                            image: NetworkImage('https://via.placeholder.com/150'), // Placeholder
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: const Icon(Icons.person, size: 40, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        authService.isAuthenticated ? (authService.username ?? 'Admin') : 'Invité',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildSectionTitle(context, 'Paramètres'),
                _buildSettingsTile(
                  context,
                  icon: Icons.dark_mode_outlined,
                  title: 'Mode Sombre',
                  subtitle: 'Activer le thème sombre',
                  trailing: Switch(value: false, onChanged: (val) {}), // TODO: Implement Theme Provider
                ),
                _buildSettingsTile(
                  context,
                  icon: Icons.notifications_outlined,
                  title: 'Notifications',
                  subtitle: 'Gérer les alertes',
                  onTap: () {},
                ),
                
                if (showAdminSection) ...[
                  const SizedBox(height: AppTheme.spacingL),
                  _buildSectionTitle(context, 'Administration'),
                  if (authService.isAuthenticated) ...[
                    _buildSettingsTile(
                      context,
                      icon: Icons.dashboard_customize,
                      title: 'Tableau de bord Admin',
                      subtitle: 'Gérer les publications',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AdminScreen()),
                        );
                      },
                    ),
                    _buildSettingsTile(
                      context,
                      icon: Icons.logout,
                      title: 'Se déconnecter',
                      subtitle: 'Fermer la session admin',
                      textColor: Colors.red,
                      iconColor: Colors.red,
                      onTap: () {
                        authService.logout();
                        setState(() {
                          _isAdminModeVisible = false; // Hide again on logout
                          _versionTapCount = 0;
                        });
                      },
                    ),
                  ] else
                    _buildSettingsTile(
                      context,
                      icon: Icons.admin_panel_settings_outlined,
                      title: 'Mode Admin',
                      subtitle: 'Connexion réservée aux administrateurs',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginScreen()),
                        );
                      },
                    ),
                ],

                const SizedBox(height: AppTheme.spacingL),
                _buildSectionTitle(context, 'À propos'),
                _buildSettingsTile(
                  context,
                  icon: Icons.info_outline,
                  title: 'Version',
                  subtitle: '1.0.0',
                  onTap: _handleVersionTap, // Secret tap handler
                ),
                _buildSettingsTile(
                  context,
                  icon: Icons.privacy_tip_outlined,
                  title: 'Politique de confidentialité',
                  onTap: () {},
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingS, left: 4),
      child: Text(
        title,
        style: GoogleFonts.lato(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryBlue,
        ),
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    Color? textColor,
    Color? iconColor,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingS),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (iconColor ?? AppTheme.primaryBlue).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor ?? AppTheme.primaryBlue, size: 20),
        ),
        title: Text(
          title,
          style: GoogleFonts.lato(
            fontWeight: FontWeight.w600,
            color: textColor ?? AppTheme.textPrimary,
          ),
        ),
        subtitle: subtitle != null
            ? Text(subtitle, style: GoogleFonts.lato(fontSize: 12))
            : null,
        trailing: trailing ?? const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
