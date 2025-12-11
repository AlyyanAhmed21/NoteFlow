import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/document.dart';
import '../services/storage_service.dart';
import '../services/groq_service.dart';

/// Provider for managing document state across the application.
/// 
/// Handles:
/// - Loading and caching documents
/// - CRUD operations
/// - Search/filter functionality
/// - AI summarization integration
class DocumentProvider extends ChangeNotifier {
  final StorageService _storageService;
  final GroqService _groqService;
  final Uuid _uuid = const Uuid();

  List<Document> _documents = [];
  List<Document> _filteredDocuments = [];
  String _searchQuery = '';
  bool _isLoading = false;
  String? _error;

  DocumentProvider({
    required StorageService storageService,
    required GroqService groqService,
  })  : _storageService = storageService,
        _groqService = groqService;

  /// List of all documents.
  List<Document> get documents => _searchQuery.isEmpty ? _documents : _filteredDocuments;

  /// Whether documents are currently being loaded.
  bool get isLoading => _isLoading;

  /// Current error message, if any.
  String? get error => _error;

  /// Current search query.
  String get searchQuery => _searchQuery;

  /// Total number of documents.
  int get documentCount => _documents.length;

  /// Whether the Groq API is configured.
  bool get isGroqConfigured => _groqService.isConfigured;

  /// Loads all documents from storage.
  Future<void> loadDocuments() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _documents = _storageService.getAllDocuments();
      _applySearch();
    } catch (e) {
      _error = 'Failed to load documents: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Creates a new document from a dictation transcript.
  /// 
  /// [transcript] - The full transcript text
  /// Returns the created document.
  Future<Document> createDocument(String transcript) async {
    final document = Document.fromDictation(
      id: _uuid.v4(),
      transcript: transcript,
    );

    await _storageService.saveDocument(document);
    _documents.insert(0, document);
    _applySearch();
    notifyListeners();

    return document;
  }

  /// Updates an existing document.
  /// 
  /// [document] - The document to update
  Future<void> updateDocument(Document document) async {
    await _storageService.saveDocument(document);
    
    final index = _documents.indexWhere((d) => d.id == document.id);
    if (index != -1) {
      _documents[index] = document;
      _applySearch();
      notifyListeners();
    }
  }

  /// Updates the title of a document.
  /// 
  /// [id] - The document ID
  /// [title] - The new title
  Future<void> updateTitle(String id, String title) async {
    await _storageService.updateTitle(id, title);
    
    final index = _documents.indexWhere((d) => d.id == id);
    if (index != -1) {
      _documents[index].title = title;
      _applySearch();
      notifyListeners();
    }
  }

  /// Deletes a document by ID.
  /// 
  /// [id] - The document ID to delete
  Future<void> deleteDocument(String id) async {
    await _storageService.deleteDocument(id);
    _documents.removeWhere((d) => d.id == id);
    _applySearch();
    notifyListeners();
  }

  /// Updates the transcript of a document.
  /// 
  /// [id] - The document ID
  /// [transcript] - The new transcript text
  Future<void> updateTranscript(String id, String transcript) async {
    await _storageService.updateTranscript(id, transcript);
    
    final index = _documents.indexWhere((d) => d.id == id);
    if (index != -1) {
      _documents[index].transcript = transcript;
      _applySearch();
      notifyListeners();
    }
  }

  /// Generates and saves an AI summary for a document.
  /// 
  /// [id] - The document ID to summarize
  /// Returns the generated summary.
  /// Throws an exception if summarization fails.
  Future<String> generateSummary(String id) async {
    final document = _documents.firstWhere(
      (d) => d.id == id,
      orElse: () => throw Exception('Document not found'),
    );

    try {
      final summary = await _groqService.summarizeTranscript(document.transcript);
      
      await _storageService.updateSummary(id, summary);
      
      final index = _documents.indexWhere((d) => d.id == id);
      if (index != -1) {
        _documents[index].summary = summary;
        notifyListeners();
      }
      
      return summary;
    } catch (e) {
      rethrow;
    }
  }

  /// Gets a document by ID.
  /// 
  /// [id] - The document ID
  /// Returns the document or null if not found.
  Document? getDocument(String id) {
    try {
      return _documents.firstWhere((d) => d.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Updates the search query and filters documents.
  /// 
  /// [query] - The search query
  void setSearchQuery(String query) {
    _searchQuery = query;
    _applySearch();
    notifyListeners();
  }

  /// Clears the current search query.
  void clearSearch() {
    _searchQuery = '';
    _filteredDocuments = [];
    notifyListeners();
  }

  /// Applies the current search query to filter documents.
  void _applySearch() {
    if (_searchQuery.isEmpty) {
      _filteredDocuments = [];
      return;
    }

    final lowerQuery = _searchQuery.toLowerCase();
    _filteredDocuments = _documents.where((doc) {
      return doc.title.toLowerCase().contains(lowerQuery) ||
             doc.transcript.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  /// Clears any error state.
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
