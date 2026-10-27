import 'package:flutter/material.dart';

import '../data/baggage_seed.dart';
import '../models/baggage.dart';
import '../models/baggage_event.dart';
import '../models/baggage_status.dart';
import '../repositories/baggage_event_repository.dart';
import '../widgets/baggage_card.dart';
import '../widgets/status_summary.dart';
import 'baggage_detail_page.dart';

class BaggageListPage extends StatefulWidget {
  const BaggageListPage({super.key, required this.repository});

  final BaggageEventRepository repository;

  @override
  State<BaggageListPage> createState() => _BaggageListPageState();
}

class _BaggageListPageState extends State<BaggageListPage> {
  Map<String, List<BaggageEvent>> _eventsByBaggage = {};
  bool _fromCache = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await widget.repository.getEvents();
    final grouped = <String, List<BaggageEvent>>{};
    for (final event in result.events) {
      grouped.putIfAbsent(event.baggageId, () => []).add(event);
    }
    if (!mounted) return;
    setState(() {
      _eventsByBaggage = grouped;
      _fromCache = result.fromCache;
      _loading = false;
    });
  }

  Future<void> _openDetail(Baggage baggage) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BaggageDetailPage(
          baggage: baggage,
          repository: widget.repository,
        ),
      ),
    );
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    final counts = BaggageStatusCalculator.summary(
      baggageSeed.map((b) => b.id),
      _eventsByBaggage,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.luggage_outlined),
            SizedBox(width: 10),
            Text('BaggageTrack'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Recargar',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_loading) const LinearProgressIndicator(),
            if (_fromCache && !_loading) ...[
              const _OfflineBanner(),
              const SizedBox(height: 12),
            ],
            StatusSummary(counts: counts),
            const SizedBox(height: 12),
            for (final baggage in baggageSeed) ...[
              BaggageCard(
                baggage: baggage,
                status: BaggageStatusCalculator.currentStatus(
                  _eventsByBaggage[baggage.id] ?? const [],
                ),
                onTap: () => _openDetail(baggage),
              ),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.tertiaryContainer,
      child: const Padding(
        padding: EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.cloud_off),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Sin conexión con Firestore. Mostrando datos locales '
                '(último estado conocido).',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
