import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/expense_service.dart';
import '../models/expense.dart';
import '../screens/expense_edit_screen.dart';

class ExpenseList extends StatelessWidget {
  final int? limit;

  const ExpenseList({
    super.key,
    this.limit,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ExpenseService>(
      builder: (context, expenseService, child) {
        var expenses = expenseService.getAllExpenses();
        
        // Sort by date descending
        expenses.sort((a, b) => b.date.compareTo(a.date));
        
        // Apply limit if specified
        if (limit != null && expenses.length > limit!) {
          expenses = expenses.sublist(0, limit);
        }

        if (expenses.isEmpty) {
          return const SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    '経費がありません',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final expense = expenses[index];
              final category = expenseService.getCategoryById(expense.categoryId);
              
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: category?.color.withValues(alpha: 0.1) ?? Colors.grey.withValues(alpha: 0.1),
                      child: Icon(
                        category?.icon ?? Icons.help_outline,
                        color: category?.color ?? Colors.grey,
                        size: 24,
                      ),
                    ),
                    title: Text(
                      expense.description,
                      style: const TextStyle(
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (expense.merchantName != null)
                          Text(
                            expense.merchantName!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        Text(
                          DateFormat('yyyy/MM/dd').format(expense.date),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        if (expense.reward > 0)
                          Text(
                            '¥${expense.cost.toStringAsFixed(0)} - ¥${expense.reward.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                      ],
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '¥${expense.actualAmount.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF1A237E),
                          ),
                        ),
                        if (expense.reward > 0)
                          const Text(
                            '実質',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          ),
                      ],
                    ),
                    onTap: () {
                      _showExpenseDetails(context, expense, category?.name ?? 'Unknown');
                    },
                  ),
                ),
              );
            },
            childCount: expenses.length,
          ),
        );
      },
    );
  }

  void _showExpenseDetails(BuildContext context, Expense expense, String categoryName) {
    final expenseService = Provider.of<ExpenseService>(context, listen: false);
    final brand = expenseService.getBrandById(expense.brandId ?? '');
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '経費詳細',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF1A237E),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _DetailRow(label: 'Date', value: DateFormat('yyyy/MM/dd').format(expense.date)),
                    _DetailRow(label: 'Category', value: categoryName),
                    _DetailRow(label: 'Cost', value: '¥${expense.cost.toStringAsFixed(0)}'),
                    if (expense.reward > 0)
                      _DetailRow(label: 'Reward', value: '¥${expense.reward.toStringAsFixed(0)}'),
                    _DetailRow(
                      label: '実質金額',
                      value: '¥${expense.actualAmount.toStringAsFixed(0)}',
                    ),
                    if (brand != null)
                      _DetailRow(label: 'Brand', value: brand.name),
                    if (expense.merchantName != null)
                      _DetailRow(label: 'Merchant', value: expense.merchantName!),
                    if (expense.memo != null && expense.memo!.isNotEmpty)
                      _DetailRow(label: 'Memo', value: expense.memo!),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ExpenseEditScreen(expense: expense),
                                ),
                              );
                            },
                            icon: const Icon(Icons.edit),
                            label: const Text('編集'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF1A237E),
                              side: const BorderSide(color: Color(0xFF1A237E)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Provider.of<ExpenseService>(context, listen: false)
                                  .deleteExpense(expense.id);
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('経費を削除しました'),
                                  backgroundColor: Color(0xFF1A237E),
                                ),
                              );
                            },
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('削除'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.w300,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF1A237E),
            ),
          ),
        ],
      ),
    );
  }
}
