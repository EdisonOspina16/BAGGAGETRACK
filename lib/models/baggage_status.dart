import 'baggage_event.dart';

/// Estados del recorrido, en el orden de la secuencia base.
enum BaggageStatus {
  checkedIn('CHECKED_IN', 'Registrado en aeropuerto', 20),
  security('SECURITY', 'Inspección de seguridad', 40),
  loaded('LOADED', 'Cargado en aeronave', 60),
  inTransit('IN_TRANSIT', 'En tránsito', 80),
  delivered('DELIVERED', 'Entregado', 100);

  const BaggageStatus(this.type, this.label, this.progress);

  final String type;
  final String label;

  /// Variante H: porcentaje de progreso asociado al estado.
  final int progress;

  BaggageStatus? get next {
    final index = BaggageStatus.values.indexOf(this);
    return index + 1 < BaggageStatus.values.length
        ? BaggageStatus.values[index + 1]
        : null;
  }

  static BaggageStatus? fromType(String type) {
    for (final status in BaggageStatus.values) {
      if (status.type == type) return status;
    }
    return null;
  }
}

/// Cálculos derivados del historial. Nada de esto se persiste.
class BaggageStatusCalculator {
  BaggageStatusCalculator._();

  /// Estado actual = evento más reciente. `null` equivale a "Sin eventos".
  static BaggageStatus? currentStatus(Iterable<BaggageEvent> events) {
    BaggageEvent? latest;
    for (final event in events) {
      if (latest == null || event.createdAt.isAfter(latest.createdAt)) {
        latest = event;
      }
    }
    return latest == null ? null : BaggageStatus.fromType(latest.type);
  }

  /// Porcentaje de progreso según el estado actual (0 si no hay eventos).
  static int progress(Iterable<BaggageEvent> events) =>
      currentStatus(events)?.progress ?? 0;

  /// Siguiente evento válido; sin eventos, el primero de la secuencia.
  static BaggageStatus? nextStatus(Iterable<BaggageEvent> events) {
    final current = currentStatus(events);
    return current == null ? BaggageStatus.values.first : current.next;
  }

  /// Variante H: cantidad de equipajes en cada estado. La clave `null`
  /// agrupa los equipajes sin eventos.
  static Map<BaggageStatus?, int> summary(
    Iterable<String> baggageIds,
    Map<String, List<BaggageEvent>> eventsByBaggage,
  ) {
    final result = <BaggageStatus?, int>{
      null: 0,
      for (final status in BaggageStatus.values) status: 0,
    };
    for (final id in baggageIds) {
      final status = currentStatus(eventsByBaggage[id] ?? const []);
      result[status] = result[status]! + 1;
    }
    return result;
  }
}
