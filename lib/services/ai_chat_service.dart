import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';

import 'location_service.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// AI Chat Service - Direct OpenAI Integration with Audio & Mood Support
/// ─────────────────────────────────────────────────────────────────────────────

/// Available TTS voices (female voices)
enum TTSVoice {
  alloy,    // Neutral
  nova,     // Female, warm
  shimmer,  // Female, expressive
}

/// Miku mood states for avatar display
enum MikuMood {
  happy,      // General positive, greetings
  excited,    // Recommending something great
  thinking,   // Processing, considering options
  teaching,   // Explaining something
  love,       // Romantic food/date suggestions
  surprised,  // Interesting facts
  confused,   // Doesn't understand
  neutral,    // Default state
}

/// Response with mood information
class AIResponse {
  final String text;
  final MikuMood mood;
  
  const AIResponse({required this.text, required this.mood});
}

class AIChatService {
  AIChatService({
    required String apiKey,
    String? basePrompt,
    String? model,
    TTSVoice? voice,
  })  : _apiKey = apiKey,
        _basePrompt = basePrompt ?? defaultPrompt,
        _model = model ?? 'gpt-4o-mini',
        _voice = voice ?? TTSVoice.nova;

  final String _apiKey;
  final String _basePrompt;
  final String _model;
  final TTSVoice _voice;
  
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  /// Stream that emits when audio playback completes
  Stream<void> get onAudioComplete => _audioPlayer.onPlayerComplete;

  // ─── Default Prompt ─────────────────────────────────────────────────────────
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

IMPORTANT: Start every response with a mood tag in brackets. Choose from:
[HAPPY] - greetings, positive responses
[EXCITED] - recommending something amazing
[THINKING] - considering options, "let me think"
[TEACHING] - explaining recipes, techniques, facts
[LOVE] - romantic suggestions, date ideas
[SURPRISED] - sharing interesting facts, "did you know"
[CONFUSED] - need clarification
[NEUTRAL] - general responses

Example: "[EXCITED] Oh, you HAVE to try the new ramen place downtown!"
''';

  // ─── Audio Prompt (shorter for voice) ───────────────────────────────────────
  static const String audioPrompt = '''
You are Dinnr, a friendly foodie assistant. Keep responses short and conversational since they will be spoken aloud. Be warm and enthusiastic about food recommendations.

IMPORTANT: Start every response with a mood tag in brackets: [HAPPY], [EXCITED], [THINKING], [TEACHING], [LOVE], [SURPRISED], [CONFUSED], or [NEUTRAL].
Example: "[EXCITED] Oh, you have to try that place!"
''';

  // ─── Send Message ───────────────────────────────────────────────────────────
  /// Sends a user [message] with optional conversation [history].
  /// Include [locationContext] to give AI info about user's location and nearby places.
  /// Include [nearbyPlaces] to provide real restaurant data from Google Places API.
  /// If [useAudio] is true, also generates and plays audio response.
  /// Returns AIChatResponse with text, optional restaurant data, and detected mood.
  Future<AIChatResponse> sendMessage({
    required String message,
    List<AIChatMessage> history = const [],
    bool useAudio = false,
    String? locationContext,
    List<NearbyPlace>? nearbyPlaces,
  }) async {
    String basePrompt = useAudio ? audioPrompt : _basePrompt;
    
    // Add location context to system prompt if available
    if (locationContext != null && locationContext.isNotEmpty) {
      basePrompt = '$basePrompt\n\nLOCATION INFO:\n$locationContext';
    }
    
    // Add nearby places data if available
    String nearbyPlacesContext = '';
    if (nearbyPlaces != null && nearbyPlaces.isNotEmpty) {
      final placesBuffer = StringBuffer('\n\nNEARBY RESTAURANTS (from Google Maps - USE THESE EXACT NAMES):\n');
      for (final place in nearbyPlaces) {
        placesBuffer.writeln('- ${place.name}');
        placesBuffer.writeln('  Address: ${place.address}');
        if (place.rating != null) placesBuffer.writeln('  Rating: ${place.rating}/5 (${place.userRatingsTotal ?? 0} reviews)');
        if (place.priceLevel != null) placesBuffer.writeln('  Price: ${"\$" * place.priceLevel!}');
        if (place.isOpen != null) placesBuffer.writeln('  ${place.isOpen! ? "Open now" : "Currently closed"}');
        if (place.types.isNotEmpty) placesBuffer.writeln('  Type: ${place.types.take(3).join(", ")}');
        if (place.placeId != null) placesBuffer.writeln('  PlaceID: ${place.placeId}');
        placesBuffer.writeln();
      }
      nearbyPlacesContext = placesBuffer.toString();
    }
    
    final enhancedPrompt = '''
$basePrompt
$nearbyPlacesContext

CRITICAL RULE: When recommending a restaurant, you MUST ONLY recommend restaurants from the NEARBY RESTAURANTS list above.
DO NOT make up restaurant names. If no nearby restaurants are provided, ask the user what type of food they're in the mood for.

When recommending restaurants, follow this EXACT format:
1. Write your conversational response (WITHOUT mentioning the restaurant JSON structure)
2. Add a blank line
3. Add the marker: RESTAURANT_DATA:
4. Add the JSON object (properly formatted, one per response)

The JSON MUST use this structure (use EXACT name and address from the nearby list):
{
  "name": "Exact Restaurant Name from list",
  "description": "Brief compelling description",
  "imageUrl": "https://images.unsplash.com/photo-XXXXX?w=800",
  "address": "Exact address from list",
  "rating": 4.5,
  "priceLevel": "\$\$",
  "cuisineType": "Type of cuisine",
  "placeId": "PlaceID from list if available"
}

IMPORTANT RULES:
- ONLY recommend restaurants from the NEARBY RESTAURANTS list
- Use the EXACT name as shown in the list
- Only add ONE restaurant per response
- The RESTAURANT_DATA: marker MUST be on its own line
- The JSON must be valid (proper quotes, commas, braces)
- Do NOT show the JSON structure to the user in your conversational text
- Use relevant Unsplash image URLs for the cuisine type

Unsplash image URL reference:
- Burgers: https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=800
- Pizza: https://images.unsplash.com/photo-1513104890138-7c749659a591?w=800
- Sushi: https://images.unsplash.com/photo-1579584425555-c3ce17fd4351?w=800
- Italian: https://images.unsplash.com/photo-1498837167922-ddd27525d352?w=800
- Mexican: https://images.unsplash.com/photo-1565299585323-38d6b0865b47?w=800
- Asian: https://images.unsplash.com/photo-1617093727343-374698b1b08d?w=800
- Fine Dining: https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=800
- General Restaurant: https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=800
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
        'max_tokens': useAudio ? 256 : 1024,
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

