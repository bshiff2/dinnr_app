import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import 'home_page.dart';
import 'page_layout.dart';
import 'profile.dart';
import 'services/ai_chat_service.dart';
import 'services/config_service.dart';
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
  bool _isSending = false;

  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _speechAvailable = false;

  @override
  void initState() {
    super.initState();
    final config = ConfigService();
    _aiService = AIChatService(
      apiKey: config.openAIKey,
      basePrompt: config.aiPrompt,
      model: config.aiModel,
    );
    _speech = stt.SpeechToText();
    _initSpeech();
  }

  void _initSpeech() async {
    _speechAvailable = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' && _isListening) {
          setState(() => _isListening = false);
          _sendMessage();
        }
      },
      onError: (error) {
        setState(() => _isListening = false);
      },
    );
    setState(() {});
  }

  void _startListening() async {
    if (!_speechAvailable) return;

    setState(() => _isListening = true);
    _controller.clear();

    await _speech.listen(
      onResult: (result) {
        setState(() {
          _controller.text = result.recognizedWords;
        });
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      cancelOnError: true,
    );
  }

  void _stopListening() async {
    await _speech.stop();
    setState(() => _isListening = false);
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
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
      final response = await _aiService.sendMessage(
        message: text,
        history: history,
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
    _speech.cancel();
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
                      return Align(
                        alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: Column(
                          crossAxisAlignment: msg.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width * 0.75,
                              ),
                              decoration: BoxDecoration(
                                color: msg.isUser ? Colors.green[400] : const Color(0xFF2C2C2C),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(msg.isUser ? 16 : 4),
                                  topRight: Radius.circular(msg.isUser ? 4 : 16),
                                  bottomLeft: const Radius.circular(16),
                                  bottomRight: const Radius.circular(16),
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
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxWidth: MediaQuery.of(context).size.width * 0.85,
                                  ),
                                  child: RestaurantCard(
                                    name: msg.restaurantData!.name,
                                    description: msg.restaurantData!.description,
                                    imageUrl: msg.restaurantData!.imageUrl,
                                    address: msg.restaurantData!.address,
                                    rating: msg.restaurantData!.rating,
                                    priceLevel: msg.restaurantData!.priceLevel,
                                    cuisineType: msg.restaurantData!.cuisineType,
                                  ),
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
                      onPressed: _isListening ? _stopListening : _startListening,
                      icon: Icon(
                        _isListening ? Icons.mic : Icons.mic_none,
                        color: _isListening ? Colors.red : Colors.white70,
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

class _ChatMessage {
  const _ChatMessage({
    required this.text, 
    required this.isUser,
    this.restaurantData,
  });

  final String text;
  final bool isUser;
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
  });

  final String name;
  final String description;
  final String imageUrl;
  final String? address;
  final double? rating;
  final String? priceLevel;
  final String? cuisineType;

  factory RestaurantData.fromJson(Map<String, dynamic> json) {
    return RestaurantData(
      name: json['name'] as String,
      description: json['description'] as String,
      imageUrl: json['imageUrl'] as String,
      address: json['address'] as String?,
      rating: json['rating'] != null ? (json['rating'] as num).toDouble() : null,
      priceLevel: json['priceLevel'] as String?,
      cuisineType: json['cuisineType'] as String?,
    );
  }
}