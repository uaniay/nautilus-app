import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/connection_service.dart';
import 'services/file_service.dart';
import 'services/session_history_service.dart';
import 'screens/connect_screen.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const NautilusApp());
}

class NautilusApp extends StatelessWidget {
  const NautilusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ConnectionService()),
        ChangeNotifierProxyProvider<ConnectionService, FileService>(
          create: (_) => FileService(),
          update: (_, connection, fileService) =>
              fileService!..updateConnection(connection),
        ),
        ChangeNotifierProxyProvider<ConnectionService, SessionHistoryService>(
          create: (_) => SessionHistoryService(),
          update: (_, connection, historyService) =>
              historyService!..updateConnection(connection),
        ),
      ],
      child: MaterialApp(
        title: 'Nautilus',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: const Color(0xFF1A1A2E),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF00D4AA),
            secondary: Color(0xFF00D4AA),
            surface: Color(0xFF16213E),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF16213E),
            elevation: 0,
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFF16213E),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF333333)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF00D4AA)),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00D4AA),
              foregroundColor: const Color(0xFF1A1A2E),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        home: const AppRouter(),
      ),
    );
  }
}

class AppRouter extends StatelessWidget {
  const AppRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final connection = context.watch<ConnectionService>();
    if (connection.isConnected) {
      return const HomeScreen();
    }
    return const ConnectScreen();
  }
}
