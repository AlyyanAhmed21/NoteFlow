import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../models/document.dart';
import '../providers/document_provider.dart';

/// Screen for viewing and managing a single document.
/// 
/// Features:
/// - View/edit full transcript
/// - View/generate AI summary
/// - Edit title
/// - Delete document
/// - Share transcript
class DocumentDetailScreen extends StatefulWidget {
  final String documentId;

  const DocumentDetailScreen({
    super.key,
    required this.documentId,
  });

  @override
  State<DocumentDetailScreen> createState() => _DocumentDetailScreenState();
}

class _DocumentDetailScreenState extends State<DocumentDetailScreen> {
  Document? _document;
  bool _isGeneratingSummary = false;
  String? _summaryError;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _transcriptController = TextEditingController();
  bool _isEditingTitle = false;
  bool _isEditingTranscript = false;
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    _loadDocument();
  }

  void _loadDocument() {
    final provider = context.read<DocumentProvider>();
    _document = provider.getDocument(widget.documentId);
    if (_document != null) {
      _titleController.text = _document!.title;
      _transcriptController.text = _document!.transcript;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _transcriptController.dispose();
    super.dispose();
  }

  Future<void> _generateSummary() async {
    if (_document == null) return;

    // Save any pending transcript changes first
    if (_hasUnsavedChanges) {
      await _saveTranscript();
    }

    setState(() {
      _isGeneratingSummary = true;
      _summaryError = null;
    });

    try {
      await context.read<DocumentProvider>().generateSummary(_document!.id);
      _loadDocument();
    } catch (e) {
      setState(() {
        _summaryError = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      setState(() {
        _isGeneratingSummary = false;
      });
    }
  }

  Future<void> _updateTitle() async {
    if (_document == null) return;
    
    final newTitle = _titleController.text.trim();
    if (newTitle.isEmpty) {
      _titleController.text = _document!.title;
      setState(() {
        _isEditingTitle = false;
      });
      return;
    }

    if (newTitle != _document!.title) {
      await context.read<DocumentProvider>().updateTitle(_document!.id, newTitle);
      _loadDocument();
    }

    setState(() {
      _isEditingTitle = false;
    });
  }

  Future<void> _saveTranscript() async {
    if (_document == null) return;
    
    final newTranscript = _transcriptController.text.trim();
    if (newTranscript.isEmpty) {
      _transcriptController.text = _document!.transcript;
      return;
    }

    if (newTranscript != _document!.transcript) {
      await context.read<DocumentProvider>().updateTranscript(_document!.id, newTranscript);
      _loadDocument();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Note saved')),
        );
      }
    }

    setState(() {
      _isEditingTranscript = false;
      _hasUnsavedChanges = false;
    });
  }

  void _startEditingTranscript() {
    setState(() {
      _isEditingTranscript = true;
    });
  }

  void _cancelEditingTranscript() {
    _transcriptController.text = _document!.transcript;
    setState(() {
      _isEditingTranscript = false;
      _hasUnsavedChanges = false;
    });
  }

  Future<void> _deleteDocument() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note?'),
        content: const Text(
          'This action cannot be undone. Are you sure you want to delete this note?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<DocumentProvider>().deleteDocument(widget.documentId);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Note deleted')),
        );
      }
    }
  }

  void _shareDocument() {
    if (_document == null) return;

    final text = '''
${_document!.title}

${_document!.transcript}

${_document!.summary != null ? '---\nSummary:\n${_document!.summary}' : ''}
    '''.trim();

    Share.share(text, subject: _document!.title);
  }

  void _copyToClipboard() {
    if (_document == null) return;

    Clipboard.setData(ClipboardData(text: _document!.transcript));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Transcript copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_document == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Note'),
        ),
        body: const Center(
          child: Text('Document not found'),
        ),
      );
    }

    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop && _hasUnsavedChanges) {
          final shouldSave = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Unsaved Changes'),
              content: const Text('Would you like to save your changes before leaving?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Discard'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Save'),
                ),
              ],
            ),
          );
          
          if (shouldSave == true) {
            await _saveTranscript();
          }
          if (mounted) {
            Navigator.pop(context);
          }
        }
      },
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          backgroundColor: colorScheme.surface,
          title: Text(_isEditingTranscript ? 'Editing Note' : 'Note'),
          actions: [
            if (_isEditingTranscript) ...[
              IconButton(
                onPressed: _cancelEditingTranscript,
                icon: const Icon(Icons.close),
                tooltip: 'Cancel',
              ),
              IconButton(
                onPressed: _saveTranscript,
                icon: const Icon(Icons.check),
                tooltip: 'Save',
              ),
            ] else ...[
              IconButton(
                onPressed: _copyToClipboard,
                icon: const Icon(Icons.copy),
                tooltip: 'Copy transcript',
              ),
              IconButton(
                onPressed: _shareDocument,
                icon: const Icon(Icons.share),
                tooltip: 'Share',
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'delete') {
                    _deleteDocument();
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: colorScheme.error),
                        const SizedBox(width: 12),
                        Text(
                          'Delete',
                          style: TextStyle(color: colorScheme.error),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title section
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isEditingTitle = true;
                  });
                },
                child: _isEditingTitle
                    ? TextField(
                        controller: _titleController,
                        autofocus: true,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.all(16),
                        ),
                        onSubmitted: (_) => _updateTitle(),
                        onEditingComplete: _updateTitle,
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: Text(
                              _document!.title,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.edit,
                            size: 18,
                            color: colorScheme.outline,
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 8),
              
              // Timestamp and word count
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: colorScheme.outline,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(_document!.createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.outline,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.notes,
                    size: 14,
                    color: colorScheme.outline,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${_wordCount(_transcriptController.text)} words',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.outline,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Transcript section
              Row(
                children: [
                  _buildSectionHeader(context, 'Note Content', Icons.format_quote),
                  const Spacer(),
                  if (!_isEditingTranscript)
                    TextButton.icon(
                      onPressed: _startEditingTranscript,
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Edit'),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _isEditingTranscript 
                        ? colorScheme.primary 
                        : colorScheme.outlineVariant.withOpacity(0.5),
                    width: _isEditingTranscript ? 2 : 1,
                  ),
                ),
                child: _isEditingTranscript
                    ? TextField(
                        controller: _transcriptController,
                        maxLines: null,
                        minLines: 10,
                        autofocus: true,
                        onChanged: (value) {
                          setState(() {
                            _hasUnsavedChanges = value != _document!.transcript;
                          });
                        },
                        style: theme.textTheme.bodyLarge?.copyWith(
                          height: 1.6,
                          color: colorScheme.onSurface,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(16),
                          hintText: 'Enter your note...',
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.all(16),
                        child: SelectableText(
                          _document!.transcript.isEmpty 
                              ? 'No content yet. Tap Edit to add text.'
                              : _document!.transcript,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            height: 1.6,
                            color: _document!.transcript.isEmpty 
                                ? colorScheme.outline 
                                : colorScheme.onSurface,
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 32),

              // Summary section
              _buildSectionHeader(context, 'AI Summary', Icons.auto_awesome),
              const SizedBox(height: 12),

              if (_summaryError != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: colorScheme.onErrorContainer,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _summaryError!,
                          style: TextStyle(
                            color: colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              if (_document!.summary != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        colorScheme.primaryContainer.withOpacity(0.5),
                        colorScheme.tertiaryContainer.withOpacity(0.5),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colorScheme.primary.withOpacity(0.3),
                    ),
                  ),
                  child: SelectableText(
                    _document!.summary!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.6,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Generate/Regenerate summary button
              SizedBox(
                width: double.infinity,
                child: _isGeneratingSummary
                    ? Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Generating summary...',
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      )
                    : FilledButton.tonal(
                        onPressed: _transcriptController.text.trim().isEmpty 
                            ? null 
                            : _generateSummary,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              size: 20,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _document!.summary != null
                                  ? 'Regenerate Summary'
                                  : 'Generate Summary (Groq)',
                              style: TextStyle(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),

              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime dateTime) {
    return DateFormat('EEEE, MMMM d, y \'at\' h:mm a').format(dateTime);
  }

  int _wordCount(String text) {
    if (text.trim().isEmpty) return 0;
    return text.trim().split(RegExp(r'\s+')).length;
  }
}
