import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../models/category.dart';
import '../models/brand.dart';
import '../services/expense_service.dart';

class ExpenseEditScreen extends StatefulWidget {
  final Expense expense;

  const ExpenseEditScreen({super.key, required this.expense});

  @override
  State<ExpenseEditScreen> createState() => _ExpenseEditScreenState();
}

class _ExpenseEditScreenState extends State<ExpenseEditScreen> {
  late TextEditingController _costController;
  late TextEditingController _rewardController;
  late TextEditingController _memoController;
  late DateTime _selectedDate;
  late String _selectedCategoryId;
  String? _selectedBrandId;

  @override
  void initState() {
    super.initState();
    _costController = TextEditingController(text: widget.expense.cost.toStringAsFixed(0));
    _rewardController = TextEditingController(text: widget.expense.reward.toStringAsFixed(0));
    _memoController = TextEditingController(text: widget.expense.memo ?? '');
    _selectedDate = widget.expense.date;
    _selectedCategoryId = widget.expense.categoryId;
    _selectedBrandId = widget.expense.brandId;
  }

  @override
  void dispose() {
    _costController.dispose();
    _rewardController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1A237E),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF1A237E),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveExpense() async {
    // Validate memo length
    if (_memoController.text.length > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('メモは100文字以内で入力してください'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final updatedExpense = Expense(
      id: widget.expense.id,
      categoryId: _selectedCategoryId,
      cost: double.tryParse(_costController.text) ?? 0,
      description: widget.expense.description,
      date: _selectedDate,
      merchantName: widget.expense.merchantName,
      imagePath: widget.expense.imagePath,
      memo: _memoController.text.isEmpty ? null : _memoController.text,
      reward: double.tryParse(_rewardController.text) ?? 0,
      brandId: _selectedBrandId,
    );

    await Provider.of<ExpenseService>(context, listen: false).updateExpense(updatedExpense);

    if (!mounted) return;

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('経費を更新しました'),
        backgroundColor: Color(0xFF1A237E),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final expenseService = Provider.of<ExpenseService>(context);
    final categories = expenseService.getAllCategories();
    final brands = expenseService.getAllBrands();

    final cost = double.tryParse(_costController.text) ?? 0;
    final reward = double.tryParse(_rewardController.text) ?? 0;
    final actualAmount = cost - reward;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '経費編集',
          style: TextStyle(fontWeight: FontWeight.w300),
        ),
        actions: [
          TextButton(
            onPressed: _saveExpense,
            child: const Text(
              '保存',
              style: TextStyle(
                color: Color(0xFF1A237E),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date
              const Text(
                'Date (支払日)',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontWeight: FontWeight.w300,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _selectDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('yyyy/MM/dd').format(_selectedDate),
                        style: const TextStyle(fontSize: 16),
                      ),
                      const Icon(Icons.calendar_today, color: Color(0xFF1A237E)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Category
              const Text(
                'Category',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontWeight: FontWeight.w300,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedCategoryId,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                items: categories.map((category) {
                  return DropdownMenuItem(
                    value: category.id,
                    child: Row(
                      children: [
                        Icon(category.icon, color: category.color, size: 20),
                        const SizedBox(width: 12),
                        Text(category.name),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategoryId = value!;
                  });
                },
              ),
              const SizedBox(height: 24),

              // Cost
              const Text(
                'Cost (日本円)',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontWeight: FontWeight.w300,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _costController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  prefixText: '¥',
                  hintText: '0',
                ),
                onChanged: (value) {
                  setState(() {});
                },
              ),
              const SizedBox(height: 24),

              // Reward
              const Text(
                'Reward (割り勘で得た金額)',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontWeight: FontWeight.w300,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _rewardController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  prefixText: '¥',
                  hintText: '0',
                ),
                onChanged: (value) {
                  setState(() {});
                },
              ),
              const SizedBox(height: 12),
              
              // Actual Amount Display
              if (reward > 0)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A237E).withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '実質金額 (Cost - Reward)',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF1A237E),
                        ),
                      ),
                      Text(
                        '¥${actualAmount.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1A237E),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),

              // Brand
              const Text(
                'Brand',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontWeight: FontWeight.w300,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String?>(
                value: _selectedBrandId,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                hint: const Text('ブランドを選択（任意）'),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('なし'),
                  ),
                  ...brands.map((brand) {
                    return DropdownMenuItem<String?>(
                      value: brand.id,
                      child: Text(brand.name),
                    );
                  }),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedBrandId = value;
                  });
                },
              ),
              const SizedBox(height: 24),

              // Memo
              const Text(
                'Memo (100文字以内)',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontWeight: FontWeight.w300,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _memoController,
                maxLength: 100,
                maxLines: 3,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                  hintText: 'メモを入力（任意）',
                ),
              ),
              const SizedBox(height: 24),

              // Save button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _saveExpense,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A237E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    '保存',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
