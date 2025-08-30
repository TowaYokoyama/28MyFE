import 'package:flutter/material.dart';
import 'deck_list_screen.dart';
import 'study_calendar_screen.dart';
import 'study_options_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;
  final _deckListKey = GlobalKey<DeckListScreenState>();

  late final List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
    _widgetOptions = <Widget>[
      DeckListScreen(key: _deckListKey),
      const StudyCalendarScreen(),
      const StudyOptionsScreen(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final fab = _selectedIndex == 0
        ? FloatingActionButton(
            onPressed: () => _deckListKey.currentState?.showAddDeckDialog(),
            child: const Icon(Icons.add),
          )
        : null;

    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth < 600) {
        // Mobile Layout
        return Scaffold(
          appBar: AppBar(title: const Text('フラッシュカード')),
          body: Center(
            child: _widgetOptions.elementAt(_selectedIndex),
          ),
          floatingActionButton: fab,
          bottomNavigationBar: BottomNavigationBar(
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.style),
                label: 'デッキ',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.calendar_today),
                label: 'カレンダー',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.school),
                label: '学習',
              ),
            ],
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
          ),
        );
      } else {
        // Web/Desktop Layout
        return Scaffold(
          appBar: AppBar(title: const Text('フラッシュカード')),
          body: Row(
            children: <Widget>[
              NavigationRail(
                selectedIndex: _selectedIndex,
                onDestinationSelected: _onItemTapped,
                labelType: NavigationRailLabelType.all,
                destinations: const <NavigationRailDestination>[
                  NavigationRailDestination(
                    icon: Icon(Icons.style_outlined),
                    selectedIcon: Icon(Icons.style),
                    label: Text('デッキ'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.calendar_today_outlined),
                    selectedIcon: Icon(Icons.calendar_today),
                    label: Text('カレンダー'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.school_outlined),
                    selectedIcon: Icon(Icons.school),
                    label: Text('学習'),
                  ),
                ],
              ),
              const VerticalDivider(thickness: 1, width: 1),
              Expanded(
                child: Center(
                  child: _widgetOptions.elementAt(_selectedIndex),
                ),
              ),
            ],
          ),
          floatingActionButton: fab,
        );
      }
    });
  }
}
