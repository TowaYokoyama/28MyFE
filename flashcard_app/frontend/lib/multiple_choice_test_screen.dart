import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'models.dart' as model;

class MultipleChoiceTestScreen extends StatefulWidget {
  final List<model.Card> cards;
  final model.Deck deck;

  const MultipleChoiceTestScreen({super.key, required this.cards, required this.deck});

  @override
  State<MultipleChoiceTestScreen> createState() => _MultipleChoiceTestScreenState();
}

class _MultipleChoiceTestScreenState extends State<MultipleChoiceTestScreen> {
  int _currentIndex = 0;
  int _score = 0;
  List<String> _options = [];
  String? _selectedAnswer;
  bool _isAnswered = false;

  @override
  void initState() {
    super.initState();
    _generateOptions();
  }

  void _generateOptions() {
    final currentCard = widget.cards[_currentIndex];
    final correctAnswer = currentCard.back;

    final allIncorrectAnswers = widget.deck.cards
        .where((c) => c.id != currentCard.id)
        .map((c) => c.back)
        .toSet()
        .toList();

    allIncorrectAnswers.shuffle();

    final incorrectOptions = allIncorrectAnswers.take(3).toList();

    setState(() {
      _options = [correctAnswer, ...incorrectOptions];
      _options.shuffle();
      _selectedAnswer = null;
      _isAnswered = false;
    });
  }

  void _handleAnswer(String selectedAnswer) {
    setState(() {
      _isAnswered = true;
      _selectedAnswer = selectedAnswer;
    });

    final isCorrect = selectedAnswer == widget.cards[_currentIndex].back;
    if (isCorrect) {
      _score++;
    }

    Future.delayed(const Duration(seconds: 2), () {
      _nextQuestion();
    });
  }

  void _nextQuestion() {
    if (_currentIndex < widget.cards.length - 1) {
      setState(() {
        _currentIndex++;
        _generateOptions();
      });
    } else {
      _showResult();
    }
  }

  void _showResult() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('テスト結果'),
        content: Text('${widget.cards.length}問中、$_score問正解しました！'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Go back to options screen
            },
            child: const Text('終了'),
          ),
        ],
      ),
    );
  }

  Color _getButtonColor(String option) {
    if (!_isAnswered) {
      return Colors.grey.shade200;
    }
    final isCorrect = option == widget.cards[_currentIndex].back;
    if (isCorrect) {
      return Colors.green.shade300;
    }
    if (option == _selectedAnswer) {
      return Colors.red.shade300;
    }
    return Colors.grey.shade200;
  }

  @override
  Widget build(BuildContext context) {
    final currentCard = widget.cards[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.deck.name} - 四択テスト'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4.0),
          child: LinearProgressIndicator(
            value: (_currentIndex + 1) / widget.cards.length,
            backgroundColor: Colors.grey.shade300,
            valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('問題 ${_currentIndex + 1} / ${widget.cards.length}', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            Expanded(
              flex: 2,
              child: Card(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(currentCard.front, style: Theme.of(context).textTheme.headlineMedium),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: _options.map((option) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ElevatedButton(
                      onPressed: _isAnswered ? null : () => _handleAnswer(option),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _getButtonColor(option),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        textStyle: Theme.of(context).textTheme.titleMedium,
                      ),
                      child: Text(option),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
