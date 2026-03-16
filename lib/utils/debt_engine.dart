import '../models/expense_model.dart';

/// Represents a simplified payment transaction
class DebtTransaction {
  final String fromEmail;
  final String toEmail;
  final double amount;

  DebtTransaction({
    required this.fromEmail,
    required this.toEmail,
    required this.amount,
  });
}

/// Represents a member's spending summary
class MemberBalance {
  final String email;
  final double totalPaid;
  final double totalOwed;
  double get balance => totalPaid - totalOwed;

  MemberBalance({
    required this.email,
    this.totalPaid = 0.0,
    this.totalOwed = 0.0,
  });
}

/// Compute each member's total paid and total owed from all expenses
Map<String, MemberBalance> computeMemberBalances(List<Expense> expenses, List<ExpenseSplit> allSplits) {
  final Map<String, MemberBalance> balances = {};

  // Accumulate total paid per member
  for (var expense in expenses) {
    final email = expense.paidByEmail.toLowerCase();
    final existing = balances[email];
    balances[email] = MemberBalance(
      email: email,
      totalPaid: (existing?.totalPaid ?? 0.0) + expense.amount,
      totalOwed: existing?.totalOwed ?? 0.0,
    );
  }

  // Accumulate total owed per member (from splits)
  for (var split in allSplits) {
    final email = split.userEmail.toLowerCase();
    final existing = balances[email];
    balances[email] = MemberBalance(
      email: email,
      totalPaid: existing?.totalPaid ?? 0.0,
      totalOwed: (existing?.totalOwed ?? 0.0) + split.amount,
    );
  }

  return balances;
}

/// Simplify debts into minimal transactions using the greedy algorithm
List<DebtTransaction> simplifyDebts(Map<String, MemberBalance> balances) {
  // Calculate net balance for each person
  List<MapEntry<String, double>> nets = [];
  for (var entry in balances.entries) {
    double net = entry.value.balance; // positive = is owed, negative = owes
    if (net.abs() > 0.01) {
      nets.add(MapEntry(entry.key, net));
    }
  }

  List<DebtTransaction> transactions = [];

  // Greedy: match max creditor with max debtor
  while (nets.isNotEmpty) {
    nets.sort((a, b) => a.value.compareTo(b.value));

    final debtor = nets.first; // most negative
    final creditor = nets.last; // most positive

    if (debtor.value.abs() < 0.01 || creditor.value.abs() < 0.01) break;
    if (nets.length < 2) break;

    final amount = debtor.value.abs() < creditor.value.abs()
        ? debtor.value.abs()
        : creditor.value.abs();

    transactions.add(DebtTransaction(
      fromEmail: debtor.key,
      toEmail: creditor.key,
      amount: double.parse(amount.toStringAsFixed(2)),
    ));

    // Adjust balances
    nets.removeWhere((e) => e.key == debtor.key || e.key == creditor.key);

    double newDebtorBalance = debtor.value + amount;
    double newCreditorBalance = creditor.value - amount;

    if (newDebtorBalance.abs() > 0.01) {
      nets.add(MapEntry(debtor.key, newDebtorBalance));
    }
    if (newCreditorBalance.abs() > 0.01) {
      nets.add(MapEntry(creditor.key, newCreditorBalance));
    }
  }

  return transactions;
}
