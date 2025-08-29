import 'package:flutter/material.dart';
import 'models.dart' as model;
import 'api_service.dart';

class FlashcardView extends StatefulWidget {
  final List<model.Card> cards;

  const FlashcardView({super.key, required this.cards});

  @override
  State<FlashcardView> createState() => _FlashcardViewState();
}

class _FlashcardViewState extends State<FlashcardView> {
  final ApiService apiService = ApiService();
  int currentIndex = 0;
  bool isFront = true;

  void _nextCard() {
    setState(() {
      if (currentIndex < widget.cards.length - 1) {
        currentIndex++;
        isFront = true;
      } else {
        Navigator.pop(context);
      }
    });
  }

  void _flipCard() {
    setState(() {
      isFront = !isFront;
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
        appBar: AppBar(title: const Text('Study')),
        body: const Center(child: Text('No cards to study.')),
      );
    }

    final card = widget.cards[currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Study'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: _flipCard,
              child: Card(
                child: SizedBox(
                  width: 300,
                  height: 200,
                  child: Center(
                    child: Text(
                      isFront ? card.front : card.back,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (!isFront)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () => _updateMasteryAndGoToNext(0),
                    child: const Text('Incorrect'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  ),
                  ElevatedButton(
                    onPressed: () => _updateMasteryAndGoToNext(1),
                    child: const Text('Correct'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  ),
                ],
              )
          ],
        ),
      ),
    );
  }
}