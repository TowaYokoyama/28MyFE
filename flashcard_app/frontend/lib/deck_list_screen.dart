import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'api_service.dart';
import 'auth_service.dart';
import 'models.dart' as model;
import 'card_list_screen.dart';

class DeckListScreen extends StatefulWidget {
  const DeckListScreen({super.key});

  @override
  State<DeckListScreen> createState() => DeckListScreenState();
}

class DeckListScreenState extends State<DeckListScreen> {
  final ApiService apiService = ApiService();
  Future<List<model.Deck>>? futureDecks;

  @override
  void initState() {
    super.initState();
    // Defer getting the token until the first build when context is available.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _refreshDecks();
      }
    });
  }

  void _refreshDecks() {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.token == null) {
      if (mounted) {
        setState(() {
          futureDecks = Future.value([]);
        });
      }
      return;
    }
    if (mounted) {
      setState(() {
        futureDecks = apiService.getDecks(authService.token!);
      });
    }
  }

  void showAddDeckDialog() {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.token == null) return;

    final TextEditingController nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('新しいデッキを追加'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(hintText: "デッキ名"),
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
                if (nameController.text.isNotEmpty) {
                  apiService.createDeck(nameController.text, authService.token!).then((_) {
                    if (!mounted) return;
                    _refreshDecks();
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

  void _deleteDeck(int deckId) {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.token == null) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('デッキを削除'),
          content: const Text('このデッキを本当に削除しますか？'),
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
                apiService.deleteDeck(deckId, authService.token!).then((_) {
                  if (!mounted) return;
                  _refreshDecks();
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
    final future = futureDecks;
    if (future == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return FutureBuilder<List<model.Deck>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('エラー: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('デッキがありません。「+」ボタンで追加してください。'));
          } else {
            return GridView.builder(
              padding: const EdgeInsets.all(24.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 20.0,
                mainAxisSpacing: 20.0,
                childAspectRatio: 0.9,
              ),
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final deck = snapshot.data![index];
                return DeckCard(
                  deck: deck,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CardListScreen(deck: deck),
                      ),
                    ).then((_) => _refreshDecks());
                  },
                  onDelete: () => _deleteDeck(deck.id),
                );
              },
            );
          }
        },
      );
  }
}

class DeckCard extends StatefulWidget {
  final model.Deck deck;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const DeckCard({
    super.key,
    required this.deck,
    required this.onTap,
    required this.onDelete,
  });

  @override
  State<DeckCard> createState() => _DeckCardState();
}

class _DeckCardState extends State<DeckCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onTap,
        onFocusChange: (isFocused) => setState(() => _isHovered = isFocused),
        borderRadius: BorderRadius.circular(16.0),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.0),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
                      blurRadius: 12.0,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      blurRadius: 8.0,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      widget.deck.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0, right: 4.0),
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: IconButton(
                    icon: Icon(Icons.delete_outline, color: Colors.grey[400]),
                    onPressed: widget.onDelete,
                    tooltip: 'デッキを削除',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

