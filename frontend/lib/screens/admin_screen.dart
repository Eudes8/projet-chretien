import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'admin/admin_layout.dart';
import 'admin/admin_dashboard_screen.dart';
import 'admin/admin_content_screen.dart';
import 'admin/admin_users_screen.dart';
import 'admin/admin_settings_screen.dart';
import 'login_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuth();
    });
  }

  Future<void> _checkAuth() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (!authService.isAuthenticated) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
      if (result != true && mounted) {
        Navigator.pop(context);
      } else {
        setState(() {}); // Refresh
      }
    }
  }

  void _onItemSelected(int index) {
    if (index == 4) { // Logout
      final authService = Provider.of<AuthService>(context, listen: false);
      authService.logout();
      Navigator.pop(context);
      return;
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    if (!authService.isAuthenticated) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    Widget body;
    String title;

    switch (_selectedIndex) {
      case 0:
        body = const AdminDashboardScreen();
        title = 'Tableau de bord';
        break;
      case 1:
        body = const AdminContentScreen();
        title = 'Gestion des Contenus';
        break;
      case 2:
        body = const AdminUsersScreen();
        title = 'Utilisateurs';
        break;
      case 3:
        body = const AdminSettingsScreen();
        title = 'Paramètres';
        break;
      default:
        body = const AdminDashboardScreen();
        title = 'Tableau de bord';
    }

    return AdminLayout(
      title: title,
      selectedIndex: _selectedIndex,
      onItemSelected: _onItemSelected,
      body: body,
    );
  }
}
