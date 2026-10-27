import 'package:flutter/material.dart';

import '../models/baggage.dart';
import '../models/baggage_event.dart';
import '../models/baggage_status.dart';
import '../repositories/baggage_event_repository.dart';
import '../widgets/baggage_card.dart';
import '../widgets/progress_indicator_bar.dart';

class BaggageDetailPage extends StatefulWidget {
  const BaggageDetailPage({
    super.key,
    required this.baggage,
    required this.repository,
  });

  final Baggage baggage;
  final BaggageEventRepository repository;

  @override
  State<BaggageDetailPage> createState() => _BaggageDetailPageState();
}

class _BaggageDetailPageState extends State<BaggageDetailPage> {
  List<BaggageEvent> _events = [];
  bool _loading = true;
  bool _saving = false;
  bool _fromCache = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Sincroniza desde Firestore (con fallback a Drift) y filtra por equipaje.
  Future<void> _load() async {
    final result = await widget.repository.getEvents();
    final own = result.events
        .where((e) => e.baggageId == widget.baggage.id)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (!mounted) return;
    setState(() {
      _events = own;
      _fromCache = result.fromCache;
      _loading = false;
    });
  }

  Future<void> _register(BaggageStatus next) async {
    setState(() => _saving = true);
    String message;
    try {
      await widget.repository.registerEvent(widget.baggage.id, next);
      message = 'Evento ${next.type} registrado.';
      await _load();
    } on InvalidTransitionException catch (e) {
      message = e.message;
    } catch (_) {
      message = 'No se pudo guardar el evento en Firestore. '
          'No fue confirmado.';
    }
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = BaggageStatusCalculator.currentStatus(_events);
    final next = BaggageStatusCalculator.nextStatus(_events);

    return Scaffold(
      appBar: AppBar(title: Text(widget.baggage.id)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _BaggageHeader(baggage: widget.baggage, status: status),
          const SizedBox(height: 24),
          Text(
            'Historial de eventos',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 14),
          if (_fromCache && !_loading)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text('Mostrando datos locales (sin conexión).'),
            ),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_events.isEmpty)
            const _EmptyHistory()
          else
            for (final event in _events) _EventTile(event: event),
          const SizedBox(height: 18),
          if (next == null)
            const Text('El recorrido finalizó: equipaje entregado.')
          else
            FilledButton.icon(
              onPressed: _saving ? null : () => _register(next),
              icon: const Icon(Icons.add),
              label: Text(
                status == null
                    ? 'Registrar primer evento (${next.type})'
                    : 'Registrar ${next.type}',
              ),
            ),
        ],
      ),
    );
  }
}

class _BaggageHeader extends StatelessWidget {
  const _BaggageHeader({required this.baggage, required this.status});

  final Baggage baggage;
  final BaggageStatus? status;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                  child: Icon(
                    Icons.luggage,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        baggage.id,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 6),
                      StatusChip(status: status),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Progreso',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 6),
            BaggageProgressBar(percent: status?.progress ?? 0),
            const Divider(height: 28),
            Row(
              children: [
                Expanded(
                  child: _InfoField(
                    label: 'Pasajero',
                    value: baggage.passenger,
                  ),
                ),
                Expanded(
                  child: _InfoField(
                    label: 'Vuelo',
                    value: baggage.flight,
                  ),
                ),
                Expanded(
                  child: _InfoField(
                    label: 'Destino',
                    value: baggage.destination,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoField extends StatelessWidget {
  const _InfoField({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _EventTile extends StatelessWidget {
  const _EventTile({required this.event});

  final BaggageEvent event;

  String _format(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year} '
        '${two(d.hour)}:${two(d.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final status = BaggageStatus.fromType(event.type);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.check_circle_outline),
        title: Text(event.type),
        subtitle: Text(status?.label ?? ''),
        trailing: Text(_format(event.createdAt)),
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 34),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.history,
            size: 48,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 12),
          Text(
            'Este equipaje aun no tiene eventos.',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
