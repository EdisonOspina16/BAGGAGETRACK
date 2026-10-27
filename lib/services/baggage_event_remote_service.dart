import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/baggage_event.dart';

/// Acceso a la colección `baggage_events`: un documento por evento.
class BaggageEventRemoteService {
  BaggageEventRemoteService(this.firestore);

  final FirebaseFirestore firestore;

  CollectionReference<Map<String, dynamic>> get _events =>
      firestore.collection('baggage_events');

  Future<List<BaggageEvent>> getEvents() async {
    final snapshot = await _events.get();
    return snapshot.docs
        .map((doc) => BaggageEvent.fromJson(doc.data()))
        .toList();
  }

  Future<void> saveEvent(BaggageEvent event) =>
      _events.doc(event.id).set(event.toJson());
}
