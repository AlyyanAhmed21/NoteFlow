import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../providers/document_provider.dart';
import '../services/speech_service.dart';

/// Screen for live voice dictation with real-time transcription.
/// 
/// Features:
/// - Large animated mic button
/// - Timer display
/// - Live transcription area with auto-scroll
/// - Auto-save on stop
class DictationScreen extends StatefulWidget {
  const DictationScreen({super.key});

  @override
  State<DictationScreen> createState() => _DictationScreenState();
}

class _DictationScreenState extends State<DictationScreen>
    with SingleTickerProviderStateMixin {
  final SpeechService _speechService = SpeechService();
  final ScrollController _scrollController = ScrollController();
  
  String _transcript = '';
  String _partialText = '';
  bool _isListening = false;
  bool _hasStarted = false;
  bool _isSaving = false;
  Timer? _timer;
  int _seconds = 0;
  
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimation();
    _initSpeechService();
  }

  void _initAnimation() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _animationController.reverse();
      } else if (status == AnimationStatus.dismissed && _isListening) {
        _animationController.forward();
      }
    });
  }

  Future<void> _initSpeechService() async {
    _speechService.onResult = (text) {
      setState(() {
        if (text.isNotEmpty) {
          if (_transcript.isNotEmpty && !_transcript.endsWith(' ')) {
            _transcript += ' ';
          }
          _transcript += text;
          _partialText = '';
        }
      });
      _scrollToBottom();
    };

    _speechService.onPartialResult = (text) {
      setState(() {
        _partialText = text;
      });
      _scrollToBottom();
    };

    _speechService.onError = (error) {
      // Only show critical errors, not speech recognition hiccups
      if (error.contains('not available') || error.contains('permission')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    };

    _speechService.onListeningStarted = () {
      setState(() {
        _isListening = true;
        _hasStarted = true;
      });
      _animationController.forward();
    };

    _speechService.onListeningStopped = () {
      if (_isListening) {
        setState(() {
          _isListening = false;
        });
        _animationController.stop();
        _animationController.reset();
      }
    };
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 50), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      });
    }
  }

  Future<void> _startListening() async {
    // Check and request microphone permission
    final status = await Permission.microphone.request();
    
    if (status.isDenied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Microphone permission is required for dictation'),
          ),
        );
      }
      return;
    }
    
    if (status.isPermanentlyDenied) {
      if (mounted) {
        _showPermissionDialog();
      }
      return;
    }

    // Haptic feedback
    HapticFeedback.mediumImpact();

    // Start timer
    _startTimer();

    // Start listening
    await _speechService.startListening();
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Microphone Permission'),
        content: const Text(
          'Microphone permission is required for voice dictation. '
          'Please enable it in your device settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _seconds++;
      });
    });
  }

  void _stopTimer() {
    _timer?.cancel();
  }

  Future<void> _stopListening() async {
    HapticFeedback.mediumImpact();
    
    await _speechService.stopListening();
    _stopTimer();

    setState(() {
      _isListening = false;
      // Add any remaining partial text to transcript
      if (_partialText.isNotEmpty) {
        if (_transcript.isNotEmpty && !_transcript.endsWith(' ')) {
          _transcript += ' ';
        }
        _transcript += _partialText;
        _partialText = '';
      }
    });

    _animationController.stop();
    _animationController.reset();
  }

  Future<void> _saveAndExit() async {
    if (_transcript.trim().isEmpty) {
      Navigator.pop(context);
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await context.read<DocumentProvider>().createDocument(_transcript.trim());
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Note saved successfully'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _discardAndExit() {
    if (_transcript.isEmpty) {
      Navigator.pop(context);
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard Note?'),
        content: const Text('Your recording will be lost. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(this.context);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _speechService.dispose();
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final size = MediaQuery.of(context).size;

    return PopScope(
      canPop: !_isListening && !_hasStarted,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          if (_isListening) {
            _stopListening();
          } else {
            _discardAndExit();
          }
        }
      },
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            onPressed: _isListening ? _stopListening : _discardAndExit,
            icon: const Icon(Icons.close),
          ),
          title: const Text('New Note'),
          centerTitle: true,
          actions: [
            if (_hasStarted && !_isListening)
              TextButton.icon(
                onPressed: _isSaving ? null : _saveAndExit,
                icon: _isSaving
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colorScheme.primary,
                        ),
                      )
                    : const Icon(Icons.check),
                label: const Text('Save'),
              ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Timer
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    Text(
                      _formatDuration(_seconds),
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w300,
                        color: _isListening
                            ? colorScheme.primary
                            : colorScheme.onSurface,
                        fontFeatures: [const FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: 8),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _isListening
                            ? colorScheme.errorContainer
                            : colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_isListening) ...[
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: colorScheme.error,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            _isListening
                                ? 'Recording...'
                                : (_hasStarted ? 'Paused' : 'Tap to start'),
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: _isListening
                                  ? colorScheme.onErrorContainer
                                  : colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Transcript area
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: colorScheme.outlineVariant.withOpacity(0.5),
                    ),
                  ),
                  child: _transcript.isEmpty && _partialText.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.mic_none,
                                size: 48,
                                color: colorScheme.outline,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Your words will appear here\nas you speak',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: colorScheme.outline,
                                ),
                              ),
                            ],
                          ),
                        )
                      : SingleChildScrollView(
                          controller: _scrollController,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SelectableText.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: _transcript,
                                      style: theme.textTheme.bodyLarge?.copyWith(
                                        color: colorScheme.onSurface,
                                        height: 1.6,
                                      ),
                                    ),
                                    if (_partialText.isNotEmpty)
                                      TextSpan(
                                        text: _partialText,
                                        style: theme.textTheme.bodyLarge?.copyWith(
                                          color: colorScheme.primary.withOpacity(0.7),
                                          height: 1.6,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),

              // Mic button
              Container(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: GestureDetector(
                  onTap: _isListening ? _stopListening : _startListening,
                  child: AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: Container(
                          width: size.width * 0.25,
                          height: size.width * 0.25,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: _isListening
                                  ? [
                                      colorScheme.error,
                                      colorScheme.error.withRed(200),
                                    ]
                                  : [
                                      colorScheme.primary,
                                      colorScheme.tertiary,
                                    ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: (_isListening
                                        ? colorScheme.error
                                        : colorScheme.primary)
                                    .withOpacity(0.4),
                                blurRadius: 24,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: Icon(
                            _isListening ? Icons.stop : Icons.mic,
                            size: size.width * 0.1,
                            color: Colors.white,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
