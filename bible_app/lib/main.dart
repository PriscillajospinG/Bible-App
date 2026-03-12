import 'package:flutter/material.dart';

import 'core/service_locator.dart';
import 'data/services/favorites_service.dart';
import 'data/services/panic_search_service.dart';
import 'ui/screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load Bible (KJV) and panic dataset concurrently.
  await Future.wait([
    bibleRepo.init(),
    panicRepo.init(),
  ]);

  // Wire up services that depend on repository data.
  panicSearchService = PanicSearchService(repository: panicRepo);
  favoritesService = FavoritesService();
  await favoritesService.init();

  debugPrint('Bible loaded — ${bibleRepo.allBookNames.length} books (KJV)');
  debugPrint('Panic dataset — ${panicRepo.count} entries');
  debugPrint('Favorites restored — ${favoritesService.count} saved');

  runApp(const BibleApp());
}

class BibleApp extends StatelessWidget {
  const BibleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bible App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6B4226)),
        useMaterial3: true,
        fontFamily: 'Georgia',
      ),
      home: const HomeScreen(),
    );
  }
}
