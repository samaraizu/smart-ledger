import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../models/category.dart';
import '../models/brand.dart';
import '../services/expense_service.dart';
import '../utils/formatters.dart';

class ExpensePreviewScreen extends StatefulWidget {
  final Expense expense;
  final String? imagePath;

  const ExpensePreviewScreen({
    super.key,
    required this.expense,
    this.imagePath,
  });

  @override
  State<ExpensePreviewScreen> createState() => _ExpensePreviewScreenState();
}

class _ExpensePreviewScreenState extends State<ExpensePreviewScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _descriptionController;
  late TextEditingController _costController;
  late TextEditingController _rewardController;
  late TextEditingController _merchantController;
  late TextEditingController _memoController;
  late DateTime _selectedDate;
  String? _selectedCategoryId;
  String? _selectedBrandId;

  @override
  void initState() {
    super.initState();
    final numberFormat = NumberFormat('#,###');
    _descriptionController = TextEditingController(text: widget.expense.description);
    _costController = TextEditingController(
      text: numberFormat.format(widget.expense.cost.toInt()),
    );
    _rewardController = TextEditingController(
      text: widget.expense.reward > 0 ? numberFormat.format(widget.expense.reward.toInt()) : '',
    );
    _merchantController = TextEditingController(text: widget.expense.merchantName ?? '');
    _memoController = TextEditingController(text: widget.expense.memo ?? '');
    _selectedDate = widget.expense.date;
    _selectedCategoryId = widget.expense.categoryId;
    _selectedBrandId = widget.expense.brandId;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _costController.dispose();
    _rewardController.dispose();
    _merchantController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('ja', 'JP'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1A237E), // Header background color
              onPrimary: Colors.white, // Header text color
              onSurface: Colors.black, // Body text color
              surface: Colors.white, // Dialog background
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: Colors.white,
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

  void _saveExpense() async {
    if (_formKey.currentState!.validate()) {
      try {
        final expenseService = Provider.of<ExpenseService>(context, listen: false);

        // Remove commas and parse
        final costText = _costController.text.replaceAll(RegExp(r'[^\d]'), '');
        final rewardText = _rewardController.text.replaceAll(RegExp(r'[^\d]'), '');

        final updatedExpense = Expense(
          id: widget.expense.id,
          categoryId: _selectedCategoryId ?? widget.expense.categoryId,
          cost: double.parse(costText),
          description: _descriptionController.text,
          date: _selectedDate,
          merchantName: _merchantController.text.isNotEmpty ? _merchantController.text : null,
          imagePath: widget.expense.imagePath,
          memo: _memoController.text.isNotEmpty ? _memoController.text : null,
          reward: rewardText.isNotEmpty ? double.parse(rewardText) : 0,
          brandId: _selectedBrandId,
        );

        await expenseService.addExpense(updatedExpense);

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('経費を登録しました！'),
            backgroundColor: Color(0xFF1A237E),
          ),
        );

        Navigator.of(context).pop(true); // Return true to indicate success
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Error saving expense: $e');
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存エラー: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _cancel() {
    Navigator.of(context).pop(false); // Return false to indicate cancellation
  }

  @override
  Widget build(BuildContext context) {
    final expenseService = Provider.of<ExpenseService>(context);
    final categories = expenseService.getAllCategories();
    final brands = expenseService.getAllBrands();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '内容を確認',
          style: TextStyle(fontWeight: FontWeight.w300),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _cancel,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Receipt image preview
                if (widget.imagePath != null)
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxHeight: 300),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        widget.imagePath!,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 200,
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.image_outlined, size: 48, color: Colors.grey.shade400),
                                const SizedBox(height: 8),
                                Text(
                                  '画像を読み込めませんでした',
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                
                // Header
                const Row(
                  children: [
                    Icon(
                      Icons.preview_outlined,
                      size: 32,
                      color: Color(0xFF1A237E),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'OCR読み取り結果',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w300,
                        color: Color(0xFF1A237E),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  '内容を確認して、必要に応じて修正してください',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 32),

                // Description field
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: '説明',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.description_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '説明を入力してください';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Date field
                InkWell(
                  onTap: () => _selectDate(context),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: '支払日（Date）',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.calendar_today_outlined),
                    ),
                    child: Text(
                      '${_selectedDate.year}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.day.toString().padLeft(2, '0')}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Category dropdown
                DropdownButtonFormField<String>(
                  value: _selectedCategoryId,
                  decoration: InputDecoration(
                    labelText: 'カテゴリー（Category）',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.category_outlined),
                  ),
                  items: categories.map((category) {
                    return DropdownMenuItem(
                      value: category.id,
                      child: Row(
                        children: [
                          Icon(category.icon, size: 20, color: category.color),
                          const SizedBox(width: 8),
                          Text(category.name),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategoryId = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'カテゴリーを選択してください';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Cost field
                TextFormField(
                  controller: _costController,
                  decoration: InputDecoration(
                    labelText: '金額（Cost）',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.currency_yen),
                    suffixText: '円',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    ThousandsSeparatorInputFormatter(),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '金額を入力してください';
                    }
                    final digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');
                    if (double.tryParse(digitsOnly) == null) {
                      return '有効な金額を入力してください';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Reward field
                TextFormField(
                  controller: _rewardController,
                  decoration: InputDecoration(
                    labelText: '割り勘金額（Reward）',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.money_off_outlined),
                    suffixText: '円',
                    helperText: 'Costから差し引かれる金額',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    ThousandsSeparatorInputFormatter(),
                  ],
                ),
                const SizedBox(height: 16),

                // Actual amount display
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '実質金額',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1A237E),
                        ),
                      ),
                      Text(
                        () {
                          final costText = _costController.text.replaceAll(RegExp(r'[^\d]'), '');
                          final rewardText = _rewardController.text.replaceAll(RegExp(r'[^\d]'), '');
                          final cost = double.tryParse(costText) ?? 0;
                          final reward = double.tryParse(rewardText) ?? 0;
                          final actual = cost - reward;
                          return '¥${NumberFormat('#,###').format(actual.toInt())}';
                        }(),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A237E),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Merchant field
                TextFormField(
                  controller: _merchantController,
                  decoration: InputDecoration(
                    labelText: '店舗名（Merchant）',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.store_outlined),
                  ),
                ),
                const SizedBox(height: 16),

                // Brand dropdown
                DropdownButtonFormField<String>(
                  value: _selectedBrandId,
                  decoration: InputDecoration(
                    labelText: 'ブランド（Brand）',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.label_outlined),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('未選択'),
                    ),
                    ...brands.map((brand) {
                      return DropdownMenuItem(
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
                const SizedBox(height: 16),

                // Memo field
                TextFormField(
                  controller: _memoController,
                  decoration: InputDecoration(
                    labelText: 'メモ（Memo）',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.note_outlined),
                    helperText: '100文字以内',
                  ),
                  maxLength: 100,
                  maxLines: 3,
                ),
                const SizedBox(height: 32),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _cancel,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey,
                          side: const BorderSide(color: Colors.grey),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'キャンセル',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _saveExpense,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A237E),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          '登録',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
