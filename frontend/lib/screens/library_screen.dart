import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/publication.dart';
import '../services/publication_service.dart';
import '../theme/app_theme.dart';
import 'ultra_pro_reader_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> with SingleTickerProviderStateMixin {
  final PublicationService _service = PublicationService();
  late Future<List<Publication>> _publicationsFuture;
  late TabController _tabController;
  
  final List<String> _categories = ['Tous', 'Meditation', 'Livret', 'Livre'];

  @override
  void initState() {
    super.initState();
    _publicationsFuture = _service.getPublications();
    _tabController = TabController(length: _categories.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Publication> _filterPublications(List<Publication> publications, String category) {
    if (category == 'Tous') return publications;
    return publications.where((p) => p.type == category).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bibliothèque'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppTheme.primaryBlue,
          labelColor: AppTheme.primaryBlue,
          unselectedLabelColor: AppTheme.textSecondary,
          labelStyle: GoogleFonts.lato(fontWeight: FontWeight.bold),
          tabs: _categories.map((c) => Tab(text: c)).toList(),
        ),
      ),
      body: FutureBuilder<List<Publication>>(
        future: _publicationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text('Erreur de chargement', style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Aucune publication.'));
          }

          final allPublications = snapshot.data!;

          return TabBarView(
            controller: _tabController,
            children: _categories.map((category) {
              final filtered = _filterPublications(allPublications, category);
              if (filtered.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.library_books_outlined, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(
                        'Aucun contenu dans cette catégorie',
                        style: GoogleFonts.lato(color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }
              return _buildGrid(filtered);
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildGrid(List<Publication> publications) {
    return GridView.builder(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: AppTheme.spacingM,
        mainAxisSpacing: AppTheme.spacingM,
      ),
      itemCount: publications.length,
      itemBuilder: (context, index) {
        final publication = publications[index];
        return _buildPublicationCard(publication, index);
      },
    );
  }

  Widget _buildPublicationCard(Publication publication, int index) {
    return GestureDetector(
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
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryBlue.withOpacity(0.8),
                      AppTheme.accentOrange.withOpacity(0.8),
                    ],
                  ),
                ),
                child: publication.imageUrl != null
                    ? ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
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
                    Text(
                      publication.type.toUpperCase(),
                      style: GoogleFonts.lato(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                    const SizedBox(height: 4),
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
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage(String type) {
    IconData icon;
    switch (type) {
      case 'Meditation': icon = Icons.self_improvement; break;
      case 'Livret': icon = Icons.menu_book; break;
      case 'Livre': icon = Icons.auto_stories; break;
      default: icon = Icons.article;
    }
    return Center(child: Icon(icon, size: 40, color: Colors.white));
  }
}
