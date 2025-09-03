class Tag {
  final int id;
  final String name;

  Tag({required this.id, required this.name});

  factory Tag.fromJson(Map<String, dynamic> json) {
    return Tag(
      id: json['id'],
      name: json['name'],
    );
  }
}

class Card {
  final int id;
  final String front;
  final String back;
  final int masteryLevel;
  final int deckId;
  final List<Tag> tags;

  Card({
    required this.id,
    required this.front,
    required this.back,
    required this.masteryLevel,
    required this.deckId,
    this.tags = const [],
  });

  factory Card.fromJson(Map<String, dynamic> json) {
    var tagsFromJson = json['tags'] as List? ?? [];
    List<Tag> tagList = tagsFromJson.map((i) => Tag.fromJson(i)).toList();

    return Card(
      id: json['id'],
      front: json['front'],
      back: json['back'],
      masteryLevel: json['mastery_level'],
      deckId: json['deck_id'],
      tags: tagList,
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

class StudyLog {
  final int id;
  final DateTime date;
  final int? cardId;
  final int? deckId;

  StudyLog({
    required this.id,
    required this.date,
    this.cardId,
    this.deckId,
  });

  factory StudyLog.fromJson(Map<String, dynamic> json) {
    return StudyLog(
      id: json['id'],
      date: DateTime.parse(json['date']),
      cardId: json['card_id'],
      deckId: json['deck_id'],
    );
  }
}