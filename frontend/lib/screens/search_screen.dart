import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/publication.dart';
import '../services/publication_service.dart';
import '../theme/app_theme.dart';
import 'ultra_pro_reader_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final PublicationService _service = PublicationService();
  List<Publication> _allPublications = [];
  List<Publication> _searchResults = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPublications();
  }

  Future<void> _loadPublications() async {
    try {
      final pubs = await _service.getPublications();
      setState(() {
        _allPublications = pubs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _filterPublications(String query) {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    final lowerQuery = query.toLowerCase();
    setState(() {
      _searchResults = _allPublications.where((p) {
        return p.titre.toLowerCase().contains(lowerQuery) ||
               p.contenuPrincipal.toLowerCase().contains(lowerQuery) ||
               (p.extrait?.toLowerCase().contains(lowerQuery) ?? false);
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacingM),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Rechercher un titre, un contenu...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _filterPublications('');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                ),
                onChanged: _filterPublications,
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _searchController.text.isEmpty
                      ? _buildEmptySearchState()
                      : _searchResults.isEmpty
                          ? _buildNoResultsState()
                          : ListView.builder(
                              padding: const EdgeInsets.all(AppTheme.spacingM),
                              itemCount: _searchResults.length,
                              itemBuilder: (context, index) {
                                final publication = _searchResults[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.all(AppTheme.spacingS),
                                    leading: Container(
                                      width: 60,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        image: publication.imageUrl != null
                                            ? DecorationImage(
                                                image: NetworkImage(publication.imageUrl!),
                                                fit: BoxFit.cover,
                                              )
                                            : null,
                                        color: AppTheme.primaryBlue.withOpacity(0.1),
                                      ),
                                      child: publication.imageUrl == null
                                          ? const Icon(Icons.book, color: AppTheme.primaryBlue)
                                          : null,
                                    ),
                                    title: Text(
                                      publication.titre,
                                      style: GoogleFonts.lato(fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Text(
                                      publication.type,
                                      style: GoogleFonts.lato(color: Colors.grey),
                                    ),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => UltraProReaderScreen(publication: publication),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptySearchState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Commencez votre recherche',
            style: GoogleFonts.lato(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.sentiment_dissatisfied, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Aucun résultat trouvé',
            style: GoogleFonts.lato(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
