class CalculationHistory {
  final int? id;
  final double a;
  final double b;
  final double c;
  final String equation;
  final String discriminant;
  final String message;
  final List<String> roots;
  final String type;
  final DateTime timestamp;

  CalculationHistory({
    this.id,
    required this.a,
    required this.b,
    required this.c,
    required this.equation,
    required this.discriminant,
    required this.message,
    required this.roots,
    required this.type,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'a': a,
      'b': b,
      'c': c,
      'equation': equation,
      'discriminant': discriminant,
      'message': message,
      'roots': roots.join('|'),
      'type': type,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory CalculationHistory.fromMap(Map<String, dynamic> map) {
    return CalculationHistory(
      id: map['id'],
      a: map['a'],
      b: map['b'],
      c: map['c'],
      equation: map['equation'],
      discriminant: map['discriminant'],
      message: map['message'],
      roots: (map['roots'] as String).split('|'),
      type: map['type'],
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}