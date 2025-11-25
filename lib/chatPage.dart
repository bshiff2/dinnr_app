import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import 'home_page.dart';
import 'page_layout.dart';
import 'profile.dart';
import 'services/ai_chat_service.dart';
import 'services/config_service.dart';
import 'services/location_service.dart';

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
  bool _isSending = false;
  bool _isAudioMode = false; // Track if user used voice input
  String? _locationContext; // Cached location context

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
    _locationService = LocationService();
    if (config.googleApiKey != null) {
      _locationService.setApiKey(config.googleApiKey!);
    }
    _speech = stt.SpeechToText();
    _initSpeech();
    _initLocation();
  }

  void _initLocation() async {
    // Get location context at startup
    _locationContext = await _locationService.getLocationContext();
    print('Location context: $_locationContext');
  }

  void _initSpeech() async {
    _speechAvailable = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' && _isListening) {
          setState(() => _isListening = false);
          _sendMessage(useAudio: true); // Use audio mode when voice input ends
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

    setState(() {
      _isListening = true;
      _isAudioMode = true; // Mark as audio mode
    });
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
      final response = await _aiService.sendMessage(
        message: text,
        history: history,
        useAudio: shouldUseAudio,
        locationContext: _locationContext,
      );

      if (mounted) {
        setState(() {
          _messages.add(_ChatMessage(
            text: response.text,
            isUser: false,
            mood: response.mood,
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
                              child: Container(
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
    this.mood,
  });

  final String text;
  final bool isUser;
  final MikuMood? mood; // Mood for AI messages
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