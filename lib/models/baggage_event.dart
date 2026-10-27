class BaggageEvent {
  const BaggageEvent({
    required this.id,
    required this.baggageId,
    required this.type,
    required this.createdAt,
  });

  final String id;
  final String baggageId;
  final String type;
  final DateTime createdAt;

  factory BaggageEvent.fromJson(Map<String, dynamic> json) {
    return BaggageEvent(
      id: json['id'] as String,
      baggageId: json['baggageId'] as String,
      type: json['type'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'baggageId': baggageId,
        'type': type,
        'createdAt': createdAt.toIso8601String(),
      };
}
