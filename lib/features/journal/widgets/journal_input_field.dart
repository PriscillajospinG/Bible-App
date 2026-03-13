import 'package:flutter/material.dart';

/// Multi-line text field used in the Journal entry screen.
class JournalInputField extends StatelessWidget {
  const JournalInputField({
    super.key,
    required this.controller,
    this.focusNode,
    this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      maxLines: null,
      minLines: 5,
      keyboardType: TextInputType.multiline,
      textCapitalization: TextCapitalization.sentences,
      style: const TextStyle(fontSize: 15, height: 1.6),
      decoration: InputDecoration(
        hintText:
            'How are you feeling today? Share what is on your heart…',
        hintStyle: TextStyle(
          color: Colors.brown.shade300,
          fontSize: 14,
          fontStyle: FontStyle.italic,
        ),
        filled: true,
        fillColor: const Color(0xFFFDFAF5),
        contentPadding: const EdgeInsets.all(16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.brown.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.brown.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF6B4226), width: 1.5),
        ),
      ),
    );
  }
}