    final trimmedReply = reply.trim();
    
    // Parse mood and text
    final parsed = _parseMoodAndText(trimmedReply);
    
    // Parse restaurant data
    final parsedResponse = _parseResponse(parsed.text);
    
    // Generate and play audio if requested
    if (useAudio) {
      await _speakText(parsedResponse.text);
    }

    return AIChatResponse(
      text: parsedResponse.text,
      restaurantData: parsedResponse.restaurantData,
      mood: parsed.mood,
    );
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
    var jsonStr = reply.substring(markerIndex + marker.length).trim();
    
    // Try to extract JSON from the response (find first { to last })
    final jsonStart = jsonStr.indexOf('{');
    final jsonEnd = jsonStr.lastIndexOf('}');
    
    if (jsonStart != -1 && jsonEnd != -1 && jsonEnd > jsonStart) {
      jsonStr = jsonStr.substring(jsonStart, jsonEnd + 1);
    }

    try {
      // Clean up any potential issues with the JSON string
      jsonStr = jsonStr
          .replaceAll('\n', ' ')
          .replaceAll('  ', ' ')
          .trim();
      
      final jsonData = jsonDecode(jsonStr) as Map<String, dynamic>;
      
      // Validate required fields
      if (jsonData['name'] == null || jsonData['description'] == null || jsonData['imageUrl'] == null) {
        print('Invalid restaurant data: missing required fields');
        return AIChatResponse(text: reply);
      }
      
      return AIChatResponse(
        text: text,
        restaurantData: jsonData,
      );
    } catch (e) {
      // If JSON parsing fails, return just the text
      print('Failed to parse restaurant JSON: $e');
      print('JSON string was: $jsonStr');
      return AIChatResponse(text: reply);
    }
  }

  // ─── Parse Mood from Response ───────────────────────────────────────────────
  AIResponse _parseMoodAndText(String response) {
    final moodRegex = RegExp(r'^\[(\w+)\]\s*', caseSensitive: false);
    final match = moodRegex.firstMatch(response);
    
    MikuMood mood = MikuMood.neutral;
    String text = response;
    
    if (match != null) {
      final moodTag = match.group(1)?.toUpperCase();
      text = response.substring(match.end).trim();
      
      switch (moodTag) {
        case 'HAPPY':
          mood = MikuMood.happy;
          break;
        case 'EXCITED':
          mood = MikuMood.excited;
          break;
        case 'THINKING':
          mood = MikuMood.thinking;
          break;
        case 'TEACHING':
          mood = MikuMood.teaching;
          break;
        case 'LOVE':
          mood = MikuMood.love;
          break;
        case 'SURPRISED':
          mood = MikuMood.surprised;
          break;
        case 'CONFUSED':
          mood = MikuMood.confused;
          break;
        default:
          mood = MikuMood.neutral;
      }
    }
    
    return AIResponse(text: text, mood: mood);
  }

  // ─── Text to Speech ─────────────────────────────────────────────────────────
  Future<void> _speakText(String text) async {
    try {
      final voiceName = _voice.name;
      
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/audio/speech'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'tts-1',
          'input': text,
          'voice': voiceName,
          'response_format': 'mp3',
        }),
      );

      if (response.statusCode != 200) {
        print('TTS Error: ${response.statusCode} - ${response.body}');
        return;
      }

      await _audioPlayer.stop(); // clear any existing playback before starting
      
      // Write to temp file for iOS compatibility (BytesSource doesn't work reliably on iOS)
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/tts_audio_${DateTime.now().millisecondsSinceEpoch}.mp3');
      await tempFile.writeAsBytes(response.bodyBytes);
      
      await _audioPlayer.play(DeviceFileSource(tempFile.path));
      
      // Clean up temp file after playback completes
      _audioPlayer.onPlayerComplete.first.then((_) {
        tempFile.delete().ignore();
      });
    } catch (e) {
      print('TTS Error: $e');
    }
  }

  Future<void> speak(String text) async => await _speakText(text);
  Future<void> stopAudio() async => await _audioPlayer.stop();
  bool get isPlaying => _audioPlayer.state == PlayerState.playing;
  void dispose() => _audioPlayer.dispose();
}

// ─── Response Model ───────────────────────────────────────────────────────────
/// AI response containing text, optional restaurant data, and mood
class AIChatResponse {
  const AIChatResponse({
    required this.text,
    this.restaurantData,
    this.mood,
  });

  final String text;
  final Map<String, dynamic>? restaurantData;
  final MikuMood? mood;
}

// ─── Message Model ────────────────────────────────────────────────────────────
class AIChatMessage {
  const AIChatMessage({required this.role, required this.content});

  final String role;
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
