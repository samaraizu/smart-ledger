import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/google_vision_service.dart';
import '../services/storage_service.dart';

class ApiKeySetupScreen extends StatefulWidget {
  final GoogleVisionService visionService;

  const ApiKeySetupScreen({super.key, required this.visionService});

  @override
  State<ApiKeySetupScreen> createState() => _ApiKeySetupScreenState();
}

class _ApiKeySetupScreenState extends State<ApiKeySetupScreen> {
  final TextEditingController _apiKeyController = TextEditingController();
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadApiKey();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _loadApiKey() async {
    try {
      if (kDebugMode) {
        debugPrint('ApiKeySetupScreen: Loading API key...');
      }
      
      // Use StorageService instead of SharedPreferences
      final apiKey = await StorageService.loadApiKey();
      
      if (kDebugMode) {
        debugPrint('ApiKeySetupScreen: Storage initialized');
      }
      
      if (apiKey != null && apiKey.isNotEmpty) {
        _apiKeyController.text = apiKey;
        widget.visionService.setApiKey(apiKey);
        if (kDebugMode) {
          debugPrint('ApiKeySetupScreen: API key loaded (${apiKey.length} chars)');
        }
      } else {
        if (kDebugMode) {
          debugPrint('ApiKeySetupScreen: No API key found');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('ApiKeySetupScreen: Error loading API key: $e');
      }
      setState(() {
        _errorMessage = 'APIキーの読み込みエラー: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveApiKey() async {
    final apiKey = _apiKeyController.text.trim();
    if (apiKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('APIキーを入力してください'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await StorageService.saveApiKey(apiKey);
      widget.visionService.setApiKey(apiKey);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('APIキーを保存しました'),
          backgroundColor: Color(0xFF1A237E),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('保存エラー: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _clearApiKey() async {
    try {
      await StorageService.removeApiKey();
      widget.visionService.setApiKey('');
      _apiKeyController.clear();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('APIキーを削除しました'),
          backgroundColor: Color(0xFF1A237E),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('削除エラー: $e'),
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
          'Google Vision API設定',
          style: TextStyle(fontWeight: FontWeight.w300),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('設定を読み込み中...'),
                ],
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _errorMessage = null;
                              _isLoading = true;
                            });
                            _loadApiKey();
                          },
                          child: const Text('再試行'),
                        ),
                      ],
                    ),
                  ),
                )
              : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.vpn_key,
                      size: 64,
                      color: Color(0xFF1A237E),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Google Cloud Vision APIキー',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w300,
                        color: Color(0xFF1A237E),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'レシート画像から自動的に金額を読み取るには、Google Cloud Vision APIキーが必要です。',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // API Key input
                    TextField(
                      controller: _apiKeyController,
                      decoration: InputDecoration(
                        labelText: 'APIキー',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        hintText: 'AIzaSy...',
                        helperText: 'Google Cloud ConsoleからAPIキーを取得',
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => _apiKeyController.clear(),
                        ),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),
                    
                    // Save button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _saveApiKey,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A237E),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('保存'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Clear button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton(
                        onPressed: _clearApiKey,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('APIキーを削除'),
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Divider(),
                    const SizedBox(height: 24),
                    
                    // Instructions
                    const Text(
                      'APIキーの取得方法',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF1A237E),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildStep('1', 'Google Cloud Consoleにアクセス', 
                        'https://console.cloud.google.com'),
                    _buildStep('2', '新しいプロジェクトを作成', ''),
                    _buildStep('3', 'Cloud Vision APIを有効化', ''),
                    _buildStep('4', '認証情報からAPIキーを作成', ''),
                    _buildStep('5', 'APIキーをコピーして上記に貼り付け', ''),
                    const SizedBox(height: 24),
                    
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.blue),
                              SizedBox(width: 8),
                              Text(
                                '無料枠について',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            '月1,000リクエストまで無料で使用できます。\n個人事業主の方なら十分な枠です。',
                            style: TextStyle(fontSize: 13, color: Colors.black87),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStep(String number, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF1A237E),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
