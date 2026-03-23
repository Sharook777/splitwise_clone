import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/expense_model.dart';
import '../models/group_model.dart';
import '../models/user_model.dart';

class ExportHelper {
  static Future<void> exportGroupToCsv({
    required Group group,
    required List<Expense> expenses,
    required List<ExpenseSplit> allSplits,
    required List<User> members,
  }) async {
    List<List<dynamic>> rows = [];

    // Row 1: Group Name
    rows.add([group.name]);
    // Row 2: Empty Spacer
    rows.add([]);

    // Row 3: Main Header
    List<String> header = [
      'Date',
      'Description',
      'Amount',
      'Paid By',
      'Split Type',
      'Payer Email',
    ];
    // Add Member Names as Dynamic Columns
    for (var member in members) {
      header.add(member.name);
    }
    rows.add(header);

    // Initialize Totals
    double totalGroupAmount = 0.0;
    Map<String, double> memberTotals = {
      for (var m in members) m.email.toLowerCase(): 0.0,
    };

    for (var expense in expenses) {
      final dt = DateFormat('yyyy-MM-dd').format(expense.date);
      final payer = members
          .firstWhere(
            (m) => m.email.toLowerCase() == expense.paidByEmail.toLowerCase(),
            orElse: () => User(
              id: 0,
              name: expense.paidByEmail,
              email: expense.paidByEmail,
              createdAt: DateTime.now(),
            ),
          )
          .name;

      totalGroupAmount += expense.amount;

      // Start current row with standard data
      List<dynamic> row = [
        dt,
        expense.description,
        expense.amount,
        payer,
        expense.splitType,
        expense.paidByEmail,
      ];

      // Get individual splits for this expense
      final expenseSplits = allSplits
          .where((s) => s.expenseId == expense.id)
          .toList();

      // Add each member's share to their respective column
      for (var member in members) {
        final split = expenseSplits.firstWhere(
          (s) => s.userEmail.toLowerCase() == member.email.toLowerCase(),
          orElse: () => ExpenseSplit(
            expenseId: expense.id ?? 0,
            userEmail: member.email,
            amount: 0.0,
          ),
        );

        row.add(split.amount);
        // Accumulate Member Totals
        memberTotals[member.email.toLowerCase()] =
            (memberTotals[member.email.toLowerCase()] ?? 0.0) + split.amount;
      }

      rows.add(row);
    }

    // Row Bottom: Totals
    List<dynamic> totalsRow = ['TOTALS', '', totalGroupAmount, '', '', ''];
    for (var member in members) {
      totalsRow.add(memberTotals[member.email.toLowerCase()] ?? 0.0);
    }
    rows.add(totalsRow);

    // Add UTF-8 BOM to ensure Excel recognizes it correctly
    String csvWithBom = '\uFEFF' + const CsvEncoder().convert(rows);

    final directory = await getTemporaryDirectory();
    final String sanitizedName = group.name.replaceAll(
      RegExp(r'[^a-zA-Z0-9]'),
      '_',
    );
    final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final file = File('${directory.path}/${sanitizedName}_$timestamp.csv');

    await file.writeAsString(csvWithBom);
    debugPrint('Exported ${rows.length - 1} expenses to ${file.path}');

    await Share.shareXFiles([
      XFile(file.path),
    ], subject: 'Expenses for ${group.name}');
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
    debugPrint('Backup generated for ${group.name} at ${file.path}');

    await Share.shareXFiles([
      XFile(file.path),
    ], subject: 'Dutch Group Backup: ${group.name}');
  }

  static Future<Map<String, dynamic>?> validateAndParseBackup(
    String content,
  ) async {
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
