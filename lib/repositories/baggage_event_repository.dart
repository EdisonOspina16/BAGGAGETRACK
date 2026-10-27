import '../database/baggage_event_local_data_source.dart';
import '../models/baggage_event.dart';
import '../models/baggage_status.dart';
import '../services/baggage_event_remote_service.dart';

/// Resultado de una carga: los eventos y si provienen de la caché local.
class EventsLoadResult {
  const EventsLoadResult(this.events, {required this.fromCache});

  final List<BaggageEvent> events;
  final bool fromCache;
}

class InvalidTransitionException implements Exception {
  const InvalidTransitionException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Coordina Firestore (fuente remota) y Drift (caché local).
class BaggageEventRepository {
  BaggageEventRepository({
    required this.local,
    this.remote,
    this.timeout = const Duration(seconds: 10),
  });

  final BaggageEventLocalDataSource local;
  final BaggageEventRemoteService? remote;
  final Duration timeout;

  /// Intenta Firestore primero; si falla, usa el último estado en Drift.
  Future<EventsLoadResult> getEvents() async {
    try {
      final service = remote;
      if (service == null) throw StateError('Firebase no disponible');
      final events = await service.getEvents().timeout(timeout);
      await local.saveEvents(events);
      return EventsLoadResult(events, fromCache: false);
    } catch (_) {
      return EventsLoadResult(await local.getAllEvents(), fromCache: true);
    }
  }

  Future<List<BaggageEvent>> getEventsForBaggage(String baggageId) =>
      local.getEventsForBaggage(baggageId);

  /// Valida la transición, guarda en Firestore y luego en Drift. Si la
  /// escritura remota falla, el error se propaga y nada se confirma.
  Future<BaggageEvent> registerEvent(
    String baggageId,
    BaggageStatus status,
  ) async {
    final history = await local.getEventsForBaggage(baggageId);
    final expected = BaggageStatusCalculator.nextStatus(history);
    if (expected != status) {
      throw InvalidTransitionException(
        expected == null
            ? 'El equipaje ya fue entregado; no admite más eventos.'
            : 'Transición inválida: el siguiente evento debe ser '
                '${expected.type}.',
      );
    }

    final service = remote;
    if (service == null) {
      throw StateError('Firebase no disponible: no se pudo confirmar.');
    }
    final now = DateTime.now();
    final event = BaggageEvent(
      id: '${baggageId}_${now.microsecondsSinceEpoch}',
      baggageId: baggageId,
      type: status.type,
      createdAt: now,
    );
    await service.saveEvent(event).timeout(timeout);
    await local.saveEvent(event);
    return event;
  }
}
