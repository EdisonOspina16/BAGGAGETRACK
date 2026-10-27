import 'package:flutter/material.dart';

import '../models/baggage_status.dart';

/// Variante H: cantidad de equipajes actualmente en cada estado.
class StatusSummary extends StatelessWidget {
  const StatusSummary({super.key, required this.counts});

  final Map<BaggageStatus?, int> counts;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resumen por estado',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _CountChip(label: 'Sin eventos', count: counts[null] ?? 0),
                for (final status in BaggageStatus.values)
                  _CountChip(label: status.type, count: counts[status] ?? 0),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Chip(
      visualDensity: VisualDensity.compact,
      label: Text('$label: $count'),
    );
  }
}
