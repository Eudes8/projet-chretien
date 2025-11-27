import 'dart:math';

class Verse {
  final String text;
  final String reference;

  const Verse({required this.text, required this.reference});
}

class VerseService {
  static const List<Verse> _verses = [
    Verse(text: "Car Dieu a tant aimé le monde qu'il a donné son Fils unique, afin que quiconque croit en lui ne périsse point, mais qu'il ait la vie éternelle.", reference: "Jean 3:16"),
    Verse(text: "Je puis tout par celui qui me fortifie.", reference: "Philippiens 4:13"),
    Verse(text: "L'Éternel est mon berger: je ne manquerai de rien.", reference: "Psaumes 23:1"),
    Verse(text: "Ne vous inquiétez de rien; mais en toute chose faites connaître vos besoins à Dieu par des prières et des supplications, avec des actions de grâces.", reference: "Philippiens 4:6"),
    Verse(text: "Confie-toi en l'Éternel de tout ton cœur, et ne t'appuie pas sur ta sagesse.", reference: "Proverbes 3:5"),
    Verse(text: "Car je connais les projets que j'ai formés sur vous, dit l'Éternel, projets de paix et non de malheur, afin de vous donner un avenir et de l'espérance.", reference: "Jérémie 29:11"),
    Verse(text: "Si Dieu est pour nous, qui sera contre nous?", reference: "Romains 8:31"),
    Verse(text: "Soyez forts et courageux, ne craignez point et ne soyez point effrayés devant eux; car l'Éternel, ton Dieu, marchera lui-même avec toi, il ne te délaissera point, il ne t'abandonnera point.", reference: "Deutéronome 31:6"),
    Verse(text: "Venez à moi, vous tous qui êtes fatigués et chargés, et je vous donnerai du repos.", reference: "Matthieu 11:28"),
    Verse(text: "Mais ceux qui se confient en l'Éternel renouvellent leur force. Ils prennent le vol comme les aigles; Ils courent, et ne se lassent point, Ils marchent, et ne se fatiguent point.", reference: "Ésaïe 40:31"),
    Verse(text: "Que tout ce que vous faites se fasse avec amour.", reference: "1 Corinthiens 16:14"),
    Verse(text: "L'amour est patient, il est plein de bonté; l'amour n'est point envieux; l'amour ne se vante point, il ne s'enfle point d'orgueil.", reference: "1 Corinthiens 13:4"),
    Verse(text: "Recherchez la paix avec tous, et la sanctification, sans laquelle personne ne verra le Seigneur.", reference: "Hébreux 12:14"),
    Verse(text: "Car le salaire du péché, c'est la mort; mais le don gratuit de Dieu, c'est la vie éternelle en Jésus-Christ notre Seigneur.", reference: "Romains 6:23"),
    Verse(text: "Jésus lui dit: Je suis le chemin, la vérité, et la vie. Nul ne vient au Père que par moi.", reference: "Jean 14:6"),
  ];

  Verse getVerseOfTheDay() {
    final now = DateTime.now();
    // Utiliser le jour de l'année pour sélectionner un verset de manière déterministe
    final dayOfYear = int.parse("${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}");
    // Utiliser un générateur aléatoire avec une graine basée sur la date
    final random = Random(dayOfYear);
    return _verses[random.nextInt(_verses.length)];
  }
}
