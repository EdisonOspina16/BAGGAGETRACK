import 'package:drift/drift.dart';

import '../models/baggage_event.dart';
import 'app_database.dart';

class BaggageEventLocalDataSource {
  final AppDatabase db;
  BaggageEventLocalDataSource(this.db);

  BaggageEvent _toDomain(BaggageEventRow row) => BaggageEvent(
        id: row.id,
        baggageId: row.baggageId,
        type: row.type,
        createdAt: row.createdAt,
      );

  /// Guarda o actualiza un evento; los anteriores se conservan.
  Future<void> saveEvent(BaggageEvent event) async {
    await db.into(db.baggageEvents).insertOnConflictUpdate(
          BaggageEventsCompanion.insert(
            id: event.id,
            baggageId: event.baggageId,
            type: event.type,
            createdAt: event.createdAt,
          ),
        );
  }

  Future<void> saveEvents(Iterable<BaggageEvent> events) async {
    for (final event in events) {
      await saveEvent(event);
    }
  }

  Future<List<BaggageEvent>> getAllEvents() async {
    final rows = await db.select(db.baggageEvents).get();
    return rows.map(_toDomain).toList();
  }

  Future<List<BaggageEvent>> getEventsForBaggage(String baggageId) async {
    final rows = await (db.select(db.baggageEvents)
          ..where((t) => t.baggageId.equals(baggageId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
    return rows.map(_toDomain).toList();
  }
}
