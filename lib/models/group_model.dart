class Group {
  final int? id;
  final String name;
  final int createdBy;
  final String? currency;
  final DateTime? startDate;
  final DateTime? endDate;
  final double? budget;
  final DateTime createdAt;

  Group({
    this.id,
    required this.name,
    required this.createdBy,
    this.currency,
    this.startDate,
    this.endDate,
    this.budget,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'created_by': createdBy,
      'currency': currency,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'budget': budget,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Group.fromMap(Map<String, dynamic> map) {
    return Group(
      id: map['id'] as int?,
      name: map['name'] as String,
      createdBy: map['created_by'] as int? ?? 0,
      currency: map['currency'] as String?,
      startDate: map['start_date'] != null
          ? DateTime.parse(map['start_date'] as String)
          : null,
      endDate: map['end_date'] != null
          ? DateTime.parse(map['end_date'] as String)
          : null,
      budget: map['budget'] != null ? (map['budget'] as num).toDouble() : null,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
