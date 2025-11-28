import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/publication.dart';
import '../services/publication_service.dart';
import '../theme/app_theme.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../theme/premium_components.dart';
import 'ultra_pro_reader_screen.dart';
import '../services/verse_service.dart';

class ModernDashboardScreen extends StatefulWidget {
  final VoidCallback? onNavigateToSearch;
  
  const ModernDashboardScreen({super.key, this.onNavigateToSearch});

  @override
  State<ModernDashboardScreen> createState() => _ModernDashboardScreenState();
}

class _ModernDashboardScreenState extends State<ModernDashboardScreen> with SingleTickerProviderStateMixin {
  final PublicationService _service = PublicationService();
  final VerseService _verseService = VerseService();
  late Verse _verseOfTheDay;
  late Future<List<Publication>> _publicationsFuture;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  String _selectedCategory = 'Tous';
  final List<String> _categories = ['Tous', 'Meditation', 'Livret', 'Livre'];

  @override
  void initState() {
    super.initState();
    _verseOfTheDay = _verseService.getVerseOfTheDay();
    _publicationsFuture = _service.getPublications();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  List<Publication> _filterPublications(List<Publication> publications) {
    if (_selectedCategory == 'Tous') return publications;
    return publications.where((p) => p.type == _selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Hero Section
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: _buildHeroSection(),
            ),
          ),
          
          // Category Filter
          SliverToBoxAdapter(
            child: _buildCategoryFilter(),
          ),
          
          // Featured Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingM),
              child: Text(
                'Contenu à la une',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
          ),
          
          // Publications Grid
          FutureBuilder<List<Publication>>(
            future: _publicationsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return SliverToBoxAdapter(
                  child: _buildLoadingState(),
                );
              }
              
              if (snapshot.hasError) {
                return SliverToBoxAdapter(
                  child: _buildErrorState(snapshot.error.toString()),
                );
              }
              
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return SliverToBoxAdapter(
                  child: _buildEmptyState(),
                );
              }
              
              final filteredPubs = _filterPublications(snapshot.data!);
              
              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingM),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.7,
                    crossAxisSpacing: AppTheme.spacingM,
                    mainAxisSpacing: AppTheme.spacingM,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return _buildPublicationCard(filteredPubs[index], index);
                    },
                    childCount: filteredPubs.length,
                  ),
                ),
              );
            },
          ),
          
          const SliverToBoxAdapter(
            child: SizedBox(height: AppTheme.spacingXXL),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    final user = Provider.of<AuthService>(context).currentUser;
    final firstName = user != null ? user['name'].toString().split(' ')[0] : 'Bienvenue';

    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -30,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          
          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bonjour, $firstName',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Que souhaitez-vous lire aujourd\'hui ?',
                            style: GoogleFonts.lato(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                      if (user != null && user['avatar'] != null)
                        CircleAvatar(
                          backgroundImage: NetworkImage(user['avatar']),
                          radius: 24,
                        )
                      else
                        CircleAvatar(
                          backgroundColor: Colors.white.withOpacity(0.2),
                          radius: 24,
                          child: Text(
                            firstName[0].toUpperCase(),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingL),
                  
                  // Quote of the Day Card
                  PremiumCard(
                    color: Colors.white.withOpacity(0.15),
                    hasShadow: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.format_quote, color: AppTheme.primaryOrange, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'VERSET DU JOUR',
                              style: GoogleFonts.lato(
                                color: AppTheme.primaryOrange,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '"${_verseOfTheDay.text}"',
                          style: GoogleFonts.playfairDisplay(
                            color: Colors.white,
                            fontSize: 16,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            _verseOfTheDay.reference,
                            style: GoogleFonts.lato(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: AppTheme.spacingL),
                  _buildSearchBar(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Rechercher...',
          hintStyle: GoogleFonts.lato(color: Colors.grey),
          prefixIcon: const Icon(Icons.search, color: AppTheme.primaryBlue),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
        onTap: () {
          widget.onNavigateToSearch?.call();
        },
        readOnly: true,
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      height: 60,
      margin: const EdgeInsets.symmetric(vertical: AppTheme.spacingM),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingM),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = category == _selectedCategory;
          
          return Padding(
            padding: const EdgeInsets.only(right: AppTheme.spacingS),
            child: FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = category;
                });
              },
              backgroundColor: Colors.grey.shade100,
              selectedColor: AppTheme.primaryBlue,
              labelStyle: GoogleFonts.lato(
                color: isSelected ? Colors.white : AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: AppTheme.chipRadius,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPublicationCard(Publication publication, int index) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UltraProReaderScreen(publication: publication),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: AppTheme.cardRadius,
            boxShadow: AppTheme.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              Expanded(
                flex: 3,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryBlue.withOpacity(0.8),
                        AppTheme.accentOrange.withOpacity(0.8),
                      ],
                    ),
                  ),
                  child: publication.imageUrl != null
                      ? ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                          child: Image.network(
                            publication.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _buildPlaceholderImage(publication.type),
                          ),
                        )
                      : _buildPlaceholderImage(publication.type),
                ),
              ),
              
              // Content
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Type Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getTypeColor(publication.type).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _getTypeName(publication.type),
                          style: GoogleFonts.lato(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: _getTypeColor(publication.type),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Title
                      Expanded(
                        child: Text(
                          publication.titre,
                          style: GoogleFonts.lato(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      
                      // Footer
                      Row(
                        children: [
                          if (publication.estPayant)
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryOrange.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.star,
                                size: 12,
                                color: AppTheme.primaryOrange,
                              ),
                            ),
                          const Spacer(),
                          const Icon(
                            Icons.arrow_forward_ios,
                            size: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ],
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

  Widget _buildPlaceholderImage(String type) {
    return Center(
      child: Icon(
        _getTypeIcon(type),
        size: 48,
        color: Colors.white,
      ),
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'Meditation':
        return Icons.self_improvement;
      case 'Livret':
        return Icons.menu_book;
      case 'Livre':
        return Icons.auto_stories;
      default:
        return Icons.article;
    }
  }

  String _getTypeName(String type) {
    switch (type) {
      case 'Meditation':
        return 'MÉDITATION';
      case 'Livret':
        return 'LIVRET';
      case 'Livre':
        return 'LIVRE';
      default:
        return type.toUpperCase();
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'Meditation':
        return const Color(0xFF4CAF50);
      case 'Livret':
        return const Color(0xFF2196F3);
      case 'Livre':
        return AppTheme.accentOrange;
      default:
        return AppTheme.textSecondary;
    }
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(AppTheme.spacingXXL),
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: AppTheme.spacingM),
            Text(
              'Une erreur est survenue',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppTheme.spacingS),
            Text(
              error,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.library_books_outlined,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: AppTheme.spacingM),
            Text(
              'Aucun contenu disponible',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppTheme.spacingS),
            Text(
              'Revenez bientôt pour découvrir\nde nouveaux contenus',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
