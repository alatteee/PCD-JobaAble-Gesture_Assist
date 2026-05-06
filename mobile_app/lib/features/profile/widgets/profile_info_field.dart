import 'package:flutter/material.dart';

class ProfileInfoField extends StatelessWidget {
  final String label;
  final String value;

  const ProfileInfoField({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: theme.textTheme.titleMedium?.color,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: theme.brightness == Brightness.dark ? Colors.grey.shade900 : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Text(
              value,
              style: TextStyle(fontSize: 15, color: theme.textTheme.bodyLarge?.color),
            ),
          ),
        ],
      ),
    );
  }
}
