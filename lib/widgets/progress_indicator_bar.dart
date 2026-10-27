import 'package:flutter/material.dart';

/// Barra de progreso con su porcentaje (variante H).
class BaggageProgressBar extends StatelessWidget {
  const BaggageProgressBar({super.key, required this.percent});

  final int percent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: percent / 100,
              minHeight: 8,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '$percent%',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
