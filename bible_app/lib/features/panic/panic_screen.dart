import 'package:flutter/material.dart';

import '../../data/models/panic_response.dart';
import '../../data/services/panic_search_service.dart';
import 'widgets/panic_input_field.dart';
import 'widgets/panic_response_card.dart';

/// Main Panic Button screen.
///
/// User flow:
///   1. Read the header prompt.
///   2. Type a message in [PanicInputField].
///   3. Tap "Get Guidance".
///   4. [PanicResponseCard] slides in with the matched spiritual guidance.
class PanicScreen extends StatefulWidget {
  const PanicScreen({super.key, required this.searchService});

  final PanicSearchService searchService;

  @override
  State<PanicScreen> createState() => _PanicScreenState();
}

class _PanicScreenState extends State<PanicScreen> {
  final _controller = TextEditingController();
  final _scrollKey = GlobalKey();

  PanicResponse? _result;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final message = _controller.text.trim();
    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please describe what you\'re feeling first.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _result = null;
    });

    // Offload scoring to the next event-loop frame so the loading indicator
    // has time to render before the synchronous scoring loop runs.
    await Future.delayed(const Duration(milliseconds: 50));

    if (!mounted) return;

    try {
      final response = widget.searchService.findBestResponse(message);
      setState(() {
        _result = response;
        _isLoading = false;
      });

      // Scroll down so the result is immediately visible.
      await Future.delayed(const Duration(milliseconds: 100));
      if (mounted && _scrollKey.currentContext != null) {
        Scrollable.ensureVisible(
          _scrollKey.currentContext!,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      setState(() {
        _error = 'Something went wrong. Please try again.';
        _isLoading = false;
      });
    }
  }

  void _reset() {
    setState(() {
      _result = null;
      _error = null;
    });
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF6F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFF6B4226),
        foregroundColor: Colors.white,
        title: const Text(
          'Spiritual Guidance',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        elevation: 0,
        // Show a "Start over" action once a result is visible.
        actions: [
          if (_result != null)
            TextButton.icon(
              onPressed: _reset,
              icon: const Icon(Icons.refresh_rounded,
                  color: Colors.white70, size: 18),
              label: const Text(
                'New',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _Header(),
              const SizedBox(height: 20),
              PanicInputField(
                controller: _controller,
                onSubmit: _search,
                isLoading: _isLoading,
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                _ErrorBanner(message: _error!),
              ],
              if (_result != null) ...[
                const SizedBox(height: 28),
                const _ResultDivider(),
                const SizedBox(height: 20),
                // Anchor used for auto-scrolling to the result.
                SizedBox(key: _scrollKey, height: 0),
                PanicResponseCard(panicResponse: _result!),
              ],
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private sub-widgets
// ---------------------------------------------------------------------------

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFF5EDD8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD4C4A0)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.church_rounded,
            size: 42,
            color: Color(0xFF6B4226),
          ),
          const SizedBox(height: 10),
          Text(
            'You are not alone.',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF4A3728),
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 5),
          const Text(
            "Share what you're feeling.\nGod's Word has guidance for you.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF7A6A5A),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultDivider extends StatelessWidget {
  const _ResultDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: Color(0xFFD4C4A0))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            "GOD'S WORD FOR YOU",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.brown.shade400,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const Expanded(child: Divider(color: Color(0xFFD4C4A0))),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: Colors.red, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.red, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
