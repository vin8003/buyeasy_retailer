import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart';
import 'providers/auth_provider.dart';
import 'providers/product_provider.dart';
import 'providers/order_provider.dart';
import 'providers/dashboard_provider.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/dashboard_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/notification_service.dart';
import 'services/api_service.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  // Initialize ApiService early to load saved base URL
  await ApiService().checkAuthToken();

  try {
    if (kIsWeb) {
      await Firebase.initializeApp(
        options: FirebaseOptions(
          apiKey: dotenv.env['API_KEY']!,
          appId: dotenv.env['APP_ID']!,
          messagingSenderId: dotenv.env['MESSAGING_SENDER_ID']!,
          projectId: dotenv.env['PROJECT_ID']!,
          storageBucket: dotenv.env['STORAGE_BUCKET']!,
          authDomain: dotenv.env['AUTH_DOMAIN']!,
        ),
      );
    } else {
      await Firebase.initializeApp();
    }
    await NotificationService().initialize();
    debugPrint('Firebase/Notifications initialized successfully');
  } catch (e) {
    debugPrint('------------------------------------------------');
    debugPrint('FIREBASE ALERT: Initialization failed.');
    debugPrint('Error: $e');
    debugPrint('------------------------------------------------');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
      ],
      child: const RetailerApp(),
    ),
  );
}

class RetailerApp extends StatelessWidget {
  const RetailerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Connect ApiService's navigatorKey for global navigation (e.g., forced logout)
      navigatorKey: ApiService().navigatorKey,
      title: 'Order Easy Retailer Dashboard',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
        textTheme: GoogleFonts.interTextTheme(),
      ),
      // Define routes for navigation from ApiService
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/dashboard': (context) => const DashboardScreen(),
      },
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (auth.isAuthenticated) {
            return const DashboardScreen();
          }
          return const LoginScreen();
        },
      ),
    );
  }
}
