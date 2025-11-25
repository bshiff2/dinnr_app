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
  /// Returns an [AIChatResponse] with text and optional restaurant data.
  Future<AIChatResponse> sendMessage({
    required String message,
    List<AIChatMessage> history = const [],
  }) async {
    final enhancedPrompt = '''
$_basePrompt

When recommending restaurants, ALWAYS respond in this exact format:
1. First, write your natural conversational response
2. Then, if you're recommending a specific restaurant, add it at the end in this JSON format:

RESTAURANT_DATA:
{
  "name": "Restaurant Name",
  "description": "Brief description of the restaurant and what makes it special",
  "imageUrl": "https://placeholder-url.com/restaurant.jpg",
  "address": "Full address if known, otherwise general area",
  "rating": 4.5,
  "priceLevel": "\$\$",
  "cuisineType": "Cuisine type"
}

Example:
"Here is a nearby option for burgers:

Burgersmith offers hand-crafted patties with house-made buns and customizable toppings. They're known for their Classic Smith burger and quick, friendly service. Great for a casual meal!

RESTAURANT_DATA:
{
  "name": "Burgersmith",
  "description": "Hand-crafted patties, house-made buns, and customizable toppings. Popular for Classic Smith and Savory Bacon burgers. Quick service, solid craft beer lineup.",
  "imageUrl": "https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=800",
  "address": "Perkins & Main St",
  "rating": 4.5,
  "priceLevel": "\$\$",
  "cuisineType": "American"
}"

Note: For imageUrl, use relevant Unsplash URLs like:
- Burgers: https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=800
- Pizza: https://images.unsplash.com/photo-1513104890138-7c749659a591?w=800
- Sushi: https://images.unsplash.com/photo-1579584425555-c3ce17fd4351?w=800
- Italian: https://images.unsplash.com/photo-1498837167922-ddd27525d352?w=800
- Mexican: https://images.unsplash.com/photo-1565299585323-38d6b0865b47?w=800
- Asian: https://images.unsplash.com/photo-1617093727343-374698b1b08d?w=800
- Fine Dining: https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=800
''';

    final messages = <Map<String, String>>[
      {'role': 'system', 'content': enhancedPrompt},
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

    return _parseResponse(reply.trim());
  }

  // ─── Parse Response ─────────────────────────────────────────────────────────
  /// Parses AI response to extract text and optional restaurant data
  AIChatResponse _parseResponse(String reply) {
    const marker = 'RESTAURANT_DATA:';
    final markerIndex = reply.indexOf(marker);

    if (markerIndex == -1) {
      return AIChatResponse(text: reply);
    }

    // Split into text and JSON parts
    final text = reply.substring(0, markerIndex).trim();
    final jsonStr = reply.substring(markerIndex + marker.length).trim();

    try {
      final jsonData = jsonDecode(jsonStr) as Map<String, dynamic>;
      return AIChatResponse(
        text: text,
        restaurantData: jsonData,
      );
    } catch (e) {
      // If JSON parsing fails, return just the text
      return AIChatResponse(text: reply);
    }
  }

  /// Clean up resources (no-op for HTTP, kept for API consistency)
  void dispose() {}
}

// ─── Response Model ───────────────────────────────────────────────────────────
/// AI response containing text and optional restaurant data
class AIChatResponse {
  const AIChatResponse({
    required this.text,
    this.restaurantData,
  });

  final String text;
  final Map<String, dynamic>? restaurantData;
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
