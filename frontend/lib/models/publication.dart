class Publication {
  final int id;
  final String titre;
  final String contenuPrincipal;
  final String? imageUrl;
  final String type;
  final bool estPayant;
  final String? idProduitStore;
  final String? extrait;

  Publication({
    required this.id,
    required this.titre,
    required this.contenuPrincipal,
    this.imageUrl,
    required this.type,
    required this.estPayant,
    this.idProduitStore,
    this.extrait,
  });

  factory Publication.fromJson(Map<String, dynamic> json) {
    return Publication(
      id: json['id'] as int,
      titre: json['title'] as String,
      contenuPrincipal: json['content'] as String,
      imageUrl: json['coverImage'] as String?,
      type: json['type'] as String,
      estPayant: json['isPaid'] as bool? ?? false,
      idProduitStore: json['productId'] as String?,
      extrait: json['excerpt'] as String?,
    );
  }
}