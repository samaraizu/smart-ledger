import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../services/expense_service.dart';
import '../services/receipt_processing_service.dart';
import '../services/google_vision_service.dart';
import 'manual_input_screen.dart';
import 'api_key_setup_screen.dart';
import 'expense_preview_screen.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final ImagePicker _picker = ImagePicker();
  final GoogleVisionService _visionService = GoogleVisionService();
  late final ReceiptProcessingService _processingService;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _processingService = ReceiptProcessingService(_visionService);
    _initializeVisionService();
  }

  Future<void> _initializeVisionService() async {
    await _visionService.initialize();
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _pickImage(ImageSource source, {bool isCreditCard = false}) async {
    try {
      // Re-initialize vision service before processing to ensure API key is loaded
      await _visionService.initialize();
      
      if (kDebugMode) {
        debugPrint('UploadScreen: API configured before picking image: ${_visionService.isConfigured}');
      }
      
      final XFile? image = await _picker.pickImage(source: source);
      
      if (image != null) {
        setState(() {
          _isProcessing = true;
        });

        if (!mounted) return;

        if (isCreditCard) {
          final expenses = await _processingService.processCreditCardStatement(image.path);
          
          if (!mounted) return;
          
          final expenseService = Provider.of<ExpenseService>(context, listen: false);
          for (var expense in expenses) {
            await expenseService.addExpense(expense);
          }

          if (!mounted) return;
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${expenses.length}件の経費を抽出しました！'),
              backgroundColor: const Color(0xFF1A237E),
            ),
          );
        } else {
          final expense = await _processingService.processReceipt(image.path);
          
          if (!mounted) return;
          
          setState(() {
            _isProcessing = false;
          });
          
          // Navigate to preview screen
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (context) => ExpensePreviewScreen(
                expense: expense,
                imagePath: image.path,
              ),
            ),
          );
          
          if (!mounted) return;
          
          // Show success message if expense was saved
          if (result == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('レシートを登録しました！'),
                backgroundColor: Color(0xFF1A237E),
              ),
            );
          }
        }

        if (isCreditCard) {
          setState(() {
            _isProcessing = false;
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isProcessing = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('画像の処理中にエラーが発生しました: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '経費追加',
          style: TextStyle(fontWeight: FontWeight.w300),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _visionService.isConfigured ? Icons.check_circle : Icons.settings,
              color: _visionService.isConfigured ? Colors.green : const Color(0xFF1A237E),
            ),
            onPressed: () async {
              if (kDebugMode) {
                debugPrint('Opening API Key Setup Screen...');
              }
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ApiKeySetupScreen(visionService: _visionService),
                ),
              );
              if (mounted) {
                setState(() {});
              }
            },
            tooltip: _visionService.isConfigured ? 'OCR有効' : 'API設定',
          ),
        ],
      ),
      body: SafeArea(
        child: _isProcessing
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: Color(0xFF1A237E),
                    ),
                    SizedBox(height: 24),
                    Text(
                      'レシートを処理中...',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF1A237E),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '経費情報を抽出しています',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.receipt_long_outlined,
                      size: 80,
                      color: Color(0xFF1A237E),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      '経費を追加',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w300,
                        color: Color(0xFF1A237E),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _visionService.isConfigured
                          ? 'レシートを撮影するか、手動で入力してください\n（OCR自動読み取り: 有効✓）'
                          : 'レシートを撮影するか、手動で入力してください\n（OCR: 未設定 - 右上の設定から有効化）',
                      style: TextStyle(
                        fontSize: 14,
                        color: _visionService.isConfigured ? Colors.green : Colors.orange,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),
                    
                    _UploadButton(
                      icon: Icons.edit_outlined,
                      label: '手動入力',
                      color: const Color(0xFF1A237E),
                      isFilled: true,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ManualInputScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    const Divider(),
                    const SizedBox(height: 16),
                    
                    Text(
                      _visionService.isConfigured
                          ? 'または、レシートを撮影（自動読み取り）'
                          : 'または、レシートを撮影（シミュレーション）',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    _UploadButton(
                      icon: Icons.camera_alt_outlined,
                      label: 'カメラで撮影',
                      onPressed: () => _pickImage(ImageSource.camera),
                    ),
                    const SizedBox(height: 16),
                    _UploadButton(
                      icon: Icons.photo_library_outlined,
                      label: 'ギャラリーから選択',
                      onPressed: () => _pickImage(ImageSource.gallery),
                    ),
                    
                    const SizedBox(height: 32),
                    const Divider(),
                    const SizedBox(height: 32),
                    
                    const Text(
                      'クレジットカード明細',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF1A237E),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _UploadButton(
                      icon: Icons.credit_card_outlined,
                      label: '明細書をアップロード',
                      onPressed: () => _pickImage(ImageSource.gallery, isCreditCard: true),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _UploadButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color? color;
  final bool isFilled;

  const _UploadButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color,
    this.isFilled = false,
  });

  @override
  Widget build(BuildContext context) {
    final buttonColor = color ?? const Color(0xFF1A237E);
    
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: isFilled
          ? ElevatedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon),
              label: Text(label),
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            )
          : OutlinedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon),
              label: Text(label),
              style: OutlinedButton.styleFrom(
                foregroundColor: buttonColor,
                side: BorderSide(color: buttonColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
    );
  }
}
