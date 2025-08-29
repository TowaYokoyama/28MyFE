class Card {
  final int id;
  final String front;
  final String back;
  final int masteryLevel;
  final int deckId;

  Card({
    required this.id,
    required this.front,
    required this.back,
    required this.masteryLevel,
    required this.deckId,
  });

  factory Card.fromJson(Map<String, dynamic> json) {
    return Card(
      id: json['id'],
      front: json['front'],
      back: json['back'],
      masteryLevel: json['mastery_level'],
      deckId: json['deck_id'],
    );
  }
}

class Deck {
  final int id;
  final String name;
  final List<Card> cards;

  Deck({required this.id, required this.name, required this.cards});

  factory Deck.fromJson(Map<String, dynamic> json) {
    var cardList = json['cards'] as List;
    List<Card> cards = cardList.map((i) => Card.fromJson(i)).toList();

    return Deck(
      id: json['id'],
      name: json['name'],
      cards: cards,
    );
  }
}
