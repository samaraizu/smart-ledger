import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/expense_service.dart';
import '../widgets/expense_list.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DateTime _selectedMonth = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Reports',
          style: TextStyle(fontWeight: FontWeight.w300),
        ),
      ),
      body: SafeArea(
        child: Consumer<ExpenseService>(
          builder: (context, expenseService, child) {
            final startOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
            final endOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0, 23, 59, 59);
            final monthExpenses = expenseService.getExpensesByDateRange(
              startOfMonth.subtract(const Duration(seconds: 1)),
              endOfMonth.add(const Duration(seconds: 1)),
            );
            final monthTotal = monthExpenses.fold<double>(
              0, 
              (sum, expense) => sum + expense.actualAmount,
            );

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Month selector
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chevron_left),
                              onPressed: () {
                                setState(() {
                                  _selectedMonth = DateTime(
                                    _selectedMonth.year,
                                    _selectedMonth.month - 1,
                                  );
                                });
                              },
                              color: const Color(0xFF1A237E),
                            ),
                            Text(
                              DateFormat('MMMM yyyy').format(_selectedMonth),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFF1A237E),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.chevron_right),
                              onPressed: () {
                                setState(() {
                                  _selectedMonth = DateTime(
                                    _selectedMonth.year,
                                    _selectedMonth.month + 1,
                                  );
                                });
                              },
                              color: const Color(0xFF1A237E),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        
                        // Monthly summary
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              children: [
                                const Text(
                                  '月間合計',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w300,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '¥${monthTotal.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.w300,
                                    color: Color(0xFF1A237E),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${monthExpenses.length}件の取引',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Category breakdown
                        const Text(
                          'カテゴリー別内訳',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF1A237E),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        ...monthExpenses.fold<Map<String, double>>({}, (map, expense) {
                          map[expense.categoryId] = (map[expense.categoryId] ?? 0) + expense.actualAmount;
                          return map;
                        }).entries.map((entry) {
                          final category = expenseService.getCategoryById(entry.key);
                          final percentage = monthTotal > 0 ? (entry.value / monthTotal * 100) : 0;
                          
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  children: [
                                    Icon(
                                      category?.icon ?? Icons.help_outline,
                                      color: category?.color ?? Colors.grey,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            category?.name ?? 'Unknown',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${percentage.toStringAsFixed(1)}% of total',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '\$${entry.value.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400,
                                        color: Color(0xFF1A237E),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                        
                        const SizedBox(height: 24),
                        const Text(
                          '全ての取引',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF1A237E),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                
                // All expenses list
                const ExpenseList(),
              ],
            );
          },
        ),
      ),
    );
  }
}
