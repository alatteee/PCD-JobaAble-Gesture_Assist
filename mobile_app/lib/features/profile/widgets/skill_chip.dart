import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class SkillChip extends StatelessWidget {
  final String label;
  final VoidCallback? onDeleted;

  const SkillChip({super.key, required this.label, this.onDeleted});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Chip(
      label: Text(
        label,
        style: TextStyle(
          color: theme.colorScheme.onSecondaryContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: theme.colorScheme.secondaryContainer,
      deleteIcon: onDeleted != null
          ? Icon(Icons.close, size: 18, color: theme.colorScheme.onSecondaryContainer)
          : null,
      onDeleted: onDeleted,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      side: BorderSide.none,
    );
  }
}
