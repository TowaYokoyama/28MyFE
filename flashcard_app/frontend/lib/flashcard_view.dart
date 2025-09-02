import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models.dart' as model;
import 'api_service.dart';
import 'auth_service.dart';
import 'package:flip_card/flip_card.dart';

class FlashcardView extends StatefulWidget {
  final List<model.Card> cards;
  final int? deckId;

  const FlashcardView({super.key, required this.cards, this.deckId});

  @override
  State<FlashcardView> createState() => _FlashcardViewState();
}

class _FlashcardViewState extends State<FlashcardView> {
  final ApiService apiService = ApiService();
  int currentIndex = 0;
  GlobalKey<FlipCardState> cardKey = GlobalKey<FlipCardState>();

  void _nextCard() {
    if (currentIndex < widget.cards.length - 1) {
      setState(() {
        currentIndex++;
        cardKey = GlobalKey<FlipCardState>();
      });
    } else {
      Navigator.pop(context);
    }
  }

  void _updateMasteryAndGoToNext(int masteryLevel) {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.token == null) return;

    final card = widget.cards[currentIndex];
    apiService.updateCardMastery(card.id, masteryLevel, authService.token!).then((updatedCard) {
      setState(() {
        widget.cards[currentIndex] = updatedCard;
      });
      // Record study log
      apiService.createStudyLog(DateTime.now(), cardId: card.id, deckId: widget.deckId);
      _nextCard();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.cards.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('学習')),
        body: const Center(child: Text('学習するカードがありません。')),
      );
    }

    final card = widget.cards[currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: const Text('学習'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            MouseRegion(
              onEnter: (_) => cardKey.currentState?.toggleCard(),
              child: FlipCard(
                key: cardKey,
                direction: FlipDirection.HORIZONTAL,
                front: _buildCardFace(card.front, context),
                back: _buildCardFace(card.back, context),
              ),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    _updateMasteryAndGoToNext(0);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  ),
                  child: const Text('不正解', style: TextStyle(fontSize: 18)),
                ),
                ElevatedButton(
                  onPressed: () {
                    _updateMasteryAndGoToNext(1);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  ),
                  child: const Text('正解', style: TextStyle(fontSize: 18)),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildCardFace(String text, BuildContext context) {
    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.0)),
      child: SizedBox(
        width: 320,
        height: 220,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              text,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}