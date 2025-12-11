import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'services/storage_service.dart';
import 'services/groq_service.dart';
import 'providers/document_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/home_screen.dart';

/// NoteFlow – AI Voice Dictation
/// 
/// A voice dictation app with real-time speech-to-text,
/// local document storage, and AI-powered summarization.
void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Load environment variables
  await dotenv.load(fileName: '.env');

  // Initialize storage service
  final storageService = StorageService();
  await storageService.init();

  // Initialize Groq service
  final groqService = GroqService();
  groqService.init();

  // Initialize theme provider
  final themeProvider = ThemeProvider();
  await themeProvider.init();

  // Run the app
  runApp(NoteFlowApp(
    storageService: storageService,
    groqService: groqService,
    themeProvider: themeProvider,
  ));
}

/// Root widget of the NoteFlow application.
class NoteFlowApp extends StatelessWidget {
  final StorageService storageService;
  final GroqService groqService;
  final ThemeProvider themeProvider;

  const NoteFlowApp({
    super.key,
    required this.storageService,
    required this.groqService,
    required this.themeProvider,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => DocumentProvider(
            storageService: storageService,
            groqService: groqService,
          ),
        ),
        ChangeNotifierProvider.value(value: themeProvider),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'NoteFlow',
            debugShowCheckedModeBanner: false,
            theme: themeProvider.theme,
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}
