// lib/core/widgets/interest_type_selector.dart

import 'package:flutter/material.dart';

class InterestTypeSelector extends StatelessWidget {
  final String selectedType;
  final ValueChanged<String> onChanged;

  const InterestTypeSelector({
    super.key,
    required this.selectedType,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildChip(context, 'daily', 'Daily'),
        const SizedBox(width: 8),
        _buildChip(context, 'monthly', 'Monthly'),
        const SizedBox(width: 8),
        _buildChip(context, 'yearly', 'Yearly'),
      ],
    );
  }

  Widget _buildChip(BuildContext context, String value, String label) {
    final isSelected = selectedType == value;
    final theme = Theme.of(context);

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onChanged(value),
      selectedColor: theme.colorScheme.primary.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        color: isSelected ? theme.colorScheme.primary : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? theme.colorScheme.primary : Colors.grey.shade300,
      ),
    );
  }
}
