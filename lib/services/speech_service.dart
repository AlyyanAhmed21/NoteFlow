import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_recognition_error.dart';

/// Service for handling speech-to-text functionality.
/// 
/// Provides real-time speech recognition with:
/// - Continuous listening until manually stopped
/// - Auto-restart on unexpected stops
/// - Live transcription updates
class SpeechService {
  final SpeechToText _speech = SpeechToText();
  bool _isInitialized = false;
  bool _isListening = false;
  bool _shouldBeListening = false;
  
  // Callbacks for speech events
  Function(String)? onResult;
  Function(String)? onPartialResult;
  Function(String)? onError;
  Function()? onListeningStarted;
  Function()? onListeningStopped;

  /// Whether speech recognition is available on this device.
  bool get isAvailable => _isInitialized;

  /// Whether the service is currently listening.
  bool get isListening => _isListening;

  /// Initializes the speech recognition service.
  /// 
  /// Returns true if initialization was successful.
  Future<bool> initialize() async {
    try {
      _isInitialized = await _speech.initialize(
        onError: _handleError,
        onStatus: _handleStatus,
        debugLogging: false,
      );
      return _isInitialized;
    } catch (e) {
      onError?.call('Failed to initialize speech recognition: $e');
      return false;
    }
  }

  /// Starts listening for speech.
  /// 
  /// The service will continue listening until [stopListening] is called.
  /// If listening stops unexpectedly, it will automatically restart.
  Future<void> startListening() async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) {
        onError?.call('Speech recognition not available');
        return;
      }
    }

    _shouldBeListening = true;
    await _startListeningInternal();
  }

  /// Internal method to start listening.
  Future<void> _startListeningInternal() async {
    if (_isListening || !_shouldBeListening) return;

    try {
      _isListening = true;
      onListeningStarted?.call();

      await _speech.listen(
        onResult: _handleResult,
        listenFor: const Duration(seconds: 60), // Max listen duration
        pauseFor: const Duration(seconds: 30), // Keep listening during silence
        listenOptions: SpeechListenOptions(
          partialResults: true,
          cancelOnError: false,
          listenMode: ListenMode.dictation,
        ),
      );
    } catch (e) {
      _isListening = false;
      onError?.call('Error starting speech recognition: $e');
    }
  }

  /// Handles speech recognition results.
  void _handleResult(SpeechRecognitionResult result) {
    if (result.finalResult) {
      onResult?.call(result.recognizedWords);
      
      // Auto-restart listening if we should still be listening
      if (_shouldBeListening) {
        Future.delayed(const Duration(milliseconds: 100), () {
          _isListening = false;
          _startListeningInternal();
        });
      }
    } else {
      onPartialResult?.call(result.recognizedWords);
    }
  }

  /// Handles speech recognition errors.
  void _handleError(SpeechRecognitionError error) {
    // Don't report "no match" as an error - it's normal during silence
    if (error.errorMsg != 'error_no_match') {
      onError?.call('Speech recognition error: ${error.errorMsg}');
    }

    // Auto-restart if we should be listening
    if (_shouldBeListening && !error.permanent) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _isListening = false;
        _startListeningInternal();
      });
    }
  }

  /// Handles status changes from the speech recognizer.
  void _handleStatus(String status) {
    if (status == 'done' || status == 'notListening') {
      _isListening = false;
      
      // Auto-restart if we should still be listening
      if (_shouldBeListening) {
        Future.delayed(const Duration(milliseconds: 100), () {
          _startListeningInternal();
        });
      } else {
        onListeningStopped?.call();
      }
    }
  }

  /// Stops listening for speech.
  Future<void> stopListening() async {
    _shouldBeListening = false;
    _isListening = false;
    
    try {
      await _speech.stop();
    } catch (e) {
      // Ignore errors when stopping
    }
    
    onListeningStopped?.call();
  }

  /// Cancels the current listening session without triggering final results.
  Future<void> cancelListening() async {
    _shouldBeListening = false;
    _isListening = false;
    
    try {
      await _speech.cancel();
    } catch (e) {
      // Ignore errors when canceling
    }
    
    onListeningStopped?.call();
  }

  /// Gets the list of available locales for speech recognition.
  Future<List<LocaleName>> getLocales() async {
    if (!_isInitialized) {
      await initialize();
    }
    return await _speech.locales();
  }

  /// Disposes of resources used by the service.
  void dispose() {
    _shouldBeListening = false;
    _speech.stop();
  }
}
