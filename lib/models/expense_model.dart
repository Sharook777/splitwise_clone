class Expense {
  final int? id;
  final int groupId;
  final String description;
  final double amount;
  final DateTime date;
  final String paidByEmail;
  final String splitType;
  final DateTime createdAt;
  final String? paidByName; // Fetched via JOIN
  final bool isSettlement;

  Expense({
    this.id,
    required this.groupId,
    required this.description,
    required this.amount,
    required this.date,
    required this.paidByEmail,
    required this.splitType,
    required this.createdAt,
    this.paidByName,
    this.isSettlement = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'group_id': groupId,
      'description': description,
      'amount': amount,
      'date': date.toIso8601String(),
      'paid_by_email': paidByEmail,
      'split_type': splitType,
      'created_at': createdAt.toIso8601String(),
      'is_settlement': isSettlement ? 1 : 0,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'],
      groupId: map['group_id'],
      description: map['description'],
      amount: map['amount'],
      date: DateTime.parse(map['date']),
      paidByEmail: map['paid_by_email'],
      splitType: map['split_type'],
      createdAt: DateTime.parse(map['created_at']),
      paidByName: map['paid_by_name'],
      isSettlement: (map['is_settlement'] ?? 0) == 1,
    );
  }
}

class ExpenseSplit {
  final int? id;
  final int expenseId;
  final String userEmail;
  final double amount;
  final double? splitValue; // Stores percentage or shares if applicable

  ExpenseSplit({
    this.id,
    required this.expenseId,
    required this.userEmail,
    required this.amount,
    this.splitValue,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'expense_id': expenseId,
      'user_email': userEmail,
      'amount': amount,
      'split_value': splitValue,
    };
  }

  factory ExpenseSplit.fromMap(Map<String, dynamic> map) {
    return ExpenseSplit(
      id: map['id'],
      expenseId: map['expense_id'],
      userEmail: map['user_email'],
      amount: map['amount'],
      splitValue: map['split_value'],
    );
  }
}
