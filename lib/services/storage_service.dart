import 'package:hive_flutter/hive_flutter.dart';
import '../models/document.dart';

/// Service for managing document storage using Hive.
/// 
/// Provides CRUD operations for documents with fast local storage
/// and offline support.
class StorageService {
  static const String _boxName = 'documents';
  late Box<Document> _box;

  /// Initializes the storage service.
  /// Must be called before any other operations.
  Future<void> init() async {
    await Hive.initFlutter();
    
    // Register the Document adapter if not already registered
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(DocumentAdapter());
    }
    
    _box = await Hive.openBox<Document>(_boxName);
  }

  /// Saves a new document or updates an existing one.
  /// 
  /// [document] - The document to save
  Future<void> saveDocument(Document document) async {
    await _box.put(document.id, document);
  }

  /// Retrieves all documents sorted by creation date (newest first).
  List<Document> getAllDocuments() {
    final documents = _box.values.toList();
    documents.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return documents;
  }

  /// Retrieves a single document by its ID.
  /// 
  /// [id] - The document ID
  /// Returns the document or null if not found.
  Document? getDocument(String id) {
    return _box.get(id);
  }

  /// Deletes a document by its ID.
  /// 
  /// [id] - The document ID to delete
  Future<void> deleteDocument(String id) async {
    await _box.delete(id);
  }

  /// Updates the summary field of a document.
  /// 
  /// [id] - The document ID
  /// [summary] - The new summary text
  Future<void> updateSummary(String id, String summary) async {
    final document = _box.get(id);
    if (document != null) {
      document.summary = summary;
      await document.save();
    }
  }

  /// Updates the title of a document.
  /// 
  /// [id] - The document ID
  /// [title] - The new title
  Future<void> updateTitle(String id, String title) async {
    final document = _box.get(id);
    if (document != null) {
      document.title = title;
      await document.save();
    }
  }

  /// Updates the transcript of a document.
  /// 
  /// [id] - The document ID
  /// [transcript] - The new transcript text
  Future<void> updateTranscript(String id, String transcript) async {
    final document = _box.get(id);
    if (document != null) {
      document.transcript = transcript;
      await document.save();
    }
  }

  /// Searches documents by title or transcript content.
  /// 
  /// [query] - The search query
  /// Returns a list of matching documents.
  List<Document> searchDocuments(String query) {
    if (query.isEmpty) return getAllDocuments();
    
    final lowerQuery = query.toLowerCase();
    return getAllDocuments().where((doc) {
      return doc.title.toLowerCase().contains(lowerQuery) ||
             doc.transcript.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  /// Gets the total number of documents.
  int get documentCount => _box.length;

  /// Closes the storage box.
  Future<void> close() async {
    await _box.close();
  }
}
