import 'dart:convert';
import 'package:http/http.dart' as http;
import 'models.dart' as model;
import 'auth_service.dart'; // Import AuthService

class ApiService {
  final String baseUrl = "https://my-flashcard-api.onrender.com";
  final AuthService _authService; // Store AuthService instance

  ApiService(this._authService); // Constructor to receive AuthService

  Map<String, String> _getHeaders() { // No token parameter needed here
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      if (_authService.token != null) 'Authorization': 'Bearer ${_authService.token}',
    };
  }

  // Generic request wrapper with token refresh logic
  Future<http.Response> _sendRequest(Future<http.Response> Function() request) async {
    http.Response response = await request();

    if (response.statusCode == 401) {
      // Token might be expired, try to refresh
      final bool refreshed = await _authService.refreshTokens();
      if (refreshed) {
        // Retry the original request with the new token
        response = await request();
      } else {
        // Refresh failed, user is logged out by authService.refreshToken()
        // Re-throw to propagate 401
        throw http.ClientException('Unauthorized: Token refresh failed.');
      }
    }
    return response;
  }

  Future<List<model.Deck>> getDecks() async { // Token parameter removed
    final response = await _sendRequest(() => http.get(
      Uri.parse('$baseUrl/decks'),
      headers: _getHeaders(), // Use _getHeaders without token parameter
    ));

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      List<model.Deck> decks = body.map((dynamic item) => model.Deck.fromJson(item)).toList();
      return decks;
    } else {
      throw Exception('Failed to load decks');
    }
  }

  Future<model.Deck> createDeck(String name) async { // Token parameter removed
    final response = await _sendRequest(() => http.post(
      Uri.parse('$baseUrl/decks'),
      headers: _getHeaders(),
      body: jsonEncode(<String, String>{'name': name}),
    ));

    if (response.statusCode == 200) {
      return model.Deck.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create deck');
    }
  }

  Future<model.Card> createCard(String front, String back, int deckId) async { // Token parameter removed
    final response = await _sendRequest(() => http.post(
      Uri.parse('$baseUrl/cards'),
      headers: _getHeaders(),
      body: jsonEncode(<String, dynamic>{
        'front': front,
        'back': back,
        'deck_id': deckId,
      }),
    ));

    if (response.statusCode == 200) {
      return model.Card.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create card');
    }
  }

  Future<model.Card> updateCard(int cardId, {String? front, String? back, int? masteryLevel}) async { // Token parameter removed
    final Map<String, dynamic> body = {};
    if (front != null) {
      body['front'] = front;
    }
    if (back != null) {
      body['back'] = back;
    }
    if (masteryLevel != null) {
      body['mastery_level'] = masteryLevel;
    }

    if (body.isEmpty) {
      throw ArgumentError('No update data provided to updateCard.');
    }

    final response = await _sendRequest(() => http.patch(
      Uri.parse('$baseUrl/cards/$cardId'),
      headers: _getHeaders(),
      body: jsonEncode(body),
    ));

    if (response.statusCode == 200) {
      return model.Card.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to update card. Status code: ${response.statusCode}');
    }
  }

  Future<void> deleteDeck(int deckId) async { // Token parameter removed
    final response = await _sendRequest(() => http.delete(
      Uri.parse('$baseUrl/decks/$deckId'),
      headers: _getHeaders(),
    ));
    if (response.statusCode != 200) {
      throw Exception('Failed to delete deck');
    }
  }

  Future<void> deleteCard(int cardId) async { // Token parameter removed
    final response = await _sendRequest(() => http.delete(
      Uri.parse('$baseUrl/cards/$cardId'),
      headers: _getHeaders(),
    ));
    if (response.statusCode != 200) {
      throw Exception('Failed to delete card');
    }
  }

  // --- Tag Methods ---

  Future<model.Tag> createTag(String name) async { // Token parameter removed
    final response = await _sendRequest(() => http.post(
      Uri.parse('$baseUrl/tags/'),
      headers: _getHeaders(),
      body: jsonEncode(<String, String>{'name': name}),
    ));

    if (response.statusCode == 200) {
      return model.Tag.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create tag');
    }
  }

  Future<List<model.Tag>> getTags() async { // Token parameter removed
    final response = await _sendRequest(() => http.get(
      Uri.parse('$baseUrl/tags/'),
      headers: _getHeaders(),
    ));

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((dynamic item) => model.Tag.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load tags');
    }
  }

  Future<model.Card> addTagToCard(int cardId, int tagId) async { // Token parameter removed
    final response = await _sendRequest(() => http.post(
      Uri.parse('$baseUrl/cards/$cardId/tags/$tagId'),
      headers: _getHeaders(),
    ));

    if (response.statusCode == 200) {
      return model.Card.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to add tag to card');
    }
  }

  Future<model.Card> removeTagFromCard(int cardId, int tagId) async { // Token parameter removed
    final response = await _sendRequest(() => http.delete(
      Uri.parse('$baseUrl/cards/$cardId/tags/$tagId'),
      headers: _getHeaders(),
    ));

    if (response.statusCode == 200) {
      return model.Card.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to remove tag from card');
    }
  }

  // Study logs are not protected for now
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

    final response = await http.get(Uri.parse(url)); // Study logs are not protected, so no _sendRequest wrapper
    // This is a design choice. If study logs become protected, this needs to be wrapped.

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