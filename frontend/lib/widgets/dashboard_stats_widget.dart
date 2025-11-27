import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class DashboardStatsWidget extends StatelessWidget {
  final int totalPublications;
  final DateTime? lastUpdate;
  final String mostReadTitle;
  final int mostReadCount;

  const DashboardStatsWidget({
    Key? key,
    required this.totalPublications,
    this.lastUpdate,
    this.mostReadTitle = 'N/A',
    this.mostReadCount = 0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppTheme.spacingM),
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryBlue.withOpacity(0.1),
            AppTheme.primaryGold.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primaryGold.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics_outlined,
                color: AppTheme.primaryBlue,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Statistiques',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingM),
          
          // Stats Grid
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.article_outlined,
                  label: 'Publications',
                  value: totalPublications.toString(),
                  color: AppTheme.primaryBlue,
                ),
              ),
              const SizedBox(width: AppTheme.spacingS),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.visibility_outlined,
                  label: 'Plus lu',
                  value: mostReadCount.toString(),
                  color: AppTheme.primaryGold,
                ),
              ),
            ],
          ),
          
          if (lastUpdate != null) ...[
            const SizedBox(height: AppTheme.spacingM),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: Colors.grey[700],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Dernière màj: ${_formatDate(lastUpdate!)}',
                      style: GoogleFonts.lato(
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          if (mostReadTitle != 'N/A') ...[
            const SizedBox(height: AppTheme.spacingM),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryGold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primaryGold.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.star,
                    size: 16,
                    color: AppTheme.primaryGold,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Populaire: $mostReadTitle',
                      style: GoogleFonts.lato(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryBlue,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.playfairDisplay(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.lato(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        return 'Il y a ${diff.inMinutes} min';
      }
      return 'Il y a ${diff.inHours}h';
    } else if (diff.inDays == 1) {
      return 'Hier';
    } else if (diff.inDays < 7) {
      return 'Il y a ${diff.inDays} jours';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
