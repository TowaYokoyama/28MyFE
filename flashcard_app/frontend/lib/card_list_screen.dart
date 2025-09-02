import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models.dart' as model;
import 'api_service.dart';
import 'auth_service.dart';
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
    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.token == null) return;

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
                      .createCard(frontController.text, backController.text, widget.deck.id, authService.token!)
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
    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.token == null) return;

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
              child: Text('削除', style: TextStyle(color: Theme.of(context).colorScheme.error)),
              onPressed: () {
                apiService.deleteCard(cardId, authService.token!).then((_) {
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
            icon: const Icon(Icons.school_outlined),
            tooltip: '学習を開始',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FlashcardView(cards: cards, deckId: widget.deck.id),
                ),
              );
            },
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: cards.length,
        itemBuilder: (context, index) {
          final card = cards[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
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
                      icon: Icon(Icons.delete_outline, color: Colors.grey[400]),
                      onPressed: () => _deleteCard(card.id),
                      tooltip: 'カードを削除',
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