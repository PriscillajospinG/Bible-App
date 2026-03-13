import 'package:flutter/material.dart';

/// List tile for a Bible translation on [TranslationSelectionScreen].
///
/// Shows the short code (e.g. "KJV"), the full name, a "Ready" badge when the
/// translation is already loaded, or a spinner when it is being loaded.
class TranslationTile extends StatelessWidget {
  const TranslationTile({
    super.key,
    required this.translationCode,
    required this.fullName,
    required this.isLoaded,
    required this.isLoading,
    required this.onTap,
  });

  final String translationCode;
  final String fullName;
  final bool isLoaded;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: isLoading ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Row(
            children: [
              // Coloured abbreviation circle
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5EDD8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    translationCode,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: Color(0xFF6B4226),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Name + status
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (isLoaded && !isLoading)
                      Row(
                        children: [
                          Icon(Icons.check_circle_rounded,
                              size: 13, color: Colors.green.shade600),
                          const SizedBox(width: 4),
                          Text(
                            'Ready to read',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      )
                    else if (!isLoading)
                      Text(
                        'Tap to load',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                  ],
                ),
              ),
              // Right action
              if (isLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF6B4226),
                  ),
                )
              else
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFFBCA08A),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
