import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Enum representing available app themes.
enum AppThemeMode {
  light,
  dark,
  abyss,
}

/// Provider for managing app theme state.
/// 
/// Supports 3 themes:
/// - Light: Clean, bright theme
/// - Dark: Standard dark theme  
/// - Abyss: Deep dark blue/purple theme (like Antigravity)
class ThemeProvider extends ChangeNotifier {
  static const String _boxName = 'settings';
  static const String _themeKey = 'theme_mode';
  
  AppThemeMode _themeMode = AppThemeMode.dark;
  Box? _box;

  AppThemeMode get themeMode => _themeMode;
  
  ThemeData get theme {
    switch (_themeMode) {
      case AppThemeMode.light:
        return _buildLightTheme();
      case AppThemeMode.dark:
        return _buildDarkTheme();
      case AppThemeMode.abyss:
        return _buildAbyssTheme();
    }
  }

  /// Initializes the theme provider and loads saved preference.
  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
    final savedTheme = _box?.get(_themeKey, defaultValue: 'dark') as String;
    _themeMode = AppThemeMode.values.firstWhere(
      (e) => e.name == savedTheme,
      orElse: () => AppThemeMode.dark,
    );
    notifyListeners();
  }

  /// Sets the theme mode and persists the preference.
  Future<void> setThemeMode(AppThemeMode mode) async {
    _themeMode = mode;
    await _box?.put(_themeKey, mode.name);
    notifyListeners();
  }

  /// Gets the display name for a theme mode.
  String getThemeName(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return 'Light';
      case AppThemeMode.dark:
        return 'Dark';
      case AppThemeMode.abyss:
        return 'Abyss';
    }
  }

  /// Gets the icon for a theme mode.
  IconData getThemeIcon(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return Icons.light_mode;
      case AppThemeMode.dark:
        return Icons.dark_mode;
      case AppThemeMode.abyss:
        return Icons.auto_awesome;
    }
  }

  /// Builds the light theme.
  ThemeData _buildLightTheme() {
    const seedColor = Color(0xFF6750A4);
    
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
    ).copyWith(
      primary: const Color(0xFF6750A4),
      secondary: const Color(0xFF625B71),
      tertiary: const Color(0xFF7D5260),
      surface: const Color(0xFFFFFBFE),
      surfaceContainerLowest: Colors.white,
      surfaceContainerHighest: const Color(0xFFE7E0EC),
    );

    return _buildTheme(colorScheme, Brightness.light);
  }

  /// Builds the standard dark theme.
  ThemeData _buildDarkTheme() {
    const seedColor = Color(0xFFD0BCFF);
    
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
    ).copyWith(
      primary: const Color(0xFFD0BCFF),
      secondary: const Color(0xFFCCC2DC),
      tertiary: const Color(0xFFEFB8C8),
      surface: const Color(0xFF1C1B1F),
      surfaceContainerLowest: const Color(0xFF141316),
      surfaceContainerHighest: const Color(0xFF363438),
    );

    return _buildTheme(colorScheme, Brightness.dark);
  }

  /// Builds the Abyss theme (deep dark blue/purple).
  ThemeData _buildAbyssTheme() {
    // Abyss color palette - deep dark blue/purple like Antigravity
    final colorScheme = ColorScheme(
      brightness: Brightness.dark,
      // Primary colors - soft blue/purple accent
      primary: const Color(0xFF7AA2F7),
      onPrimary: const Color(0xFF0D1117),
      primaryContainer: const Color(0xFF2D3B55),
      onPrimaryContainer: const Color(0xFFBBD6FF),
      // Secondary colors
      secondary: const Color(0xFF9CABCA),
      onSecondary: const Color(0xFF0D1117),
      secondaryContainer: const Color(0xFF2D3548),
      onSecondaryContainer: const Color(0xFFD4DEF4),
      // Tertiary colors - subtle purple accent
      tertiary: const Color(0xFFBB9AF7),
      onTertiary: const Color(0xFF0D1117),
      tertiaryContainer: const Color(0xFF3D2D55),
      onTertiaryContainer: const Color(0xFFE6D6FF),
      // Error colors
      error: const Color(0xFFF7768E),
      onError: const Color(0xFF0D1117),
      errorContainer: const Color(0xFF4D2D35),
      onErrorContainer: const Color(0xFFFFD6DD),
      // Surface colors - deep dark blue
      surface: const Color(0xFF0D1117),
      onSurface: const Color(0xFFC9D1D9),
      surfaceContainerLowest: const Color(0xFF010409),
      surfaceContainerLow: const Color(0xFF161B22),
      surfaceContainer: const Color(0xFF1C2128),
      surfaceContainerHigh: const Color(0xFF21262D),
      surfaceContainerHighest: const Color(0xFF30363D),
      onSurfaceVariant: const Color(0xFF8B949E),
      // Outline colors
      outline: const Color(0xFF484F58),
      outlineVariant: const Color(0xFF30363D),
      // Other
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: const Color(0xFFC9D1D9),
      onInverseSurface: const Color(0xFF0D1117),
      inversePrimary: const Color(0xFF3D5A99),
    );

    return _buildTheme(colorScheme, Brightness.dark);
  }

  /// Builds a theme with the given color scheme.
  ThemeData _buildTheme(ColorScheme colorScheme, Brightness brightness) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: 'Roboto',
      brightness: brightness,
      
      // App bar theme
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: brightness == Brightness.dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
      
      // Card theme
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      
      // Floating action button theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      
      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      
      // Snackbar theme
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      
      // Bottom sheet theme
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      
      // Dialog theme
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}
