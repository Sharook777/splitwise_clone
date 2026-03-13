import 'package:hive/hive.dart';

part 'user_model.g.dart';

@HiveType(typeId: 0)
class User extends HiveObject {
  // SQLite-only field (not stored in Hive)
  final int? id;

  @HiveField(0)
  final String name;

  @HiveField(1)
  final String email;

  @HiveField(2)
  final DateTime createdAt;

  User({this.id, required this.name, required this.email, DateTime? createdAt})
    : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int?,
      name: map['name'] as String,
      email: map['email'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
