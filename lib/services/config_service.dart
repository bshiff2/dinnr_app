import 'package:cloud_firestore/cloud_firestore.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// Config Service - Fetches AI config from Firebase
/// ─────────────────────────────────────────────────────────────────────────────
/// 
/// Stores config in Firestore at: /config/ai
/// 
/// To set up in Firebase Console:
/// 1. Go to Firestore Database
/// 2. Create collection: "config"
/// 3. Create document with ID: "ai"
/// 4. Add fields:
///    - prompt (string): Your AI personality prompt
///    - model (string): "gpt-4o-mini" or "gpt-4o"
///    - apiKey (string): Your OpenAI API key
/// 
/// ─────────────────────────────────────────────────────────────────────────────

class ConfigService {
  static final ConfigService _instance = ConfigService._internal();
  factory ConfigService() => _instance;
  ConfigService._internal();

  final _firestore = FirebaseFirestore.instance;

  // Cached values
  String? _cachedPrompt;
  String? _cachedModel;
  String? _cachedApiKey;
  bool _isLoaded = false;

  // Default values if Firestore doesn't have them
  static const String _defaultPrompt = '''
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
  static const String _defaultModel = 'gpt-4o-mini';

  /// Load config from Firestore (call once at app start)
  Future<void> loadConfig() async {
    if (_isLoaded) return;

    try {
      final doc = await _firestore.collection('config').doc('ai').get();
      
      if (doc.exists) {
        final data = doc.data()!;
        _cachedPrompt = data['prompt'] as String?;
        _cachedModel = data['model'] as String?;
        _cachedApiKey = data['apiKey'] as String?;
      }
      _isLoaded = true;
    } catch (e) {
      print('ConfigService: Failed to load from Firestore: $e');
      _isLoaded = true;
    }
  }

  /// Get AI prompt from Firestore
  String get aiPrompt => _cachedPrompt ?? _defaultPrompt;

  /// Get AI model from Firestore
  String get aiModel => _cachedModel ?? _defaultModel;

  /// Get OpenAI API key from Firestore
  /// Throws if not configured in Firestore
  String get openAIKey {
    if (_cachedApiKey == null || _cachedApiKey!.isEmpty) {
      throw Exception('OpenAI API key not configured in Firestore. Add apiKey field to /config/ai');
    }
    return _cachedApiKey!;
  }

  /// Check if API key is configured
  bool get hasApiKey => _cachedApiKey != null && _cachedApiKey!.isNotEmpty;

  /// Force reload config from Firestore
  Future<void> reload() async {
    _isLoaded = false;
    await loadConfig();
  }

  /// Listen for real-time config updates
  Stream<void> onConfigChanged() {
    return _firestore.collection('config').doc('ai').snapshots().map((doc) {
      if (doc.exists) {
        final data = doc.data()!;
        _cachedPrompt = data['prompt'] as String?;
        _cachedModel = data['model'] as String?;
        _cachedApiKey = data['apiKey'] as String?;
      }
    });
  }
}
