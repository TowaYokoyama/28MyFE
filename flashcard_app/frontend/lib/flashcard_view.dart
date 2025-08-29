import 'package:flutter/material.dart';
import 'models.dart' as model;
import 'api_service.dart';
import 'package:flip_card/flip_card.dart';

class FlashcardView extends StatefulWidget {
  final List<model.Card> cards;

  const FlashcardView({super.key, required this.cards});

  @override
  State<FlashcardView> createState() => _FlashcardViewState();
}

class _FlashcardViewState extends State<FlashcardView> {
  final ApiService apiService = ApiService();
  int currentIndex = 0;
  GlobalKey<FlipCardState> cardKey = GlobalKey<FlipCardState>();

  void _nextCard() {
    setState(() {
      if (currentIndex < widget.cards.length - 1) {
        currentIndex++;
        cardKey = GlobalKey<FlipCardState>(); // Reset key to force rebuild and show front
      } else {
        // End of deck
        Navigator.pop(context);
      }
    });
  }

  void _updateMasteryAndGoToNext(int masteryLevel) {
    final card = widget.cards[currentIndex];
    apiService.updateCardMastery(card.id, masteryLevel).then((updatedCard) {
      setState(() {
        widget.cards[currentIndex] = updatedCard;
      });
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
            FlipCard(
              key: cardKey,
              direction: FlipDirection.HORIZONTAL,
              front: Card(
                elevation: 2.0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
                child: SizedBox(
                  width: 300,
                  height: 200,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        card.front,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
              back: Card(
                elevation: 2.0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
                child: SizedBox(
                  width: 300,
                  height: 200,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        card.back,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                                  ElevatedButton(
                    onPressed: () {
                      cardKey.currentState?.toggleCard(); // Flip back to front if needed
                      _updateMasteryAndGoToNext(0);
                    },
                    child: const Text('不正解'),
                    style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      cardKey.currentState?.toggleCard(); // Flip back to front if needed
                      _updateMasteryAndGoToNext(1);
                    },
                    child: const Text('正解'),
                    style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary),
                  ),
              ],
            )
          ],
        ),
      ),
    );
  }
}