import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/expense_model.dart';
import '../models/group_model.dart';
import '../models/user_model.dart';
import '../utils/split_engine.dart';

class ExportHelper {
  static Future<void> exportGroupToCsv({
    required Group group,
    required List<Expense> expenses,
    required List<ExpenseSplit> allSplits,
    required List<User> members,
  }) async {
    List<List<dynamic>> rows = [];

    // Header
    rows.add([
      'Date',
      'Description',
      'Amount',
      'Paid By',
      'Split Type',
      'Payer Email',
      'Involved Members',
    ]);

    for (var expense in expenses) {
      final dt = DateFormat('yyyy-MM-dd').format(expense.date);
      final payer = members.firstWhere(
        (m) => m.email.toLowerCase() == expense.paidByEmail.toLowerCase(),
        orElse: () => User(id: 0, name: expense.paidByEmail, email: expense.paidByEmail, createdAt: DateTime.now())
      ).name;

      final expenseSplits = allSplits.where((s) => s.expenseId == expense.id).toList();
      final involved = expenseSplits.map((s) {
        final m = members.firstWhere(
          (m) => m.email.toLowerCase() == s.userEmail.toLowerCase(),
          orElse: () => User(id: 0, name: s.userEmail, email: s.userEmail, createdAt: DateTime.now())
        );
        return '${m.name} (${formatAmount(s.amount)})';
      }).join(', ');

      rows.add([
        dt,
        expense.description,
        expense.amount,
        payer,
        expense.splitType,
        expense.paidByEmail,
        involved,
      ]);
    }

    String csvContent = const CsvEncoder().convert(rows);

    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/${group.name.replaceAll(' ', '_')}_Expenses.csv');
    
    await file.writeAsString(csvContent);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text: 'Expenses for ${group.name}',
      ),
    );
  }

  static Future<void> backupGroupToSystemFile({
    required Group group,
    required List<Expense> expenses,
    required List<ExpenseSplit> allSplits,
    required List<User> members,
    required List<User> inactiveMembers,
  }) async {
    final Map<String, dynamic> data = {
      'version': 1,
      'exported_at': DateTime.now().toIso8601String(),
      'group': group.toMap(),
      'members': members.map((m) => m.toMap()).toList(),
      'inactive_members': inactiveMembers.map((m) => m.toMap()).toList(),
      'expenses': expenses.map((e) => e.toMap()).toList(),
      'splits': allSplits.map((s) => s.toMap()).toList(),
    };

    final String jsonStr = jsonEncode(data);
    final String base64Content = base64Encode(utf8.encode(jsonStr));
    final String finalContent = 'DUTCH_BACKUP_V1:$base64Content';

    final directory = await getTemporaryDirectory();
    final fileName = '${group.name.replaceAll(' ', '_')}_Backup.dutch';
    final file = File('${directory.path}/$fileName');
    
    await file.writeAsString(finalContent);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text: 'Dutch Group Backup: ${group.name}',
      ),
    );
  }

  static Future<Map<String, dynamic>?> validateAndParseBackup(String content) async {
    if (!content.startsWith('DUTCH_BACKUP_V1:')) return null;
    
    try {
      final base64Part = content.substring('DUTCH_BACKUP_V1:'.length);
      final jsonStr = utf8.decode(base64Decode(base64Part));
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }
}
