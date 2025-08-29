import 'package:flutter/material.dart';
import 'api_service.dart';
import 'models.dart';
import 'card_list_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flashcard App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const DeckListScreen(),
    );
  }
}

class DeckListScreen extends StatefulWidget {
  const DeckListScreen({super.key});

  @override
  State<DeckListScreen> createState() => _DeckListScreenState();
}

class _DeckListScreenState extends State<DeckListScreen> {
  final ApiService apiService = ApiService();
  late Future<List<Deck>> futureDecks;

  @override
  void initState() {
    super.initState();
    _refreshDecks();
  }

  void _refreshDecks() {
    setState(() {
      futureDecks = apiService.getDecks();
    });
  }

  void _showAddDeckDialog() {
    final TextEditingController nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Deck'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(hintText: "Deck Name"),
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
                if (nameController.text.isNotEmpty) {
                  apiService.createDeck(nameController.text).then((_) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Decks'),
      ),
      body: FutureBuilder<List<Deck>>(
        future: futureDecks,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No decks found. Tap + to add one.'));
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final deck = snapshot.data![index];
                return ListTile(
                  title: Text(deck.name),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CardListScreen(deck: deck),
                      ),
                    ).then((_) => _refreshDecks());
                  },
                );
              },
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDeckDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}