import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user_model.dart';

import '../models/group_model.dart';

/// Service to manage User data in SQLite (local relational storage).
class DatabaseService {
  static Database? _database;

  static Future<Database> get database async {
    if (_database == null) {
      _database = await _initDB();
      // Ensure tables exist regardless of version (fallback for failed migrations)
      await _createTables(_database!);
    }
    return _database!;
  }

  static Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'dutch.db');

    return await openDatabase(
      path,
      version: 6,
      onCreate: (db, version) async {
        await _createTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS friends (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              user_email TEXT NOT NULL,
              friend_email TEXT NOT NULL,
              UNIQUE(user_email, friend_email)
            )
          ''');
        }
        if (oldVersion < 3) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS groups (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              created_at TEXT NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS group_members (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              group_id INTEGER NOT NULL,
              user_email TEXT NOT NULL,
              FOREIGN KEY (group_id) REFERENCES groups (id) ON DELETE CASCADE,
              UNIQUE(group_id, user_email)
            )
          ''');
        }
        if (oldVersion < 4) {
          await db.execute(
            'ALTER TABLE groups ADD COLUMN created_by INTEGER REFERENCES users(id)',
          );
          await db.execute(
            'ALTER TABLE group_members ADD COLUMN friend_id INTEGER REFERENCES friends(id)',
          );
        }
        if (oldVersion < 5) {
          await db.execute(
            'ALTER TABLE groups ADD COLUMN currency TEXT',
          );
          await db.execute(
            'ALTER TABLE groups ADD COLUMN start_date TEXT',
          );
          await db.execute(
            'ALTER TABLE groups ADD COLUMN end_date TEXT',
          );
        }
        if (oldVersion < 6) {
          await db.execute(
            'ALTER TABLE groups ADD COLUMN budget REAL',
          );
        }
      },
    );
  }

  static Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS friends (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_email TEXT NOT NULL,
        friend_email TEXT NOT NULL,
        UNIQUE(user_email, friend_email)
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS groups (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        created_by INTEGER,
        currency TEXT,
        start_date TEXT,
        end_date TEXT,
        budget REAL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (created_by) REFERENCES users (id)
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS group_members (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        group_id INTEGER NOT NULL,
        user_email TEXT NOT NULL,
        friend_id INTEGER,
        FOREIGN KEY (group_id) REFERENCES groups (id) ON DELETE CASCADE,
        FOREIGN KEY (friend_id) REFERENCES friends (id),
        UNIQUE(group_id, user_email)
      )
    ''');
  }

  /// Insert a user into SQLite
  static Future<int> insertUser(User user) async {
    final db = await database;
    return await db.insert('users', user.toMap());
  }

  /// Find a user by email (case-insensitive)
  static Future<User?> getUserByEmail(String email) async {
    final db = await database;
    final results = await db.query(
      'users',
      where: 'LOWER(email) = ?',
      whereArgs: [email.toLowerCase()],
      limit: 1,
    );
    if (results.isNotEmpty) {
      return User.fromMap(results.first);
    }
    return null;
  }

  /// Get all users
  static Future<List<User>> getAllUsers() async {
    final db = await database;
    final maps = await db.query('users');
    return maps.map((map) => User.fromMap(map)).toList();
  }

  /// Search users excluding the current user
  static Future<List<User>> searchUsers(
    String query,
    String excludeEmail,
  ) async {
    final db = await database;
    final maps = await db.query(
      'users',
      where:
          '(LOWER(name) LIKE ? OR LOWER(email) LIKE ?) AND LOWER(email) != ?',
      whereArgs: [
        '%${query.toLowerCase()}%',
        '%${query.toLowerCase()}%',
        excludeEmail.toLowerCase(),
      ],
    );
    return maps.map((map) => User.fromMap(map)).toList();
  }

  /// Add a friend relationship
  static Future<int> addFriend(
    String currentUserEmail,
    String friendEmail,
  ) async {
    final db = await database;
    return await db.insert('friends', {
      'user_email': currentUserEmail.toLowerCase(),
      'friend_email': friendEmail.toLowerCase(),
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  /// Get all friends for a user
  static Future<List<User>> getFriends(String currentUserEmail) async {
    final db = await database;
    final results = await db.rawQuery(
      '''
      SELECT u.* FROM users u
      INNER JOIN friends f ON LOWER(u.email) = LOWER(f.friend_email)
      WHERE LOWER(f.user_email) = ?
    ''',
      [currentUserEmail.toLowerCase()],
    );

    return results.map((map) => User.fromMap(map)).toList();
  }

  /// Create a new group and add the creator as a member
  static Future<int> createGroup(
    String name,
    String creatorEmail,
    int creatorId,
  ) async {
    final db = await database;
    return await db.transaction((txn) async {
      final groupId = await txn.insert('groups', {
        'name': name,
        'created_by': creatorId,
        'created_at': DateTime.now().toIso8601String(),
      });

      await txn.insert('group_members', {
        'group_id': groupId,
        'user_email': creatorEmail.toLowerCase(),
      });

      return groupId;
    });
  }

  /// Add a member to a group
  static Future<int> addMemberToGroup(int groupId, String email) async {
    final db = await database;
    return await db.insert('group_members', {
      'group_id': groupId,
      'user_email': email.toLowerCase(),
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  /// Remove a member from a group
  static Future<int> removeMemberFromGroup(int groupId, String email) async {
    final db = await database;
    return await db.delete(
      'group_members',
      where: 'group_id = ? AND LOWER(user_email) = ?',
      whereArgs: [groupId, email.toLowerCase()],
    );
  }

  /// Get groups for a specific user
  static Future<List<Group>> getGroupsForUser(String email) async {
    final db = await database;
    final results = await db.rawQuery(
      '''
      SELECT g.* FROM groups g
      INNER JOIN group_members gm ON g.id = gm.group_id
      WHERE LOWER(gm.user_email) = ?
    ''',
      [email.toLowerCase()],
    );

    return results.map((map) => Group.fromMap(map)).toList();
  }

  /// Search groups for a user
  static Future<List<Group>> searchGroups(String query, String email) async {
    final db = await database;
    final results = await db.rawQuery(
      '''
      SELECT g.* FROM groups g
      INNER JOIN group_members gm ON g.id = gm.group_id
      WHERE LOWER(gm.user_email) = ? AND LOWER(g.name) LIKE ?
    ''',
      [email.toLowerCase(), '%${query.toLowerCase()}%'],
    );

    return results.map((map) => Group.fromMap(map)).toList();
  }

  /// Get members of a group (returns user records)
  static Future<List<User>> getGroupMembers(int groupId) async {
    final db = await database;
    final results = await db.rawQuery(
      '''
      SELECT u.* FROM users u
      INNER JOIN group_members gm ON LOWER(u.email) = LOWER(gm.user_email)
      WHERE gm.group_id = ?
    ''',
      [groupId],
    );
    return results.map((map) => User.fromMap(map)).toList();
  }

  /// Update a group's name
  static Future<int> updateGroupName(int groupId, String newName) async {
    final db = await database;
    return await db.update(
      'groups',
      {'name': newName},
      where: 'id = ?',
      whereArgs: [groupId],
    );
  }

  /// Update a group's currency
  static Future<int> updateGroupCurrency(int groupId, String currency) async {
    final db = await database;
    return await db.update(
      'groups',
      {'currency': currency},
      where: 'id = ?',
      whereArgs: [groupId],
    );
  }

  /// Update a group's date range
  static Future<int> updateGroupDates(
    int groupId,
    DateTime? startDate,
    DateTime? endDate,
  ) async {
    final db = await database;
    return await db.update(
      'groups',
      {
        'start_date': startDate?.toIso8601String(),
        'end_date': endDate?.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [groupId],
    );
  }

  /// Update a group's budget
  static Future<int> updateGroupBudget(int groupId, double budget) async {
    final db = await database;
    return await db.update(
      'groups',
      {'budget': budget},
      where: 'id = ?',
      whereArgs: [groupId],
    );
  }

  /// Delete a group (cascade deletes group_members)
  static Future<int> deleteGroup(int groupId) async {
    final db = await database;
    return await db.delete('groups', where: 'id = ?', whereArgs: [groupId]);
  }
}
