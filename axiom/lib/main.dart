
import 'package:axiom/screens/APIManagementScreen.dart';
import 'package:axiom/screens/SpleshScreen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/editor/editor_screen.dart';
import 'screens/preview/preview_screen_list.dart';
import 'services/auth_service.dart';
import 'services/project_service.dart';
import 'services/websocket_service.dart';
import 'providers/project_provider.dart';
import 'providers/widget_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProjectProvider()),
        ChangeNotifierProvider(create: (_) => WidgetProvider()),
        Provider(create: (_) => AuthService()),
        Provider(create: (_) => ProjectService()),
        Provider(create: (_) => WebSocketService()),
      ],
      child: MaterialApp(
        title: 'Axiom - No-Code Platform',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
          fontFamily: 'Roboto',
        ),
        initialRoute: '/splash',
        routes: {
          '/splash': (context) => const SplashScreen(),
          '/login': (context) => const LoginScreen(),
          '/dashboard': (context) => const DashboardScreen(),
          '/editor': (context) => const EditorScreen(),
          '/api-management': (context) => const APIManagementScreen(),
          '/preview': (context) => const PreviewScreenList(),
        },
      ),
    );
  }
}