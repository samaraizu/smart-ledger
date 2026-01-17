import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/category.dart';
import '../models/brand.dart';
import '../services/expense_service.dart';
import '../services/google_vision_service.dart';
import 'api_key_setup_screen.dart';
import 'dart:html' as html;
import 'dart:convert';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final visionService = GoogleVisionService();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '設定',
          style: TextStyle(fontWeight: FontWeight.w300),
        ),
      ),
      body: SafeArea(
        child: ListView(
          children: [
            // API Settings Section
            ListTile(
              leading: Icon(
                visionService.isConfigured ? Icons.check_circle : Icons.vpn_key,
                color: visionService.isConfigured ? Colors.green : const Color(0xFF1A237E),
              ),
              title: const Text('Google Vision API設定'),
              subtitle: Text(
                visionService.isConfigured ? 'OCR自動読み取り: 有効' : 'レシート自動読み取りを有効化',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ApiKeySetupScreen(visionService: visionService),
                  ),
                );
              },
            ),
            const Divider(),
            
            // Data Management Section
            ListTile(
              leading: const Icon(Icons.file_download, color: Color(0xFF1A237E)),
              title: const Text('CSVエクスポート'),
              subtitle: const Text('全ての経費データをCSVファイルでダウンロード'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _exportCsv(context),
            ),
            const Divider(),
            
            // Category and Brand Management
            ListTile(
              leading: const Icon(Icons.category, color: Color(0xFF1A237E)),
              title: const Text('カテゴリー管理'),
              subtitle: const Text('カテゴリーラベルの追加・削除'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CategoryManagementScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.label, color: Color(0xFF1A237E)),
              title: const Text('ブランド管理'),
              subtitle: const Text('ブランドラベルの追加・削除'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BrandManagementScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _exportCsv(BuildContext context) {
    final expenseService = Provider.of<ExpenseService>(context, listen: false);
    final csvData = expenseService.exportToCsv();

    // Create blob and download
    final bytes = utf8.encode(csvData);
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.document.createElement('a') as html.AnchorElement
      ..href = url
      ..style.display = 'none'
      ..download = 'smart_ledger_expenses_${DateTime.now().toIso8601String().split('T')[0]}.csv';
    html.document.body?.children.add(anchor);

    anchor.click();

    html.document.body?.children.remove(anchor);
    html.Url.revokeObjectUrl(url);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('CSVファイルをダウンロードしました'),
        backgroundColor: Color(0xFF1A237E),
      ),
    );
  }
}

// Category Management Screen
class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  State<CategoryManagementScreen> createState() => _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _addCategory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新しいカテゴリー'),
        content: TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'カテゴリー名',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              if (_nameController.text.isNotEmpty) {
                final category = ExpenseCategory(
                  id: const Uuid().v4(),
                  name: _nameController.text,
                  icon: Icons.circle,
                  color: const Color(0xFF1A237E),
                );
                Provider.of<ExpenseService>(context, listen: false)
                    .addCategory(category);
                _nameController.clear();
                Navigator.pop(context);
              }
            },
            child: const Text('追加'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'カテゴリー管理',
          style: TextStyle(fontWeight: FontWeight.w300),
        ),
      ),
      body: Consumer<ExpenseService>(
        builder: (context, service, child) {
          final categories = service.getAllCategories();
          return ListView.builder(
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return ListTile(
                leading: Icon(category.icon, color: category.color),
                title: Text(category.name),
                trailing: category.isDefault
                    ? const Chip(
                        label: Text('デフォルト', style: TextStyle(fontSize: 11)),
                        backgroundColor: Colors.grey,
                        labelStyle: TextStyle(color: Colors.white),
                      )
                    : IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          service.deleteCategory(category.id);
                        },
                      ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCategory,
        child: const Icon(Icons.add),
      ),
    );
  }
}

// Brand Management Screen
class BrandManagementScreen extends StatefulWidget {
  const BrandManagementScreen({super.key});

  @override
  State<BrandManagementScreen> createState() => _BrandManagementScreenState();
}

class _BrandManagementScreenState extends State<BrandManagementScreen> {
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _addBrand() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新しいブランド'),
        content: TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'ブランド名',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              if (_nameController.text.isNotEmpty) {
                final service = Provider.of<ExpenseService>(context, listen: false);
                final brands = service.getAllBrands();
                final brand = Brand(
                  id: const Uuid().v4(),
                  name: _nameController.text,
                  order: brands.length,
                );
                service.addBrand(brand);
                _nameController.clear();
                Navigator.pop(context);
              }
            },
            child: const Text('追加'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ブランド管理',
          style: TextStyle(fontWeight: FontWeight.w300),
        ),
      ),
      body: Consumer<ExpenseService>(
        builder: (context, service, child) {
          final brands = service.getAllBrands();
          
          if (brands.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.label_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'ブランドがありません',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }
          
          return ListView.builder(
            itemCount: brands.length,
            itemBuilder: (context, index) {
              final brand = brands[index];
              return ListTile(
                leading: const Icon(Icons.label, color: Color(0xFF1A237E)),
                title: Text(brand.name),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    service.deleteBrand(brand.id);
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addBrand,
        child: const Icon(Icons.add),
      ),
    );
  }
}
