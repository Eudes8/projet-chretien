import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../theme/premium_components.dart';
import '../screens/subscription_screen.dart';

class PremiumGate extends StatelessWidget {
  final Widget child;
  final bool isPaidContent;

  const PremiumGate({
    Key? key,
    required this.child,
    this.isPaidContent = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!isPaidContent) {
      return child;
    }

    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;
    final isPremium = user?['isPremium'] == true;

    if (isPremium) {
      return child;
    }

    // Show premium gate
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_outline,
                      size: 80,
                      color: AppTheme.primaryOrange,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Contenu Premium',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Ce contenu est réservé aux membres Premium.\nAbonnez-vous pour accéder à tous les contenus exclusifs.',
                    style: GoogleFonts.lato(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  PremiumGradientButton(
                    label: 'Devenir Premium',
                    icon: Icons.star,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SubscriptionScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Retour',
                      style: GoogleFonts.lato(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
