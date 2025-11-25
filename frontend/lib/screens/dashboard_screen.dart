import 'package:flutter/material.dart';
import '../models/publication.dart';
import '../services/publication_service.dart';
import 'reading_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<List<Publication>> _featuredFuture;

  @override
  void initState() {
    super.initState();
    _featuredFuture = PublicationService().getPublications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de bord'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'À la une',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 10),
            FutureBuilder<List<Publication>>(
              future: _featuredFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('Erreur de chargement')));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('Aucun contenu disponible')));
                }

                final featured = snapshot.data!.first;
                return Card(
                  elevation: 4,
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ReadingScreen(publication: featured),
                        ),
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (featured.imageUrl != null)
                          Image.network(
                            featured.imageUrl!,
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(height: 150, color: Colors.grey[300], child: const Icon(Icons.image, size: 50)),
                          )
                        else
                          Container(
                            height: 150,
                            width: double.infinity,
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            child: Icon(Icons.auto_stories, size: 50, color: Theme.of(context).colorScheme.primary),
                          ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                featured.titre,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                featured.extrait ?? 'Découvrez ce contenu inspirant...',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 30),
            Text(
              'Collections',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 15),
            SizedBox(
              height: 120,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildCollectionCard(context, 'Prière', Icons.volunteer_activism),
                  _buildCollectionCard(context, 'Étude', Icons.menu_book),
                  _buildCollectionCard(context, 'Témoignages', Icons.record_voice_over),
                  _buildCollectionCard(context, 'Jeunesse', Icons.child_care),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollectionCard(BuildContext context, String title, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(right: 15, bottom: 5),
      elevation: 2,
      child: Container(
        width: 110,
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 35, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
