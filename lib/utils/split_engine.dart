import 'dart:math';

class SplitMember {
  String email;
  int weight;
  double? percentage;
  double? manualAmount;

  SplitMember({
    required this.email,
    this.weight = 1,
    this.percentage,
    this.manualAmount,
  });
}

Map<String, double> smartSplit({
  required double total,
  required List<SplitMember> members,
  required String mode, // equal | weighted | percentage | manual
  int? seed,
}) {
  int totalCents = (total * 100).round();
  Map<String, int> result = {};

  if (mode == "manual") {
    for (var m in members) {
      result[m.email] = (m.manualAmount! * 100).round();
    }
  } else if (mode == "percentage") {
    for (var m in members) {
      int cents = ((total * m.percentage! / 100) * 100).round();
      result[m.email] = cents;
    }
  } else if (mode == "weighted") {
    int totalWeight = members.fold(0, (sum, m) => sum + m.weight);

    int distributed = 0;

    for (var m in members) {
      int cents = totalCents * m.weight ~/ totalWeight;
      result[m.email] = cents;
      distributed += cents;
    }

    // leftover cents added sequentially (not random)
    int remainder = totalCents - distributed;

    for (int i = 0; i < remainder; i++) {
      result[members[i].email] = result[members[i].email]! + 1;
    }
  } else if (mode == "equal") {
    final random = seed != null ? Random(seed) : Random();

    int base = totalCents ~/ members.length;
    int remainder = totalCents % members.length;

    for (var m in members) {
      result[m.email] = base;
    }

    List<String> keys = members.map((e) => e.email).toList()..shuffle(random);

    for (int i = 0; i < remainder; i++) {
      result[keys[i]] = result[keys[i]]! + 1;
    }
  }

  return result.map((k, v) => MapEntry(k, v / 100));
}
