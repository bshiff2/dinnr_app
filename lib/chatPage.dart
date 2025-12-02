import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'home_page.dart';
import 'page_layout.dart';
import 'profile.dart';
import 'voice_mode_page.dart';
import 'services/ai_chat_service.dart';
import 'services/config_service.dart';
import 'services/location_service.dart';
import 'services/favorite_service.dart';
import 'components/restaurant_card.dart';

// Temporary main() for standalone testing - remove when integrating with main.dart
void main() {
  runApp(const TestApp());
}

class TestApp extends StatelessWidget {
  const TestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
      ),
      initialRoute: '/chat',
      routes: {
        '/home': (context) => HomePageUI(),
        '/chat': (context) => ChatOngoing(),
        '/profile': (context) => Profile(),
      },
    );
  }
}

class ChatOngoing extends StatefulWidget {
  const ChatOngoing({super.key});

  @override
  State<ChatOngoing> createState() => _ChatOngoingState();
}

class _ChatOngoingState extends State<ChatOngoing> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];

  late final AIChatService _aiService;
  late final LocationService _locationService;
  final FavoriteService _favoriteService = FavoriteService();
  StreamSubscription<User?>? _authSub;
  StreamSubscription<List<FavoriteRestaurant>>? _favoritesSub;
  Set<String> _favoriteKeys = {};
  bool _isSending = false;
  bool _isAudioMode = false; // Track if user used voice input
  String? _locationContext; // Cached location context

  @override
  void initState() {
    super.initState();
    final config = ConfigService();
    _aiService = AIChatService(
      apiKey: config.openAIKey,
      basePrompt: config.aiPrompt,
      model: config.aiModel,
    );
    _locationService = LocationService();
    if (config.googleApiKey != null) {
      _locationService.setApiKey(config.googleApiKey!);
    }
    _initLocation();
    _initAuthListener();
  }

  void _initLocation() async {
    // Get location context at startup
    _locationContext = await _locationService.getLocationContext();
    print('Location context: $_locationContext');
  }

  void _initAuthListener() {
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      _favoritesSub?.cancel();
      if (!mounted) return;

      setState(() {
        _favoriteKeys = {};
      });

      if (user != null) {
        _favoritesSub = _favoriteService.streamFavorites(user.uid).listen((favorites) {
          if (!mounted) return;
          setState(() {
            _favoriteKeys = favorites.map((f) => f.lookupKey).toSet();
          });
        });
      }
    });
  }

  void _openVoiceMode() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const VoiceModePage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  String _favoriteKeyFor(RestaurantData data) {
    return FavoriteRestaurant.buildLookupKey(
      placeId: data.placeId,
      name: data.name,
      address: data.address,
    );
  }

  User? _requireLogin() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Log in to save favorites.'),
          action: SnackBarAction(
            label: 'Log in',
            onPressed: () => Navigator.pushNamed(context, '/login'),
          ),
        ),
      );
    }
    return user;
  }

  Future<void> _saveRestaurantFromChat(RestaurantData data) async {
    final user = _requireLogin();
    if (user == null) return;

    final key = _favoriteKeyFor(data);
    if (_favoriteKeys.contains(key)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Already saved to favorites.')),
        );
      }
      return;
    }

    final favorite = FavoriteRestaurant(
      lookupKey: key,
      name: data.name,
      description: data.description,
      imageUrl: data.imageUrl,
      address: data.address,
      rating: data.rating,
      priceLabel: data.priceLevel,
      cuisine: data.cuisineType,
      placeId: data.placeId,
      source: 'chat',
    );

    try {
      await _favoriteService.saveFavorite(user.uid, favorite);
      if (!mounted) return;
      setState(() {
        _favoriteKeys.add(key);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved to favorites')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save: $e')),
      );
    }
  }

  Future<void> _sendMessage({bool useAudio = false}) async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    
    final shouldUseAudio = useAudio || _isAudioMode;
    _isAudioMode = false; // Reset audio mode
    
    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _isSending = true;
    });
    _scrollToBottom();

    final history = _messages
        .map(
          (msg) => AIChatMessage(
            role: msg.isUser ? 'user' : 'assistant',
            content: msg.text,
          ),
        )
        .toList();

    try {
      // Fetch nearby restaurants for better recommendations
      final lowerText = text.toLowerCase();
      String? cuisineKeyword;
      if (lowerText.contains('pizza')) cuisineKeyword = 'pizza';
      else if (lowerText.contains('burger')) cuisineKeyword = 'burger';
      else if (lowerText.contains('sushi') || lowerText.contains('japanese')) cuisineKeyword = 'sushi';
      else if (lowerText.contains('mexican') || lowerText.contains('taco')) cuisineKeyword = 'mexican';
      else if (lowerText.contains('chinese')) cuisineKeyword = 'chinese';
      else if (lowerText.contains('italian') || lowerText.contains('pasta')) cuisineKeyword = 'italian';
      else if (lowerText.contains('thai')) cuisineKeyword = 'thai';
      else if (lowerText.contains('indian')) cuisineKeyword = 'indian';
      else if (lowerText.contains('bbq') || lowerText.contains('barbecue')) cuisineKeyword = 'bbq';
      
      final nearbyPlaces = await _locationService.searchNearbyRestaurants(
        keyword: cuisineKeyword,
        radius: 5000,
      );
      
      final response = await _aiService.sendMessage(
        message: text,
        history: history,
        useAudio: shouldUseAudio,
        locationContext: _locationContext,
        nearbyPlaces: nearbyPlaces,
      );

      if (mounted) {
        setState(() {
          RestaurantData? restaurantData;
          
          // Parse restaurant data if available
          if (response.restaurantData != null) {
            try {
              restaurantData = RestaurantData.fromJson(response.restaurantData!);
            } catch (e) {
              // If parsing fails, just skip the restaurant card
            }
          }

          _messages.add(_ChatMessage(
            text: response.text,
            isUser: false,
            mood: response.mood,
            restaurantData: restaurantData,
          ));
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('AI error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        try {
          final max = _scrollController.position.maxScrollExtent;
          _scrollController.animateTo(
            max,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        } catch (_) {}
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _favoritesSub?.cancel();
    _authSub?.cancel();
    _aiService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageLayout(
      child: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? const Center(
                    child: Text(
                      'Start a conversation...',
                      style: TextStyle(color: Colors.white54),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      
                      // User message (right side)
                      if (msg.isUser) {
                        return Align(
                          alignment: Alignment.centerRight,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.green[400],
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(16),
                                topRight: Radius.circular(4),
                                bottomLeft: Radius.circular(16),
                                bottomRight: Radius.circular(16),
                              ),
                            ),
                            child: Text(
                              msg.text,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        );
                      }
                      
                      // AI message with Miku avatar (left side)
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _MikuAvatar(mood: msg.mood ?? MikuMood.neutral),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF2C2C2C),
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(4),
                                        topRight: Radius.circular(16),
                                        bottomLeft: Radius.circular(16),
                                        bottomRight: Radius.circular(16),
                                      ),
                                    ),
                                    child: Text(
                                      msg.text,
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  // Show restaurant card if available
                                  if (msg.restaurantData != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Builder(
                                        builder: (context) {
                                          final restaurant = msg.restaurantData!;
                                          final favoriteKey = _favoriteKeyFor(restaurant);
                                          return RestaurantCard(
                                            name: restaurant.name,
                                            description: restaurant.description,
                                            imageUrl: restaurant.imageUrl,
                                            address: restaurant.address,
                                            rating: restaurant.rating,
                                            priceLevel: restaurant.priceLevel,
                                            cuisineType: restaurant.cuisineType,
                                            onSave: () => _saveRestaurantFromChat(restaurant),
                                            isSaved: _favoriteKeys.contains(favoriteKey),
                                          );
                                        },
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              left: 12,
              right: 12,
              top: 8,
              bottom: 8 + MediaQuery.of(context).viewInsets.bottom,
            ),
            color: const Color(0xFF121212),
            child: SafeArea(
              child: Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: ShapeDecoration(
                  color: const Color(0xFF1E1E1E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        onSubmitted: (_) => _sendMessage(),
                        decoration: const InputDecoration(
                          hintText: 'Type to chat',
                          hintStyle: TextStyle(color: Colors.white54),
                          border: InputBorder.none,
                        ),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    IconButton(
                      onPressed: _openVoiceMode,
                      icon: const Icon(
                        Icons.mic_none,
                        color: Colors.white70,
                      ),
                    ),
                    IconButton(
                      onPressed: _isSending ? null : _sendMessage,
                      icon: _isSending
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Miku Avatar Widget ───────────────────────────────────────────────────────
class _MikuAvatar extends StatelessWidget {
  final MikuMood mood;
  
  const _MikuAvatar({required this.mood});
  
  // Asset path for bundled images
  String get _assetPath {
    switch (mood) {
      case MikuMood.happy:
        return 'lib/assets/miku/happy.jpg';
      case MikuMood.excited:
        return 'lib/assets/miku/excited.jpg';
      case MikuMood.thinking:
        return 'lib/assets/miku/thinking.jpg';
      case MikuMood.teaching:
        return 'lib/assets/miku/teaching.jpg';
      case MikuMood.love:
        return 'lib/assets/miku/love.jpg';
      case MikuMood.surprised:
        return 'lib/assets/miku/surprised.jpg';
      case MikuMood.confused:
        return 'lib/assets/miku/confused.jpg';
      case MikuMood.neutral:
        return 'lib/assets/miku/neutral.jpg';
    }
  }
  
  // Mood-specific colors for fallback avatar
  Color get _moodColor {
    switch (mood) {
      case MikuMood.happy:
        return Colors.teal.shade300;
      case MikuMood.excited:
        return Colors.orange.shade300;
      case MikuMood.thinking:
        return Colors.blue.shade300;
      case MikuMood.teaching:
        return Colors.purple.shade300;
      case MikuMood.love:
        return Colors.pink.shade300;
      case MikuMood.surprised:
        return Colors.yellow.shade300;
      case MikuMood.confused:
        return Colors.grey.shade400;
      case MikuMood.neutral:
        return Colors.cyan.shade300;
    }
  }
  
  String get _moodEmoji {
    switch (mood) {
      case MikuMood.happy: return '😊';
      case MikuMood.excited: return '🤩';
      case MikuMood.thinking: return '🤔';
      case MikuMood.teaching: return '📚';
      case MikuMood.love: return '💕';
      case MikuMood.surprised: return '😮';
      case MikuMood.confused: return '😕';
      case MikuMood.neutral: return '🎤';
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF2C2C2C),
        border: Border.all(color: _moodColor, width: 2),
      ),
      child: ClipOval(
        child: Image.asset(
          _assetPath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // Fallback to emoji with colored background
            return Container(
              color: _moodColor.withOpacity(0.2),
              child: Center(
                child: Text(
                  _moodEmoji,
                  style: const TextStyle(fontSize: 26),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ChatMessage {
  const _ChatMessage({
    required this.text,
    required this.isUser,
    this.mood,
    this.restaurantData,
  });

  final String text;
  final bool isUser;
  final MikuMood? mood;
  final RestaurantData? restaurantData;
}

/// Restaurant data model for embedded cards
class RestaurantData {
  const RestaurantData({
    required this.name,
    required this.description,
    required this.imageUrl,
    this.address,
    this.rating,
    this.priceLevel,
    this.cuisineType,
    this.placeId,
  });

  final String name;
  final String description;
  final String imageUrl;
  final String? address;
  final double? rating;
  final String? priceLevel;
  final String? cuisineType;
  final String? placeId;

  factory RestaurantData.fromJson(Map<String, dynamic> json) {
    return RestaurantData(
      name: json['name'] as String,
      description: json['description'] as String,
      imageUrl: json['imageUrl'] as String,
      address: json['address'] as String?,
      rating: json['rating'] != null ? (json['rating'] as num).toDouble() : null,
      priceLevel: json['priceLevel'] as String?,
      cuisineType: json['cuisineType'] as String?,
      placeId: json['placeId'] as String?,
    );
  }
}
