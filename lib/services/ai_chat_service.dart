import 'dart:convert';
import 'package:http/http.dart' as http;

/// ─────────────────────────────────────────────────────────────────────────────
/// AI Chat Service - Direct OpenAI Integration
/// ─────────────────────────────────────────────────────────────────────────────
/// 
/// USAGE:
/// ```dart
/// final ai = AIChatService(
///   apiKey: 'sk-...',
///   basePrompt: 'You are a helpful cooking assistant.',  // Optional
/// );
/// final reply = await ai.sendMessage(message: 'Hello!');
/// ```
/// 
/// To change the AI personality, just pass a different basePrompt:
/// ```dart
/// final ai = AIChatService(
///   apiKey: 'sk-...',
///   basePrompt: 'You are a sarcastic chef who loves Italian food.',
/// );
/// ```
/// ─────────────────────────────────────────────────────────────────────────────

class AIChatService {
  AIChatService({
    required String apiKey,
    String? basePrompt,
    String? model,
  })  : _apiKey = apiKey,
        _basePrompt = basePrompt ?? defaultPrompt,
        _model = model ?? 'gpt-4o-mini';

  final String _apiKey;
  final String _basePrompt;
  final String _model;

  // ─── Default Prompt ─────────────────────────────────────────────────────────
  /// Change this to customize the AI's default personality
  static const String defaultPrompt = '''
You are Dinnr, a playful and knowledgeable foodie concierge. You help couples and friends discover amazing dining experiences together.

Your personality:
- Warm, friendly, and enthusiastic about food
- Great at suggesting date night restaurants
- Know cuisines from around the world
- Can recommend recipes for cooking at home
- Help with meal planning and grocery lists
- Give quick, helpful answers (keep responses concise)

Always be supportive and make food decisions fun!
''';

  // ─── Send Message ───────────────────────────────────────────────────────────
  /// Sends a user [message] with optional conversation [history].
  /// Returns the AI's reply text.
  Future<String> sendMessage({
    required String message,
    List<AIChatMessage> history = const [],
  }) async {
    final messages = <Map<String, String>>[
      {'role': 'system', 'content': _basePrompt},
      ...history.map((msg) => msg.toJson()),
      {'role': 'user', 'content': message},
    ];

    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      body: jsonEncode({
        'model': _model,
        'messages': messages,
        'temperature': 0.7,
        'max_tokens': 1024,
      }),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw AIChatException(
        error['error']?['message'] ?? 'API request failed: ${response.statusCode}',
      );
    }

    final data = jsonDecode(response.body);
    final reply = data['choices']?[0]?['message']?['content'] as String?;

    if (reply == null || reply.isEmpty) {
      throw const AIChatException('OpenAI returned an empty response.');
    }

    return reply.trim();
  }

  /// Clean up resources (no-op for HTTP, kept for API consistency)
  void dispose() {}
}

// ─── Message Model ────────────────────────────────────────────────────────────
/// Simple model for chat messages
class AIChatMessage {
  const AIChatMessage({required this.role, required this.content});

  final String role; // "user" or "assistant"
  final String content;

  Map<String, String> toJson() => {'role': role, 'content': content};
}

// ─── Exception ────────────────────────────────────────────────────────────────
class AIChatException implements Exception {
  const AIChatException(this.message);
  final String message;

  @override
  String toString() => 'AIChatException: $message';
}
