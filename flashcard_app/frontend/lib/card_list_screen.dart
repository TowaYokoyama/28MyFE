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
          title: const Text('Add New Card'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: frontController,
                decoration: const InputDecoration(hintText: "Front"),
              ),
              TextField(
                controller: backController,
                decoration: const InputDecoration(hintText: "Back"),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Add'),
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
        itemCount: cards.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(cards[index].front),
            subtitle: Text(cards[index].back),
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