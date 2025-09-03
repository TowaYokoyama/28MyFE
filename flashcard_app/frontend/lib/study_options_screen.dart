import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_service.dart';
import 'api_service.dart';
import 'models.dart' as model;
import 'flashcard_view.dart';
import 'multiple_choice_test_screen.dart';

enum StudyMode { normal, random, multipleChoice }

enum MasteryFilter { all, notMastered, mastered }

class StudyOptionsScreen extends StatefulWidget {
  const StudyOptionsScreen({super.key});

  @override
  State<StudyOptionsScreen> createState() => _StudyOptionsScreenState();
}

class _StudyOptionsScreenState extends State<StudyOptionsScreen> {
  late final ApiService apiService;
  model.Deck? _selectedDeck;
  StudyMode _studyMode = StudyMode.normal;
  MasteryFilter _masteryFilter = MasteryFilter.all;

  @override
  void initState() {
    super.initState();
    apiService = Provider.of<ApiService>(context, listen: false);
  }

  void _startStudySession() {
    if (_selectedDeck == null) return;

    List<model.Card> filteredCards = _selectedDeck!.cards;

    // Apply mastery filter
    switch (_masteryFilter) {
      case MasteryFilter.notMastered:
        filteredCards = filteredCards.where((c) => c.masteryLevel == 0).toList();
        break;
      case MasteryFilter.mastered:
        filteredCards = filteredCards.where((c) => c.masteryLevel == 1).toList();
        break;
      case MasteryFilter.all:
        break;
    }

    if (filteredCards.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('選択された条件に合うカードがありません。')),
      );
      return;
    }

    // Apply study mode
    if (_studyMode == StudyMode.random) {
      filteredCards.shuffle();
    }

    // Navigate to the correct screen
    if (_studyMode == StudyMode.multipleChoice) {
       if (filteredCards.length < 4) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('四択テストには4枚以上のカードが必要です。')),
        );
        return;
      }
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MultipleChoiceTestScreen(cards: filteredCards, deck: _selectedDeck!),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FlashcardView(cards: filteredCards, deckId: _selectedDeck!.id),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('学習設定'),
      ),
      body: _selectedDeck == null
          ? _buildDeckSelection()
          : _buildStudyConfiguration(),
    );
  }

  Widget _buildDeckSelection() {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.token == null) {
      return const Center(child: Text('ログインしてください。'));
    }

    return FutureBuilder<List<model.Deck>>(
      future: apiService.getDecks(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('エラー: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('学習するデッキがありません。'));
        }

        final decks = snapshot.data!;
        return ListView.builder(
          itemCount: decks.length,
          itemBuilder: (context, index) {
            final deck = decks[index];
            return ListTile(
              title: Text(deck.name),
              subtitle: Text('${deck.cards.length}枚のカード'),
              onTap: () {
                setState(() {
                  _selectedDeck = deck;
                });
              },
            );
          },
        );
      },
    );
  }

  Widget _buildStudyConfiguration() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('デッキ: ${_selectedDeck!.name}', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 24),
          Text('学習モード', style: Theme.of(context).textTheme.titleLarge),
          SegmentedButton<StudyMode>(
            segments: const <ButtonSegment<StudyMode>>[
              ButtonSegment(value: StudyMode.normal, label: Text('通常'), icon: Icon(Icons.sort_by_alpha)),
              ButtonSegment(value: StudyMode.random, label: Text('ランダム'), icon: Icon(Icons.shuffle)),
              ButtonSegment(value: StudyMode.multipleChoice, label: Text('四択'), icon: Icon(Icons.quiz)),
            ],
            selected: {_studyMode},
            onSelectionChanged: (newSelection) {
              setState(() {
                _studyMode = newSelection.first;
              });
            },
          ),
          const SizedBox(height: 24),
          Text('フィルター', style: Theme.of(context).textTheme.titleLarge),
          SegmentedButton<MasteryFilter>(
            segments: const <ButtonSegment<MasteryFilter>>[
              ButtonSegment(value: MasteryFilter.all, label: Text('すべて')),
              ButtonSegment(value: MasteryFilter.notMastered, label: Text('未習熟')),
              ButtonSegment(value: MasteryFilter.mastered, label: Text('習熟済み')),
            ],
            selected: {_masteryFilter},
            onSelectionChanged: (newSelection) {
              setState(() {
                _masteryFilter = newSelection.first;
              });
            },
          ),
          const Spacer(),
          Center(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.play_arrow),
              label: const Text('学習開始'),
              onPressed: _startStudySession,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                textStyle: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ),
          Center(
            child: TextButton(
              onPressed: () {
                setState(() {
                  _selectedDeck = null;
                });
              },
              child: const Text('他のデッキを選択'),
            ),
          )
        ],
      ),
    );
  }
}