import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// AI Chat Service - Direct OpenAI Integration with Audio Support
/// ─────────────────────────────────────────────────────────────────────────────
/// 
/// USAGE:
/// ```dart
/// final ai = AIChatService(
///   apiKey: 'sk-...',
///   basePrompt: 'You are a helpful cooking assistant.',
/// );
/// 
/// // Text response
/// final reply = await ai.sendMessage(message: 'Hello!');
/// 
/// // Audio response (speaks the reply in a female voice)
/// final reply = await ai.sendMessage(message: 'Hello!', useAudio: true);
/// ```
/// ─────────────────────────────────────────────────────────────────────────────

/// Available TTS voices (female voices)
enum TTSVoice {
  alloy,    // Neutral
  nova,     // Female, warm
  shimmer,  // Female, expressive
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
''';

  // ─── Audio Prompt (shorter for voice) ───────────────────────────────────────
  static const String audioPrompt = '''
You are Dinnr, a friendly foodie assistant. Keep responses short and conversational since they will be spoken aloud. Be warm and enthusiastic about food recommendations.
''';

  // ─── Send Message ───────────────────────────────────────────────────────────
  /// Sends a user [message] with optional conversation [history].
  /// If [useAudio] is true, also generates and plays audio response.
  /// Returns the AI's reply text.
  Future<String> sendMessage({
    required String message,
    List<AIChatMessage> history = const [],
    bool useAudio = false,
  }) async {
    // Use shorter prompt for audio mode
    final prompt = useAudio ? audioPrompt : _basePrompt;
    
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
        'max_tokens': useAudio ? 256 : 1024, // Shorter for audio
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

    // Generate and play audio if requested
    if (useAudio) {
      await _speakText(trimmedReply);
    }

    return trimmedReply;
  }

  // ─── Text to Speech ─────────────────────────────────────────────────────────
  /// Converts text to speech using OpenAI TTS and plays it
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

      // Save audio to temp file and play
      final tempDir = await getTemporaryDirectory();
      final audioFile = File('${tempDir.path}/tts_response.mp3');
      await audioFile.writeAsBytes(response.bodyBytes);
      
      await _audioPlayer.play(DeviceFileSource(audioFile.path));
    } catch (e) {
      print('TTS Error: $e');
    }
  }

  /// Speak text directly (for replaying messages)
  Future<void> speak(String text) async {
    await _speakText(text);
  }

  /// Stop any currently playing audio
  Future<void> stopAudio() async {
    await _audioPlayer.stop();
  }

  /// Check if audio is currently playing
  bool get isPlaying => _audioPlayer.state == PlayerState.playing;

  /// Clean up resources
  void dispose() {
    _audioPlayer.dispose();
  }
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
