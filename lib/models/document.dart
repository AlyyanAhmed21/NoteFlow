import 'package:hive/hive.dart';

part 'document.g.dart';

/// Document model for storing voice dictation notes.
/// 
/// Each document contains:
/// - [id]: Unique identifier for the document
/// - [title]: Auto-generated or custom title
/// - [transcript]: Full speech-to-text transcript
/// - [summary]: AI-generated summary (nullable until LLM is called)
/// - [createdAt]: Timestamp when the document was created
@HiveType(typeId: 0)
class Document extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String transcript;

  @HiveField(3)
  String? summary;

  @HiveField(4)
  final DateTime createdAt;

  Document({
    required this.id,
    required this.title,
    required this.transcript,
    this.summary,
    required this.createdAt,
  });

  /// Creates a copy of this document with optional field updates.
  Document copyWith({
    String? id,
    String? title,
    String? transcript,
    String? summary,
    DateTime? createdAt,
  }) {
    return Document(
      id: id ?? this.id,
      title: title ?? this.title,
      transcript: transcript ?? this.transcript,
      summary: summary ?? this.summary,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Factory constructor for creating a new document from dictation.
  /// Automatically generates a title based on the current timestamp.
  factory Document.fromDictation({
    required String id,
    required String transcript,
    DateTime? createdAt,
  }) {
    final now = createdAt ?? DateTime.now();
    final title = _generateTitle(now);
    return Document(
      id: id,
      title: title,
      transcript: transcript,
      createdAt: now,
    );
  }

  /// Generates a default title in format: "Note — 2025-12-10 3:42 PM"
  static String _generateTitle(DateTime dateTime) {
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour;
    final displayHour = hour == 0 ? 12 : hour;
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    final minute = dateTime.minute.toString().padLeft(2, '0');
    
    return 'Note — ${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} $displayHour:$minute $period';
  }

  /// Returns the first line of the transcript for preview.
  String get transcriptPreview {
    if (transcript.isEmpty) return 'No content';
    final firstLine = transcript.split('\n').first;
    return firstLine.length > 100 ? '${firstLine.substring(0, 100)}...' : firstLine;
  }

  @override
  String toString() {
    return 'Document(id: $id, title: $title, createdAt: $createdAt)';
  }
}
