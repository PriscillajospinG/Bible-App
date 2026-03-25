import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/services/service_locator.dart';
import '../../features/bible/screens/translation_selection_screen.dart';
import '../../features/home/screens/today_screen.dart';
import '../../features/journal/screens/journal_screen.dart';
import '../../features/kyrie/screens/kyrie_screen.dart';
import '../../features/settings/screens/settings_screen.dart';

/// Root shell of the app.
///
/// Hosts a [BottomNavigationBar] with five tabs:
///   0 — Home (spiritual dashboard)
///   1 — Bible reader (TranslationSelectionScreen)
///   2 — Journal (JournalScreen)
///   3 — Kyrie (PanicScreen)
///   4 — Profile (SettingsScreen)
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
  bool _isLoaded = false;

  final _todayNavKey = GlobalKey<NavigatorState>();
  final _bibleNavKey = GlobalKey<NavigatorState>();
  final _journalNavKey = GlobalKey<NavigatorState>();
  final _kyrieNavKey = GlobalKey<NavigatorState>();
  final _profileNavKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    tabSwitchRequest.addListener(_onTabSwitchRequest);
    _initializeApp();
  }

  @override
  void dispose() {
    tabSwitchRequest.removeListener(_onTabSwitchRequest);
    super.dispose();
  }

  void _onTabSwitchRequest() {
    final tab = tabSwitchRequest.value;
    if (tab != null) {
      setState(() => _currentIndex = tab);
      tabSwitchRequest.value = null;
    }
  }

  Future<void> _initializeApp() async {
    debugPrint('Starting background initialization...');
    bibleDatasetInitInProgressNotifier.value = true;

    try {
      final bibleLoadFuture = localBibleService.loadBible().then((_) {
        bibleDatasetReadyNotifier.value = localBibleService.isLoaded;
      });

      await Future.any([
        bibleLoadFuture,
        Future.delayed(const Duration(seconds: 5)),
      ]);
    } catch (e) {
      debugPrint('Initialization error: $e');
    } finally {
      bibleDatasetReadyNotifier.value = localBibleService.isLoaded;
      bibleDatasetInitInProgressNotifier.value = false;
    }

    aiModelInitInProgressNotifier.value = true;
    unawaited(
      gemmaModelService.initializeModel().then((_) {
        aiModelReadyNotifier.value = gemmaModelService.isReady;
      }).catchError((Object e, StackTrace _) {
        aiModelReadyNotifier.value = false;
        debugPrint('Gemma background initialization failed: $e');
      }).whenComplete(() {
        aiModelInitInProgressNotifier.value = false;
      }),
    );

    if (!mounted) return;
    setState(() {
      _isLoaded = true;
    });
  }

  // ── Android back-button handling ───────────────────────────────────────────
  Future<bool> _onWillPop() async {
    final keys = [
      _todayNavKey,
      _bibleNavKey,
      _journalNavKey,
      _kyrieNavKey,
      _profileNavKey,
    ];
    final innerNav = keys[_currentIndex].currentState;
    if (innerNav != null && innerNav.canPop()) {
      innerNav.pop();
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded) {
      return const Scaffold(
        body: SafeArea(
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return ValueListenableBuilder<bool>(
      valueListenable: bibleDatasetInitInProgressNotifier,
      builder: (_, bibleLoading, __) {
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
            body: Column(
              children: [
                ValueListenableBuilder<bool>(
                  valueListenable: aiModelReadyNotifier,
                  builder: (_, ready, __) {
                    if (ready) return const SizedBox.shrink();
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      color: const Color(0xFFF5EAD8),
                      child: const Row(
                        children: [
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'AI initializing...',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF6B4226),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                Expanded(
                  child: IndexedStack(
                    index: _currentIndex,
                    children: [
                      _TabNavigator(
                        navigatorKey: _todayNavKey,
                        builder: () => const TodayScreen(),
                      ),
                      _TabNavigator(
                        navigatorKey: _bibleNavKey,
                        builder: () => const TranslationSelectionScreen(),
                      ),
                      _TabNavigator(
                        navigatorKey: _journalNavKey,
                        builder: () => const JournalScreen(),
                      ),
                      _TabNavigator(
                        navigatorKey: _kyrieNavKey,
                        builder: () => const PanicScreen(),
                      ),
                      _TabNavigator(
                        navigatorKey: _profileNavKey,
                        builder: () => const SettingsScreen(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (i) => setState(() => _currentIndex = i),
              type: BottomNavigationBarType.fixed,
              backgroundColor: const Color(0xFFFDF8F0),
              selectedItemColor: const Color(0xFF6B4226),
              unselectedItemColor: Colors.brown.shade400,
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home_rounded),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.menu_book_outlined),
                  activeIcon: Icon(Icons.menu_book_rounded),
                  label: 'Bible',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.edit_note_outlined),
                  activeIcon: Icon(Icons.edit_note_rounded),
                  label: 'Journal',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.volunteer_activism_outlined),
                  activeIcon: Icon(Icons.volunteer_activism_rounded),
                  label: 'Kyrie',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline_rounded),
                  activeIcon: Icon(Icons.person_rounded),
                  label: 'Profile',
                ),
              ],
            ),
          ),
        );
      },
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
