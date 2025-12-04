import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing app settings using SharedPreferences
class SettingsService {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  SharedPreferences? _prefs;

  /// Initialize the service - call this early in app startup
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Ensure prefs is loaded
  Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // ============ Voice Mode Settings ============

  /// Whether to show subtitles/transcripts in voice mode
  static const String _keyShowSubtitles = 'voice_show_subtitles';
  
  bool get showSubtitles => _prefs?.getBool(_keyShowSubtitles) ?? true;
  
  Future<void> setShowSubtitles(bool value) async {
    final prefs = await _getPrefs();
    await prefs.setBool(_keyShowSubtitles, value);
  }

  // ============ Notification Settings ============

  static const String _keyPushNotifications = 'notify_push';
  static const String _keyEmailUpdates = 'notify_email';

  bool get pushNotifications => _prefs?.getBool(_keyPushNotifications) ?? true;
  bool get emailUpdates => _prefs?.getBool(_keyEmailUpdates) ?? false;

  Future<void> setPushNotifications(bool value) async {
    final prefs = await _getPrefs();
    await prefs.setBool(_keyPushNotifications, value);
  }

  Future<void> setEmailUpdates(bool value) async {
    final prefs = await _getPrefs();
    await prefs.setBool(_keyEmailUpdates, value);
  }

  // ============ Discover Settings ============

  static const String _keyVeganFirst = 'prefer_vegan_first';
  static const String _keyMaxDistance = 'max_distance_miles';

  bool get preferVeganFirst => _prefs?.getBool(_keyVeganFirst) ?? false;
  double get maxDistanceMiles => _prefs?.getDouble(_keyMaxDistance) ?? 5.0;

  Future<void> setPreferVeganFirst(bool value) async {
    final prefs = await _getPrefs();
    await prefs.setBool(_keyVeganFirst, value);
  }

  Future<void> setMaxDistanceMiles(double value) async {
    final prefs = await _getPrefs();
    await prefs.setDouble(_keyMaxDistance, value);
  }
}
