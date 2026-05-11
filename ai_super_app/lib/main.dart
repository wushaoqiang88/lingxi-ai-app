import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';

import 'l10n/app_strings.dart';
import 'screens/shell_page.dart';
import 'services/api_client.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await loadSavedApiUrl();
  runApp(const LingxiApp());
}

class LingxiApp extends StatelessWidget {
  const LingxiApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF4F46E5);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Lingxi AI',
      localizationsDelegates: const [
        AppStrings.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppStrings.supportedLocales,
      theme: ThemeData(
        colorScheme: colorScheme,
        scaffoldBackgroundColor: const Color(0xFFF5F6FA),
        useMaterial3: true,
        fontFamily: '.SF Pro Text',
        appBarTheme: AppBarTheme(
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 0.5,
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1E293B),
          systemOverlayStyle: SystemUiOverlayStyle.dark,
          titleTextStyle: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shadowColor: const Color(0x1A4F46E5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: const EdgeInsets.only(bottom: 12),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: const Color(0xFFF1F5F9),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          side: BorderSide.none,
          labelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          elevation: 0,
          indicatorColor: colorScheme.primary.withValues(alpha: 0.1),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: colorScheme.primary,
              );
            }
            return const TextStyle(fontSize: 11, color: Color(0xFF94A3B8));
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return IconThemeData(color: colorScheme.primary, size: 24);
            }
            return const IconThemeData(color: Color(0xFF94A3B8), size: 24);
          }),
        ),
        dividerTheme: const DividerThemeData(
          color: Color(0xFFF1F5F9),
          thickness: 1,
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: const Color(0xFF1E293B),
        ),
      ),
      home: const ShellPage(),
    );
  }
}
