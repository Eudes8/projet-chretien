import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/payment_service.dart';
import '../theme/app_theme.dart';
import '../theme/premium_components.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({Key? key}) : super(key: key);

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final PaymentService _paymentService = PaymentService();
  bool _isLoading = false;
  String _selectedPlan = 'monthly';

  Future<void> _subscribe() async {
    setState(() => _isLoading = true);
    
    try {
      final success = await _paymentService.subscribe(plan: _selectedPlan);
      
      if (success && mounted) {
        // Show success dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 32),
                const SizedBox(width: 12),
                Text(
                  'Félicitations !',
                  style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: Text(
              'Vous êtes maintenant membre Premium ! Profitez de tous les contenus exclusifs.',
              style: GoogleFonts.lato(),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Return to previous screen
                },
                child: const Text('Continuer'),
              ),
            ],
          ),
        );
      } else if (mounted) {
        // Show error
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de l\'abonnement')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      // Title
                      Icon(
                        Icons.star,
                        size: 80,
                        color: AppTheme.primaryGold,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Devenez Premium',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Accédez à tous les contenus exclusifs',
                        style: GoogleFonts.lato(
                          fontSize: 18,
                          color: Colors.white.withOpacity(0.9),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      const SizedBox(height: 48),
                      
                      // Features
                      _buildFeature(Icons.book, 'Tous les livres et méditations'),
                      _buildFeature(Icons.lock_open, 'Contenu exclusif illimité'),
                      _buildFeature(Icons.download, 'Téléchargement hors ligne'),
                      _buildFeature(Icons.support, 'Support prioritaire'),
                      
                      const SizedBox(height: 48),
                      
                      // Plans
                      _buildPlanCard(
                        'monthly',
                        'Mensuel',
                        '9,99 €',
                        'par mois',
                      ),
                      const SizedBox(height: 16),
                      _buildPlanCard(
                        'yearly',
                        'Annuel',
                        '99,99 €',
                        'par an',
                        badge: 'ÉCONOMISEZ 17%',
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Subscribe button
                      SizedBox(
                        width: double.infinity,
                        child: PremiumGradientButton(
                          label: 'S\'abonner maintenant',
                          icon: Icons.star,
                          isLoading: _isLoading,
                          onPressed: _isLoading ? null : _subscribe,
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      Text(
                        'Annulez à tout moment',
                        style: GoogleFonts.lato(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeature(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppTheme.primaryGold, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.lato(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(String planId, String title, String price, String period, {String? badge}) {
    final isSelected = _selectedPlan == planId;
    
    return GestureDetector(
      onTap: () => setState(() => _selectedPlan = planId),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected 
              ? Colors.white 
              : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primaryGold : Colors.transparent,
            width: 2,
          ),
        ),
        child: Stack(
          children: [
            Row(
              children: [
                // Radio
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? AppTheme.primaryBlue : Colors.white,
                      width: 2,
                    ),
                    color: isSelected ? AppTheme.primaryBlue : Colors.transparent,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 16),
                
                // Plan info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.lato(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? AppTheme.textPrimary : Colors.white,
                        ),
                      ),
                      Text(
                        period,
                        style: GoogleFonts.lato(
                          fontSize: 14,
                          color: isSelected 
                              ? AppTheme.textSecondary 
                              : Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Price
                Text(
                  price,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? AppTheme.primaryBlue : Colors.white,
                  ),
                ),
              ],
            ),
            
            // Badge
            if (badge != null)
              Positioned(
                top: -8,
                right: -8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGold,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    badge,
                    style: GoogleFonts.lato(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
