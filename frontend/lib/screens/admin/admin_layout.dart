import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

class AdminLayout extends StatelessWidget {
  final Widget body;
  final String title;
  final int selectedIndex;
  final Function(int) onItemSelected;

  const AdminLayout({
    super.key,
    required this.body,
    required this.title,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: isDesktop
          ? null
          : AppBar(
              title: Text(title, style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold)),
              backgroundColor: Colors.white,
              elevation: 0,
              iconTheme: const IconThemeData(color: AppTheme.primaryBlue),
            ),
      drawer: !isDesktop ? _buildSidebar(context) : null,
      body: Row(
        children: [
          if (isDesktop) SizedBox(width: 250, child: _buildSidebar(context)),
          Expanded(
            child: Column(
              children: [
                if (isDesktop)
                  Container(
                    height: 80,
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    color: Colors.white,
                    child: Row(
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                        const Spacer(),
                        const CircleAvatar(
                          backgroundColor: AppTheme.backgroundLight,
                          child: Icon(Icons.person, color: AppTheme.primaryBlue),
                        ),
                      ],
                    ),
                  ),
                Expanded(child: body),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    return Container(
      color: AppTheme.primaryBlue,
      child: Column(
        children: [
          Container(
            height: 150,
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.admin_panel_settings, size: 48, color: AppTheme.primaryOrange),
                const SizedBox(height: 16),
                Text(
                  'BACK OFFICE',
                  style: GoogleFonts.lato(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
          _buildMenuItem(0, 'Tableau de bord', Icons.dashboard),
          _buildMenuItem(1, 'Contenus', Icons.library_books),
          _buildMenuItem(2, 'Utilisateurs', Icons.people),
          _buildMenuItem(3, 'Paramètres', Icons.settings),
          const Spacer(),
          _buildMenuItem(4, 'Quitter', Icons.logout, isDestructive: true),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildMenuItem(int index, String title, IconData icon, {bool isDestructive = false}) {
    final isSelected = selectedIndex == index;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onItemSelected(index),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            border: isSelected
                ? const Border(left: BorderSide(color: AppTheme.primaryOrange, width: 4))
                : null,
            color: isSelected ? Colors.white.withOpacity(0.1) : Colors.transparent,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isDestructive ? Colors.redAccent : (isSelected ? AppTheme.primaryOrange : Colors.white70),
                size: 22,
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: GoogleFonts.lato(
                  color: isDestructive ? Colors.redAccent : (isSelected ? Colors.white : Colors.white70),
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
