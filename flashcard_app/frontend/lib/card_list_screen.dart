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

class _TagManagementDialog extends StatefulWidget {
  final model.Card card;
  final ApiService apiService;
  final AuthService authService;

  const _TagManagementDialog({
    Key? key,
    required this.card,
    required this.apiService,
    required this.authService,
  }) : super(key: key);

  @override
  State<_TagManagementDialog> createState() => _TagManagementDialogState();
}

class _TagManagementDialogState extends State<_TagManagementDialog> {
  List<model.Tag> _allTags = [];
  Set<int> _cardTagIds = {}; // IDs of tags currently on the card
  final TextEditingController _newTagController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchTags();
    _cardTagIds = widget.card.tags.map((tag) => tag.id).toSet();
  }

  Future<void> _fetchTags() async {
    try {
      final tags = await widget.apiService.getTags(); // Token removed
      setState(() {
        _allTags = tags;
      });
    } catch (e) {
      // Handle error, e.g., show a SnackBar
      print('Failed to fetch tags: $e');
    }
  }

  Future<void> _createTag() async {
    if (_newTagController.text.isEmpty) return;

    try {
      final newTag = await widget.apiService.createTag(_newTagController.text); // Token removed
      setState(() {
        _allTags.add(newTag);
        _newTagController.clear();
      });
    } catch (e) {
      // Handle error, e.g., show a SnackBar
      print('Failed to create tag: $e');
    }
  }

  Future<void> _toggleTagOnCard(model.Tag tag, bool isChecked) async {
    try {
      model.Card updatedCard;
      if (isChecked) {
        updatedCard = await widget.apiService.addTagToCard(widget.card.id, tag.id); // Token removed
      } else {
        updatedCard = await widget.apiService.removeTagFromCard(widget.card.id, tag.id); // Token removed
      }
      setState(() {
        _cardTagIds = updatedCard.tags.map((t) => t.id).toSet();
        // Optionally, update the card in the parent widget's state if needed
      });
    } catch (e) {
      print('Failed to toggle tag on card: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('タグを管理'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // List of existing tags with checkboxes
            ..._allTags.map((tag) {
              final isChecked = _cardTagIds.contains(tag.id);
              return CheckboxListTile(
                title: Text(tag.name),
                value: isChecked,
                onChanged: (bool? value) {
                  if (value != null) {
                    _toggleTagOnCard(tag, value);
                  }
                },
              );
            }).toList(),
            const Divider(),
            // Add new tag section
            TextField(
              controller: _newTagController,
              decoration: InputDecoration(
                hintText: '新しいタグ名',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _createTag,
                ),
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('閉じる'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}

class _CardListScreenState extends State<CardListScreen> {
  late final ApiService apiService; // Changed to late final
  late List<model.Card> cards;

  @override
  void initState() {
    super.initState();
    apiService = Provider.of<ApiService>(context, listen: false); // Initialize here
    // Initial fetch of cards for the deck
    _fetchCardsForDeck();
  }

  // Method to fetch cards for the current deck
  Future<void> _fetchCardsForDeck() async {
    final authService = Provider.of<AuthService>(context, listen: false); // Still need authService for token
    if (authService.token == null) return;
    try {
      // Re-fetch the specific deck to get updated card list with tags
      final updatedDeck = await apiService.getDecks() // Token removed
          .then((decks) => decks.firstWhere((d) => d.id == widget.deck.id));
      setState(() {
        cards = updatedDeck.cards;
      });
    } catch (e) {
      print('Failed to re-fetch cards for deck: $e');
      // Optionally show an error message to the user
    }
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
                      .createCard(frontController.text, backController.text, widget.deck.id) // Token removed
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

  void _showEditCardDialog(model.Card card) {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.token == null) return;

    final TextEditingController frontController = TextEditingController(text: card.front);
    final TextEditingController backController = TextEditingController(text: card.back);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('カードを編集'),
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
              child: const Text('保存'),
              onPressed: () {
                if (frontController.text.isNotEmpty && backController.text.isNotEmpty) {
                  apiService
                      .updateCard(card.id, front: frontController.text, back: backController.text) // Token removed
                      .then((updatedCard) {
                    setState(() {
                      final index = cards.indexWhere((c) => c.id == card.id);
                      if (index != -1) {
                        cards[index] = updatedCard;
                      }
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

  void _showTagManagementDialog(model.Card card) {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.token == null) return;

    showDialog(
      context: context,
      builder: (context) {
        return _TagManagementDialog(
          card: card,
          apiService: apiService,
          authService: authService,
        );
      },
    ).then((_) {
      // Re-fetch cards after dialog closes to ensure tags are updated in the parent list
      _fetchCardsForDeck();
    });
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
                apiService.deleteCard(cardId) // Token removed
                    .then((_) {
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
                  const SizedBox(height: 8.0),
                  // Display tags using Wrap and Chip widgets
                  if (card.tags.isNotEmpty)
                    Wrap(
                      spacing: 6.0,
                      runSpacing: 6.0,
                      children: card.tags.map((tag) => Chip(
                        label: Text(tag.name),
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      )).toList(),
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: Icon(Icons.label_outline, color: Colors.grey[400]),
                        onPressed: () => _showTagManagementDialog(card),
                        tooltip: 'タグを管理',
                      ),
                      IconButton(
                        icon: Icon(Icons.edit_outlined, color: Colors.grey[400]),
                        onPressed: () => _showEditCardDialog(card),
                        tooltip: 'カードを編集',
                      ),
                      IconButton(
                        icon: Icon(Icons.delete_outline, color: Colors.grey[400]),
                        onPressed: () => _deleteCard(card.id),
                        tooltip: 'カードを削除',
                      ),
                    ],
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