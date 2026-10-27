import 'package:baggage_track_shell/main.dart';
import 'package:baggage_track_shell/models/baggage_event.dart';
import 'package:baggage_track_shell/models/baggage_status.dart';
import 'package:baggage_track_shell/repositories/baggage_event_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRepository implements BaggageEventRepository {
  _FakeRepository(this.events);

  final List<BaggageEvent> events;

  @override
  Future<EventsLoadResult> getEvents() async =>
      EventsLoadResult(events, fromCache: false);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

BaggageEvent _event(String baggageId, BaggageStatus status, int minute) =>
    BaggageEvent(
      id: '$baggageId-$minute',
      baggageId: baggageId,
      type: status.type,
      createdAt: DateTime(2026, 1, 1, 10, minute),
    );

void main() {
  testWidgets('muestra el catalogo inicial', (tester) async {
    await tester.pumpWidget(BaggageTrackApp(repository: _FakeRepository([])));
    await tester.pumpAndSettle();

    expect(find.text('BaggageTrack'), findsOneWidget);
    expect(find.text('BG-1001'), findsOneWidget);
    expect(find.text('Sin eventos'), findsWidgets);
    expect(find.text('Resumen por estado'), findsOneWidget);
  });

  testWidgets('muestra progreso y resumen calculados desde los eventos',
      (tester) async {
    final repository = _FakeRepository([
      _event('BG-1001', BaggageStatus.checkedIn, 1),
      _event('BG-1001', BaggageStatus.security, 2),
      _event('BG-1002', BaggageStatus.checkedIn, 3),
    ]);
    await tester.pumpWidget(BaggageTrackApp(repository: repository));
    await tester.pumpAndSettle();

    expect(find.text('40%'), findsOneWidget);
    expect(find.text('20%'), findsOneWidget);
    expect(find.text('SECURITY: 1'), findsOneWidget);
    expect(find.text('CHECKED_IN: 1'), findsOneWidget);
    expect(find.text('Sin eventos: 3'), findsOneWidget);
  });

  group('BaggageStatusCalculator', () {
    test('el estado actual es el del evento mas reciente', () {
      final events = [
        _event('A', BaggageStatus.security, 5),
        _event('A', BaggageStatus.checkedIn, 1),
      ];
      expect(BaggageStatusCalculator.currentStatus(events),
          BaggageStatus.security);
      expect(BaggageStatusCalculator.progress(events), 40);
    });

    test('porcentajes por estado', () {
      expect(
        BaggageStatus.values.map((s) => s.progress),
        [20, 40, 60, 80, 100],
      );
      expect(BaggageStatusCalculator.progress(const []), 0);
    });

    test('siguiente evento valido y estado terminal', () {
      expect(BaggageStatusCalculator.nextStatus(const []),
          BaggageStatus.checkedIn);
      expect(
        BaggageStatusCalculator.nextStatus(
            [_event('A', BaggageStatus.delivered, 1)]),
        isNull,
      );
    });

    test('resumen cuenta equipajes por estado', () {
      final summary = BaggageStatusCalculator.summary(
        ['A', 'B', 'C'],
        {
          'A': [_event('A', BaggageStatus.loaded, 1)],
          'B': [_event('B', BaggageStatus.loaded, 2)],
        },
      );
      expect(summary[BaggageStatus.loaded], 2);
      expect(summary[null], 1);
      expect(summary[BaggageStatus.delivered], 0);
    });
  });
}
