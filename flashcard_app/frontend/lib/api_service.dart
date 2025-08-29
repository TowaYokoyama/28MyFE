import 'dart:convert';
import 'package:http/http.dart' as http;
import 'models.dart';

class ApiService {
  final String baseUrl = "http://127.0.0.1:8000";

  Future<List<Deck>> getDecks() async {
    final response = await http.get(Uri.parse('$baseUrl/decks'));

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      List<Deck> decks = body.map((dynamic item) => Deck.fromJson(item)).toList();
      return decks;
    } else {
      throw Exception('Failed to load decks');
    }
  }

  Future<Deck> createDeck(String name) async {
    final response = await http.post(
      Uri.parse('$baseUrl/decks'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'name': name,
      }),
    );

    if (response.statusCode == 200) {
      return Deck.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create deck');
    }
  }

  Future<Card> createCard(String front, String back, int deckId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/cards'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'front': front,
        'back': back,
        'deck_id': deckId,
      }),
    );

    if (response.statusCode == 200) {
      return Card.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create card');
    }
  }

  Future<Card> updateCardMastery(int cardId, int masteryLevel) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/cards/$cardId'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'mastery_level': masteryLevel,
      }),
    );

    if (response.statusCode == 200) {
      return Card.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to update card');
    }
  }

  Future<void> deleteDeck(int deckId) async {
    final response = await http.delete(Uri.parse('$baseUrl/decks/$deckId'));
    if (response.statusCode != 200) {
      throw Exception('Failed to delete deck');
    }
  }

  Future<void> deleteCard(int cardId) async {
    final response = await http.delete(Uri.parse('$baseUrl/cards/$cardId'));
    if (response.statusCode != 200) {
      throw Exception('Failed to delete card');
    }
  }
}
