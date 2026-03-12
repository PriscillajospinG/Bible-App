import 'package:flutter/material.dart';

import '../../core/service_locator.dart';
import '../../features/bible/screens/translation_selection_screen.dart';
import '../../features/journal/journal_placeholder_screen.dart';
import '../../features/panic/panic_screen.dart';

/// Root shell of the app.
///
/// Hosts a [NavigationBar] with three tabs:
///   0 — Bible reader (TranslationSelectionScreen)
///   1 — Spiritual guidance (PanicScreen)
///   2 — Journal (placeholder for Step 4)
///
/// Each tab is wrapped in its own [Navigator] so navigation within a tab
/// (e.g. Bible: translation → testament → book → chapter → verse) is
/// independent and preserved when switching tabs.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final _bibleNavKey = GlobalKey<NavigatorState>();
  final _panicNavKey = GlobalKey<NavigatorState>();
  final _journalNavKey = GlobalKey<NavigatorState>();

  // ── Android back-button handling ───────────────────────────────────────────
  // Pop the active tab's inner navigator first; exit the app only when the
  // inner navigator has no more routes to pop.
  Future<bool> _onWillPop() async {
    final activeKey = [_bibleNavKey, _panicNavKey, _journalNavKey][_currentIndex];
    final innerNav = activeKey.currentState;
    if (innerNav != null && innerNav.canPop()) {
      innerNav.pop();
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: [
            _TabNavigator(
              navigatorKey: _bibleNavKey,
              builder: () => const TranslationSelectionScreen(),
            ),
            _TabNavigator(
              navigatorKey: _panicNavKey,
              builder: () => PanicScreen(searchService: panicSearchService),
            ),
            _TabNavigator(
              navigatorKey: _journalNavKey,
              builder: () => const JournalPlaceholderScreen(),
            ),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (i) => setState(() => _currentIndex = i),
          backgroundColor: const Color(0xFFFDF8F0),
          indicatorColor: const Color(0xFFF0E9D2),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.menu_book_outlined),
              selectedIcon: Icon(Icons.menu_book, color: Color(0xFF6B4226)),
              label: 'Bible',
            ),
            NavigationDestination(
              icon: Icon(Icons.volunteer_activism_outlined),
              selectedIcon: Icon(
                Icons.volunteer_activism,
                color: Color(0xFF6B4226),
              ),
              label: 'Guidance',
            ),
            NavigationDestination(
              icon: Icon(Icons.edit_note_outlined),
              selectedIcon:
                  Icon(Icons.edit_note_rounded, color: Color(0xFF6B4226)),
              label: 'Journal',
            ),
          ],
        ),
      ),
    );
  }
}

/// Wraps a tab's root widget in its own [Navigator] so each tab maintains an
/// independent navigation stack.
class _TabNavigator extends StatelessWidget {
  const _TabNavigator({
    required this.navigatorKey,
    required this.builder,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final Widget Function() builder;

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      onGenerateRoute: (settings) => MaterialPageRoute(
        settings: settings,
        builder: (_) => builder(),
      ),
    );
  }
}
