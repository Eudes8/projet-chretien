import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/publication.dart';
import '../../services/auth_service.dart';
import '../../services/publication_service.dart';
import '../../theme/app_theme.dart';
import '../ultra_pro_editor_screen.dart';

class AdminContentScreen extends StatefulWidget {
  const AdminContentScreen({super.key});

  @override
  State<AdminContentScreen> createState() => _AdminContentScreenState();
}

class _AdminContentScreenState extends State<AdminContentScreen> {
  final PublicationService _service = PublicationService();
  List<Publication> _publications = [];
  List<Publication> _filteredPublications = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedFilter = 'Tous';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final pubs = await _service.getPublications();
      setState(() {
        _publications = pubs;
        _filterData();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _filterData() {
    setState(() {
      _filteredPublications = _publications.where((p) {
        final matchesSearch = p.titre.toLowerCase().contains(_searchQuery.toLowerCase());
        final matchesType = _selectedFilter == 'Tous' || p.type == _selectedFilter;
        return matchesSearch && matchesType;
      }).toList();
    });
  }

  Future<void> _delete(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Voulez-vous vraiment supprimer cette publication ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final authService = Provider.of<AuthService>(context, listen: false);
      await _service.deletePublication(id, authService.getAuthHeaders());
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Actions
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Rechercher...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (val) {
                    _searchQuery = val;
                    _filterData();
                  },
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedFilter,
                    items: ['Tous', 'Meditation', 'Livret', 'Livre']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedFilter = val;
                          _filterData();
                        });
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const UltraProEditorScreen()),
                  );
                  _loadData();
                },
                icon: const Icon(Icons.add),
                label: const Text('Ajouter'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Data Table
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: ListView.separated(
                      itemCount: _filteredPublications.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final pub = _filteredPublications[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                              image: pub.imageUrl != null
                                  ? DecorationImage(image: NetworkImage(pub.imageUrl!), fit: BoxFit.cover)
                                  : null,
                            ),
                            child: pub.imageUrl == null ? const Icon(Icons.image, color: Colors.grey) : null,
                          ),
                          title: Text(pub.titre, style: GoogleFonts.lato(fontWeight: FontWeight.bold)),
                          subtitle: Text(pub.type, style: GoogleFonts.lato(color: Colors.grey)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => UltraProEditorScreen(
                                        publicationId: pub.id.toString(),
                                        existingData: {
                                          'title': pub.titre,
                                          'content': pub.contenuPrincipal,
                                          'excerpt': pub.extrait,
                                          'type': pub.type,
                                          'isPaid': pub.estPayant,
                                          'coverImage': pub.imageUrl,
                                        },
                                      ),
                                    ),
                                  );
                                  _loadData();
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _delete(pub.id),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
