import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Service for interacting with the Groq API for AI summarization.
/// 
/// Uses the Groq API with llama3-70b-8192 model to generate
/// crisp bullet summaries with action items from transcripts.
class GroqService {
  static const String _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';
  static const String _model = 'llama3-70b-8192';
  
  late final Dio _dio;
  String? _apiKey;

  GroqService() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
    ));
  }

  /// Initializes the service with the API key from environment.
  void init() {
    _apiKey = dotenv.env['GROQ_API_KEY'];
  }

  /// Checks if the API key is configured.
  bool get isConfigured => _apiKey != null && _apiKey!.isNotEmpty && _apiKey != 'your_groq_api_key_here';

  /// Generates a summary with action items from the given transcript.
  /// 
  /// [transcript] - The full transcript text to summarize
  /// 
  /// Returns a formatted summary with bullet points and action items.
  /// Throws an exception if the API call fails.
  Future<String> summarizeTranscript(String transcript) async {
    if (!isConfigured) {
      throw Exception('Groq API key not configured. Please add your API key to the .env file.');
    }

    if (transcript.trim().isEmpty) {
      throw Exception('Cannot summarize empty transcript');
    }

    try {
      final response = await _dio.post(
        '',
        options: Options(
          headers: {
            'Authorization': 'Bearer $_apiKey',
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'model': _model,
          'messages': [
            {
              'role': 'system',
              'content': '''You are a helpful assistant that creates concise, well-organized summaries.

Given a transcript, create:
1. A crisp bullet-point summary (3-5 key points)
2. 3 actionable items based on the content

Format your response as:

## Summary
• [Key point 1]
• [Key point 2]
• [Key point 3]

## Action Items
1. [Action 1]
2. [Action 2]
3. [Action 3]

Keep the summary concise and focused on the most important information.'''
            },
            {
              'role': 'user',
              'content': 'Please summarize the following transcript:\n\n$transcript'
            }
          ],
          'temperature': 0.7,
          'max_tokens': 1024,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final content = data['choices']?[0]?['message']?['content'];
        
        if (content != null && content.toString().isNotEmpty) {
          return content.toString();
        }
        throw Exception('Empty response from Groq API');
      } else {
        throw Exception('API request failed with status: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Invalid API key. Please check your Groq API key.');
      } else if (e.response?.statusCode == 429) {
        throw Exception('Rate limit exceeded. Please try again later.');
      } else if (e.type == DioExceptionType.connectionTimeout) {
        throw Exception('Connection timeout. Please check your internet connection.');
      } else if (e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Request timeout. The server took too long to respond.');
      }
      throw Exception('Failed to generate summary: ${e.message}');
    } catch (e) {
      throw Exception('Failed to generate summary: $e');
    }
  }
}
