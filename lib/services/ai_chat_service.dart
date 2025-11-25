import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';

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
  /// Returns AIResponse with text and detected mood.
  Future<AIResponse> sendMessage({
    required String message,
    List<AIChatMessage> history = const [],
    bool useAudio = false,
    String? locationContext,
  }) async {
    String prompt = useAudio ? audioPrompt : _basePrompt;
    
    // Add location context to system prompt if available
    if (locationContext != null && locationContext.isNotEmpty) {
      prompt = '$prompt\n\nLOCATION INFO:\n$locationContext\n\nUse this location info to recommend specific nearby restaurants when asked about food places.';
    }
    
    final messages = <Map<String, String>>[
      {'role': 'system', 'content': prompt},
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

    // Parse mood and clean text
    final parsed = _parseMoodAndText(reply.trim());

    // Generate and play audio if requested
    if (useAudio) {
      await _speakText(parsed.text);
    }

    return parsed;
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

      final tempDir = await getTemporaryDirectory();
      final audioFile = File('${tempDir.path}/tts_response.mp3');
      await audioFile.writeAsBytes(response.bodyBytes);
      
      await _audioPlayer.play(DeviceFileSource(audioFile.path));
    } catch (e) {
      print('TTS Error: $e');
    }
  }

  Future<void> speak(String text) async => await _speakText(text);
  Future<void> stopAudio() async => await _audioPlayer.stop();
  bool get isPlaying => _audioPlayer.state == PlayerState.playing;
  void dispose() => _audioPlayer.dispose();
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
