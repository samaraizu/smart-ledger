import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/expense_service.dart';
import '../widgets/dashboard_chart.dart';
import '../widgets/expense_list.dart';
import '../widgets/summary_card.dart';
import 'upload_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _selectedIndex == 0
            ? const DashboardTab()
            : _selectedIndex == 1
                ? const UploadScreen()
                : _selectedIndex == 2
                    ? const ReportsScreen()
                    : const SettingsScreen(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const UploadScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFF1A237E).withValues(alpha: 0.1),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.upload_outlined),
            selectedIcon: Icon(Icons.upload),
            label: 'Upload',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Reports',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ExpenseService>(
      builder: (context, expenseService, child) {
        final totalExpenses = expenseService.getTotalExpenses();
        final expenseCount = expenseService.getAllExpenses().length;
        final categoryTotals = expenseService.getCategoryTotals();

        return CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              title: const Text(
                'Smart Ledger',
                style: TextStyle(
                  fontWeight: FontWeight.w300,
                  fontSize: 28,
                ),
              ),
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF1A237E),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary cards
                    Row(
                      children: [
                        Expanded(
                          child: SummaryCard(
                            title: '総支出',
                            value: '¥${totalExpenses.toStringAsFixed(0)}',
                            icon: Icons.attach_money,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: SummaryCard(
                            title: '取引件数',
                            value: expenseCount.toString(),
                            icon: Icons.receipt_long,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Chart section
                    const Text(
                      'カテゴリー別支出',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF1A237E),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    if (categoryTotals.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Column(
                            children: [
                              Icon(
                                Icons.receipt_long_outlined,
                                size: 64,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                '経費がまだありません',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'レシートをアップロードして開始',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      DashboardChart(categoryTotals: categoryTotals),
                    
                    const SizedBox(height: 24),
                    
                    // Recent expenses
                    const Text(
                      '最近の経費',
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
            
            // Expense list
            const ExpenseList(limit: 10),
          ],
        );
      },
    );
  }
}
