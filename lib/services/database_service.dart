import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user_model.dart';

import '../models/group_model.dart';
import '../models/expense_model.dart';

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
      version: 9,
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
          await db.execute('ALTER TABLE groups ADD COLUMN currency TEXT');
          await db.execute('ALTER TABLE groups ADD COLUMN start_date TEXT');
          await db.execute('ALTER TABLE groups ADD COLUMN end_date TEXT');
        }
        if (oldVersion < 6) {
          await db.execute('ALTER TABLE groups ADD COLUMN budget REAL');
        }
        if (oldVersion < 9) {
          await db.execute(
            'ALTER TABLE group_members ADD COLUMN is_active INTEGER DEFAULT 1',
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
        is_active INTEGER DEFAULT 1,
        FOREIGN KEY (group_id) REFERENCES groups (id) ON DELETE CASCADE,
        FOREIGN KEY (friend_id) REFERENCES friends (id),
        UNIQUE(group_id, user_email)
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        group_id INTEGER NOT NULL,
        description TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        paid_by_email TEXT NOT NULL,
        split_type TEXT NOT NULL,
        created_at TEXT NOT NULL,
        is_settlement INTEGER DEFAULT 0,
        FOREIGN KEY (group_id) REFERENCES groups (id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS expense_splits (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        expense_id INTEGER NOT NULL,
        user_email TEXT NOT NULL,
        amount REAL NOT NULL,
        split_value REAL,
        FOREIGN KEY (expense_id) REFERENCES expenses (id) ON DELETE CASCADE
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

  /// Add a member to a group (handles restoration of inactive members)
  static Future<int> addMemberToGroup(int groupId, String email) async {
    final db = await database;

    // Check if the member already exists (including inactive ones)
    final existing = await db.query(
      'group_members',
      where: 'group_id = ? AND LOWER(user_email) = ?',
      whereArgs: [groupId, email.toLowerCase()],
    );

    if (existing.isNotEmpty) {
      // If they exist but are inactive, reactivate them
      return await db.update(
        'group_members',
        {'is_active': 1},
        where: 'group_id = ? AND LOWER(user_email) = ?',
        whereArgs: [groupId, email.toLowerCase()],
      );
    }

    // Otherwise, insert as new
    return await db.insert('group_members', {
      'group_id': groupId,
      'user_email': email.toLowerCase(),
      'is_active': 1,
    });
  }

  /// Remove a member from a group
  static Future<int> removeMemberFromGroup(int groupId, String email) async {
    final db = await database;
    return await db.update(
      'group_members',
      {'is_active': 0},
      where: 'group_id = ? AND LOWER(user_email) = ?',
      whereArgs: [groupId, email.toLowerCase()],
    );
  }

  static Future<int> restoreMemberToGroup(int groupId, String email) async {
    final db = await database;
    return await db.update(
      'group_members',
      {'is_active': 1},
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
  static Future<List<User>> getGroupMembers(int groupId, {bool includeInactive = false}) async {
    final db = await database;
    final String whereClause = includeInactive 
        ? 'gm.group_id = ?' 
        : 'gm.group_id = ? AND gm.is_active = 1';

    final results = await db.rawQuery(
      '''
      SELECT u.* FROM users u
      INNER JOIN group_members gm ON LOWER(u.email) = LOWER(gm.user_email)
      WHERE $whereClause
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

  /// Get a single group by ID
  static Future<Group?> getGroupById(int groupId) async {
    final db = await database;
    final results = await db.query(
      'groups',
      where: 'id = ?',
      whereArgs: [groupId],
      limit: 1,
    );
    if (results.isNotEmpty) {
      return Group.fromMap(results.first);
    }
    return null;
  }

  /// Insert an expense and its splits within a transaction
  static Future<int> insertExpense(
    Expense expense,
    List<ExpenseSplit> splits,
  ) async {
    final db = await database;
    return await db.transaction((txn) async {
      final expenseId = await txn.insert('expenses', expense.toMap());

      for (var split in splits) {
        var splitMap = split.toMap();
        splitMap['expense_id'] = expenseId; // set foreign key
        await txn.insert('expense_splits', splitMap);
      }

      return expenseId;
    });
  }

  /// Get expenses for a specific group, ordered by date descending
  static Future<List<Expense>> getGroupExpenses(int groupId) async {
    final db = await database;
    final results = await db.rawQuery(
      '''
      SELECT e.*, u.name as paid_by_name 
      FROM expenses e
      INNER JOIN users u ON LOWER(e.paid_by_email) = LOWER(u.email)
      WHERE e.group_id = ?
      ORDER BY e.created_at DESC
      ''',
      [groupId],
    );
    return results.map((map) => Expense.fromMap(map)).toList();
  }

  /// Delete an expense (cascade deletes expense_splits)
  static Future<int> deleteExpense(int expenseId) async {
    final db = await database;
    return await db.delete('expenses', where: 'id = ?', whereArgs: [expenseId]);
  }

  /// Get splits for a specific expense
  static Future<List<ExpenseSplit>> getExpenseSplits(int expenseId) async {
    final db = await database;
    final results = await db.query(
      'expense_splits',
      where: 'expense_id = ?',
      whereArgs: [expenseId],
    );
    return results.map((map) => ExpenseSplit.fromMap(map)).toList();
  }

  /// Update an expense and its splits within a transaction
  static Future<void> updateExpense(
    Expense expense,
    List<ExpenseSplit> splits,
  ) async {
    final db = await database;
    await db.transaction((txn) async {
      // Update main expense record
      await txn.update(
        'expenses',
        expense.toMap(),
        where: 'id = ?',
        whereArgs: [expense.id],
      );

      // Delete old splits
      await txn.delete(
        'expense_splits',
        where: 'expense_id = ?',
        whereArgs: [expense.id],
      );

      // Insert new splits
      for (var split in splits) {
        var splitMap = split.toMap();
        splitMap['id'] = null; // Ensure new ID is generated
        splitMap['expense_id'] = expense.id;
        await txn.insert('expense_splits', splitMap);
      }
    });
  }

  /// Get all splits for all expenses in a group
  static Future<List<ExpenseSplit>> getAllExpenseSplitsForGroup(
    int groupId,
  ) async {
    final db = await database;
    final results = await db.rawQuery(
      '''
      SELECT es.* FROM expense_splits es
      INNER JOIN expenses e ON es.expense_id = e.id
      WHERE e.group_id = ?
      ''',
      [groupId],
    );
    return results.map((map) => ExpenseSplit.fromMap(map)).toList();
  }

  /// Import a full group from backup data
  static Future<int> importGroupData(Map<String, dynamic> data) async {
    final db = await database;
    return await db.transaction((txn) async {
      // 1. Insert Group
      final groupData = Map<String, dynamic>.from(data['group']);
      groupData.remove('id'); // Ensure new ID
      final groupId = await txn.insert('groups', groupData);

      // 2. Insert Members (Users first)
      final List<dynamic> activeMembers = data['members'] ?? [];
      final List<dynamic> inactiveMembers = data['inactive_members'] ?? [];
      final allBackupMembers = [...activeMembers, ...inactiveMembers];

      for (var mData in allBackupMembers) {
        final email = mData['email'].toString().toLowerCase();
        // Check if user exists
        final existing = await txn.query('users', where: 'LOWER(email) = ?', whereArgs: [email], limit: 1);
        if (existing.isEmpty) {
          final userData = {
            'name': mData['name'],
            'email': email,
            'created_at': mData['created_at'] ?? DateTime.now().toIso8601String(),
          };
          await txn.insert('users', userData);
        }

        // Add to group_members
        final isActive = activeMembers.any((m) => m['email'].toString().toLowerCase() == email) ? 1 : 0;
        await txn.insert('group_members', {
          'group_id': groupId,
          'user_email': email,
          'is_active': isActive,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }

      // 3. Insert Expenses & Splits
      final List<dynamic> expensesData = data['expenses'] ?? [];
      final List<dynamic> splitsData = data['splits'] ?? [];

      for (var eData in expensesData) {
        final oldExpenseId = eData['id'];
        final Map<String, dynamic> expMap = Map<String, dynamic>.from(eData);
        expMap.remove('id');
        expMap['group_id'] = groupId;
        
        final newExpenseId = await txn.insert('expenses', expMap);

        // Filter and insert splits for this expense
        final relatedSplits = splitsData.where((s) => s['expense_id'] == oldExpenseId);
        for (var sData in relatedSplits) {
          final Map<String, dynamic> splitMap = Map<String, dynamic>.from(sData);
          splitMap.remove('id');
          splitMap['expense_id'] = newExpenseId;
          await txn.insert('expense_splits', splitMap);
        }
      }

      return groupId;
    });
  }
}
