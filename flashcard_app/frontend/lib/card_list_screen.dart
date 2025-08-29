import 'package:flutter/material.dart';
import 'models.dart' as model;
import 'api_service.dart';
import 'flashcard_view.dart';

class CardListScreen extends StatefulWidget {
  final model.Deck deck;

  const CardListScreen({super.key, required this.deck});

  @override
  State<CardListScreen> createState() => _CardListScreenState();
}

class _CardListScreenState extends State<CardListScreen> {
  final ApiService apiService = ApiService();
  late List<model.Card> cards;

  @override
  void initState() {
    super.initState();
    cards = widget.deck.cards;
  }

  void _showAddCardDialog() {
    final TextEditingController frontController = TextEditingController();
    final TextEditingController backController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('新しいカードを追加'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: frontController,
                decoration: const InputDecoration(hintText: "表面"),
              ),
              TextField(
                controller: backController,
                decoration: const InputDecoration(hintText: "裏面"),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('キャンセル'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('追加'),
              onPressed: () {
                if (frontController.text.isNotEmpty && backController.text.isNotEmpty) {
                  apiService
                      .createCard(frontController.text, backController.text, widget.deck.id)
                      .then((newCard) {
                    setState(() {
                      cards.add(newCard);
                    });
                    Navigator.of(context).pop();
                  });
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _deleteCard(int cardId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('カードを削除'),
          content: const Text('このカードを本当に削除しますか？'),
          actions: <Widget>[
            TextButton(
              child: const Text('キャンセル'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('削除'),
              onPressed: () {
                apiService.deleteCard(cardId).then((_) {
                  setState(() {
                    cards.removeWhere((card) => card.id == cardId);
                  });
                  Navigator.of(context).pop();
                });
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.deck.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.school),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FlashcardView(cards: cards),
                ),
              );
            },
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: cards.length,
        itemBuilder: (context, index) {
          final card = cards[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            elevation: 2.0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card.front,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    card.back,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: IconButton(
                      icon: Icon(Icons.delete, color: Colors.grey[600]),
                      onPressed: () {
                        _deleteCard(card.id);
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCardDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}