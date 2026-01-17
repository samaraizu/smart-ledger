import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/expense_service.dart';
import 'screens/home_screen.dart';
import 'models/adapters.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive
  await Hive.initFlutter();
  
  // Register custom type adapters
  if (!Hive.isAdapterRegistered(2)) {
    Hive.registerAdapter(IconDataAdapter());
  }
  if (!Hive.isAdapterRegistered(3)) {
    Hive.registerAdapter(ColorAdapter());
  }
  
  // Initialize ExpenseService
  final expenseService = ExpenseService(userId: null);
  await expenseService.init();
  
  runApp(MyApp(expenseService: expenseService));
}

class MyApp extends StatelessWidget {
  final ExpenseService expenseService;
  
  const MyApp({super.key, required this.expenseService});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: expenseService,
      child: MaterialApp(
        title: 'Smart Ledger',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1A237E), // Navy blue
            brightness: Brightness.light,
            surface: Colors.white,
            onSurface: Colors.black,
          ),
          scaffoldBackgroundColor: Colors.white,
          dialogBackgroundColor: Colors.white,
          dialogTheme: const DialogThemeData(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            elevation: 0,
            iconTheme: IconThemeData(color: Color(0xFF1A237E)),
            titleTextStyle: TextStyle(
              color: Color(0xFF1A237E),
              fontSize: 20,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
