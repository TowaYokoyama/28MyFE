import 'dart:convert';
import 'package:http/http.dart' as http;
import 'models.dart' as model;

class ApiService {
  final String baseUrl = "http://127.0.0.1:8000";

  Future<List<model.Deck>> getDecks() async {
    final response = await http.get(Uri.parse('$baseUrl/decks'));

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      List<model.Deck> decks = body.map((dynamic item) => model.Deck.fromJson(item)).toList();
      return decks;
    } else {
      throw Exception('Failed to load decks');
    }
  }

  Future<model.Deck> createDeck(String name) async {
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
      return model.Deck.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create deck');
    }
  }

  Future<model.Card> createCard(String front, String back, int deckId) async {
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
      return model.Card.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create card');
    }
  }

  Future<model.Card> updateCardMastery(int cardId, int masteryLevel) async {
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
      return model.Card.fromJson(jsonDecode(response.body));
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

  Future<List<model.StudyLog>> getStudyLogs({DateTime? startDate, DateTime? endDate}) async {
    String url = '$baseUrl/study_logs';
    final Map<String, String> queryParams = {};
    if (startDate != null) {
      queryParams['start_date'] = startDate.toIso8601String().split('T').first;
    }
    if (endDate != null) {
      queryParams['end_date'] = endDate.toIso8601String().split('T').first;
    }
    if (queryParams.isNotEmpty) {
      url += '?' + Uri(queryParameters: queryParams).query;
    }

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((dynamic item) => model.StudyLog.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load study logs');
    }
  }

  Future<model.StudyLog> createStudyLog(DateTime date, {int? cardId, int? deckId}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/study_logs'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'date': date.toIso8601String().split('T').first,
        'card_id': cardId,
        'deck_id': deckId,
      }),
    );

    if (response.statusCode == 200) {
      return model.StudyLog.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create study log');
    }
  }
}
