import 'package:flutter/material.dart';

import 'data/repositories/bible_repository.dart';
import 'data/repositories/panic_response_repository.dart';
import 'data/services/panic_search_service.dart';
import 'features/panic/panic_screen.dart';

// ---------------------------------------------------------------------------
// Singleton repositories and services — accessible app-wide.
// ---------------------------------------------------------------------------
final bibleRepo = BibleRepository();
final panicRepo = PanicResponseRepository();
late final PanicSearchService panicSearchService;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load both datasets concurrently from bundled assets.
  await Future.wait([
    bibleRepo.init(),
    panicRepo.init(),
  ]);

  // Wire up the search service now that the repository is populated.
  panicSearchService = PanicSearchService(repository: panicRepo);

  debugPrint('Bible loaded — ${bibleRepo.allBookNames.length} books');
  debugPrint('Panic dataset loaded — ${panicRepo.count} entries');

  runApp(const BibleApp());
}

// ---------------------------------------------------------------------------
// Root widget
// ---------------------------------------------------------------------------
class BibleApp extends StatelessWidget {
  const BibleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bible App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4A3728)),
        useMaterial3: true,
      ),
      home: PanicScreen(searchService: panicSearchService),
    );
  }
}


