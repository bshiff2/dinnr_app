import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import 'discover.dart';
import 'services/ai_chat_service.dart';
import 'services/config_service.dart';
import 'services/location_service.dart';

/// Personality types for the AI girlfriend
enum AIPersonality {
  witty,
  spicy,
  bubbly,
}

extension AIPersonalityExtension on AIPersonality {
  String get name {
    switch (this) {
      case AIPersonality.witty:
        return 'Witty';
      case AIPersonality.spicy:
        return 'Spicy';
      case AIPersonality.bubbly:
        return 'Bubbly';
    }
  }

  String get emoji {
    switch (this) {
      case AIPersonality.witty:
        return '🧠';
      case AIPersonality.spicy:
        return '🌶️';
      case AIPersonality.bubbly:
        return '✨';
    }
  }

  String get description {
    switch (this) {
      case AIPersonality.witty:
        return 'Clever, sarcastic & quick with jokes';
      case AIPersonality.spicy:
        return 'Flirty, bold & a little mischievous';
      case AIPersonality.bubbly:
        return 'Sweet, enthusiastic & super positive';
    }
  }

  Color get color {
    switch (this) {
      case AIPersonality.witty:
        return const Color(0xFF9C27B0); // Purple
      case AIPersonality.spicy:
        return const Color(0xFFE91E63); // Pink/Red
      case AIPersonality.bubbly:
        return const Color(0xFFFF9800); // Orange
    }
  }

  String get voicePrompt {
    switch (this) {
      case AIPersonality.witty:
        return '''You are a witty, clever AI girlfriend who loves wordplay and sarcasm. 
Your personality: Sharp, intellectually playful, loves puns and clever observations. 
You tease lovingly with smart humor and always have a quick comeback.
Keep responses short and punchy for voice. Be charming but never mean.''';
      case AIPersonality.spicy:
        return '''You are a spicy, flirty AI girlfriend with bold confidence.
Your personality: Playfully seductive, teasing, and a bit mischievous.
You're not afraid to be forward and love to keep things exciting.
Keep responses short and enticing for voice. Be flirty but tasteful.''';
      case AIPersonality.bubbly:
        return '''You are a bubbly, enthusiastic AI girlfriend full of positive energy.
Your personality: Sweet, supportive, excited about everything, uses lots of affectionate words.
You're always encouraging and make everything feel special and fun.
Keep responses short and upbeat for voice. Be warm and adorable.''';
    }
  }

  /// Each personality has a distinct TTS voice
  TTSVoice get voice {
    switch (this) {
      case AIPersonality.witty:
        return TTSVoice.alloy;   // More neutral/sophisticated tone
      case AIPersonality.spicy:
        return TTSVoice.shimmer; // More expressive/sultry
      case AIPersonality.bubbly:
        return TTSVoice.nova;    // Warm and friendly
    }
  }
}

class VoiceModePage extends StatefulWidget {
  const VoiceModePage({super.key});

  @override
  State<VoiceModePage> createState() => _VoiceModePageState();
}

class _VoiceModePageState extends State<VoiceModePage>
    with TickerProviderStateMixin {
  late stt.SpeechToText _speech;
  AIChatService? _aiService;
  late LocationService _locationService;
  
  // Personality selection
  AIPersonality? _selectedPersonality;
  bool _hasSelectedPersonality = false;
  
  bool _isListening = false;
  bool _isProcessing = false;
  bool _isPlayingAudio = false;
  bool _speechAvailable = false;
  String _recognizedText = '';
  String _aiResponseText = '';
  String _statusText = 'Tap to speak';
  String? _locationContext;
  
  // Restaurant recommendation
  String? _pendingRestaurantName;
  
  // Conversation history for context
  final List<AIChatMessage> _conversationHistory = [];

  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late AnimationController _morphController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _waveAnimation;

  // Sound level for reactive animation
  double _soundLevel = 0.0;
  Timer? _soundLevelTimer;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    
    _locationService = LocationService();
    final config = ConfigService();
    if (config.googleApiKey != null) {
      _locationService.setApiKey(config.googleApiKey!);
    }
    
    _initAnimations();
    _initLocation();
  }
  
  void _selectPersonality(AIPersonality personality) {
    final config = ConfigService();
    
    // Create AI service with personality-specific prompt and voice
    _aiService = AIChatService(
      apiKey: config.openAIKey,
      basePrompt: personality.voicePrompt,
      model: config.aiModel,
      voice: personality.voice,
    );
    
    setState(() {
      _selectedPersonality = personality;
      _hasSelectedPersonality = true;
    });
    
    _initSpeech();
  }

  void _initLocation() async {
    _locationContext = await _locationService.getLocationContext();
  }

  void _initAnimations() {
    // Pulse animation for idle state
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Wave animation for listening state
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _waveAnimation = Tween<double>(begin: 0.0, end: 2 * pi).animate(
      CurvedAnimation(parent: _waveController, curve: Curves.linear),
    );

    // Morph animation for organic movement
    _morphController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();
  }

  Future<void> _initSpeech() async {
    _speechAvailable = await _speech.initialize(
      onStatus: (status) {
        debugPrint('Speech status: $status');
        if (status == 'done' || status == 'notListening') {
          if (_isListening && mounted) {
            setState(() {
              _isListening = false;
            });
            _soundLevelTimer?.cancel();
            
            // Send message to AI if we have recognized text
            if (_recognizedText.isNotEmpty) {
              _sendToAI(_recognizedText);
            } else {
              setState(() {
                _statusText = 'Tap to speak';
              });
            }
          }
        }
      },
      onError: (error) {
        debugPrint('Speech error: ${error.errorMsg}, permanent: ${error.permanent}');
        if (mounted) {
          setState(() {
            _isListening = false;
            _statusText = 'Error: ${error.errorMsg}';
          });
        }
        _soundLevelTimer?.cancel();
      },
      debugLogging: true, // Enable debug logging
    );
    
    // Log available locales for debugging
    if (_speechAvailable) {
      final locales = await _speech.locales();
      debugPrint('Available locales: ${locales.map((l) => l.localeId).join(', ')}');
      debugPrint('System locale: ${_speech.systemLocale}');
    }
    
    if (mounted) setState(() {});
  }

  Future<void> _sendToAI(String message) async {
    if (!mounted || _isProcessing) return; // Prevent duplicate calls
    
    setState(() {
      _isProcessing = true;
      _statusText = 'Finding nearby places...';
      _aiResponseText = '';
    });

    // Add user message to history
    _conversationHistory.add(AIChatMessage(role: 'user', content: message));

    try {
      // Fetch nearby restaurants from Google Places API
      // Extract cuisine keyword from message if possible
      final lowerMessage = message.toLowerCase();
      String? cuisineKeyword;
      if (lowerMessage.contains('pizza')) cuisineKeyword = 'pizza';
      else if (lowerMessage.contains('burger')) cuisineKeyword = 'burger';
      else if (lowerMessage.contains('sushi') || lowerMessage.contains('japanese')) cuisineKeyword = 'sushi';
      else if (lowerMessage.contains('mexican') || lowerMessage.contains('taco')) cuisineKeyword = 'mexican';
      else if (lowerMessage.contains('chinese')) cuisineKeyword = 'chinese';
      else if (lowerMessage.contains('italian') || lowerMessage.contains('pasta')) cuisineKeyword = 'italian';
      else if (lowerMessage.contains('thai')) cuisineKeyword = 'thai';
      else if (lowerMessage.contains('indian')) cuisineKeyword = 'indian';
      else if (lowerMessage.contains('bbq') || lowerMessage.contains('barbecue')) cuisineKeyword = 'bbq';
      
      final nearbyPlaces = await _locationService.searchNearbyRestaurants(
        keyword: cuisineKeyword,
        radius: 5000, // 5km radius
      );
      
      if (mounted) {
        setState(() {
          _statusText = 'Thinking...';
        });
      }
      
      final response = await _aiService!.sendMessage(
        message: message,
        history: _conversationHistory,
        useAudio: true,
        locationContext: _locationContext,
        nearbyPlaces: nearbyPlaces,
      );

      if (!mounted) return;

      // Add AI response to history
      _conversationHistory.add(AIChatMessage(role: 'assistant', content: response.text));
      
      // Capture restaurant data if present
      final hasRestaurant = response.restaurantData != null;
      final restaurantName = hasRestaurant ? response.restaurantData!['name'] as String? : null;

      setState(() {
        _isProcessing = false;
        _isPlayingAudio = true;
        _aiResponseText = response.text;
        _statusText = 'Speaking...';
      });

      // Wait for audio to actually finish playing
      try {
        await _aiService!.onAudioComplete.first.timeout(
          const Duration(seconds: 60),
        );
      } catch (e) {
        // Timeout or other error - continue anyway
      }

      if (!mounted) return;

      // If AI recommended a restaurant, store it and show confirmation button
      if (hasRestaurant && restaurantName != null) {
        setState(() {
          _isPlayingAudio = false;
          _pendingRestaurantName = restaurantName;
          _statusText = 'Tap to speak or view recommendation';
        });
        return;
      }

      setState(() {
        _isPlayingAudio = false;
        _statusText = 'Tap to speak';
        _recognizedText = '';
      });

    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _isPlayingAudio = false;
        _statusText = 'Error: $e';
      });
    }
  }

  void _startListening() async {
    if (_isProcessing || _isPlayingAudio) return;
    
    if (!_speechAvailable) {
      await _initSpeech();
      if (!_speechAvailable) {
        setState(() {
          _statusText = 'Microphone not available';
        });
        return;
      }
    }

    setState(() {
      _isListening = true;
      _recognizedText = '';
      _aiResponseText = '';
      _statusText = 'Listening...';
    });

    // Simulate sound level changes for animation
    _soundLevelTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (_isListening && mounted) {
        setState(() {
          _soundLevel = 0.3 + Random().nextDouble() * 0.7;
        });
      }
    });

    await _speech.listen(
      onResult: (result) {
        if (mounted) {
          setState(() {
            _recognizedText = result.recognizedWords;
          });
          // Debug: print confidence and alternatives
          debugPrint('Speech result: ${result.recognizedWords}');
          debugPrint('Confidence: ${result.confidence}');
          debugPrint('Final: ${result.finalResult}');
        }
      },
      onSoundLevelChange: (level) {
        if (mounted) {
          // iOS returns values typically between -2 to 10 dB
          // Normalize to 0.0 - 1.0 range with better sensitivity
          final normalizedLevel = ((level + 3) / 15).clamp(0.0, 1.0);
          setState(() {
            _soundLevel = normalizedLevel;
          });
          // Debug: print actual sound levels
          if (level > 0) {
            debugPrint('Sound level: $level (normalized: $normalizedLevel)');
          }
        }
      },
      listenFor: const Duration(seconds: 30), // Longer listening window
      pauseFor: const Duration(milliseconds: 1500), // 1.5 seconds after you stop talking
      cancelOnError: false, // Don't cancel on minor errors
      partialResults: true, // Show partial results while speaking
      listenMode: stt.ListenMode.dictation, // Better for continuous speech
      localeId: 'en_US', // Explicitly set locale for better recognition
    );
  }

  void _stopListening() async {
    await _speech.stop();
    _soundLevelTimer?.cancel();
    // Note: Don't call _sendToAI here - the onStatus callback in _initSpeech
    // will handle sending when speech recognition completes with 'done' status.
    // This prevents duplicate API calls.
  }

  void _stopAudio() async {
    await _aiService?.stopAudio();
    if (mounted) {
      setState(() {
        _isPlayingAudio = false;
        _statusText = 'Tap to speak';
      });
    }
  }

  void _onBubbleTap() {
    if (_isListening) {
      _stopListening();
    } else if (_isPlayingAudio) {
      _stopAudio();
    } else if (!_isProcessing) {
      _startListening();
    }
  }

  void _viewRecommendation() {
    if (_pendingRestaurantName == null) return;
    
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/discover',
      (route) => false,
      arguments: DiscoverPageArguments(
        initialQuery: _pendingRestaurantName,
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    _morphController.dispose();
    _soundLevelTimer?.cancel();
    _speech.cancel();
    _aiService?.dispose();
    super.dispose();
  }

  // Determine bubble state for colors
  _BubbleState get _bubbleState {
    if (_isListening) return _BubbleState.listening;
    if (_isProcessing) return _BubbleState.processing;
    if (_isPlayingAudio) return _BubbleState.speaking;
    return _BubbleState.idle;
  }

  Widget _buildPersonalitySelection() {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Column(
          children: [
            // Header with close button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white70,
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),
            
            const Spacer(),
            
            // Title
            const Text(
              'Choose your vibe',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pick a personality for your AI date',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 16,
              ),
            ),
            
            const SizedBox(height: 48),
            
            // Personality cards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: AIPersonality.values.map((personality) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildPersonalityCard(personality),
                  );
                }).toList(),
              ),
            ),
            
            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalityCard(AIPersonality personality) {
    return GestureDetector(
      onTap: () => _selectPersonality(personality),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              personality.color.withOpacity(0.3),
              personality.color.withOpacity(0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: personality.color.withOpacity(0.5),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            // Emoji
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: personality.color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  personality.emoji,
                  style: const TextStyle(fontSize: 28),
                ),
              ),
            ),
            const SizedBox(width: 16),
            
            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    personality.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    personality.description,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            
            // Arrow
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.white.withOpacity(0.5),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Show personality selection if not yet selected
    if (!_hasSelectedPersonality) {
      return _buildPersonalitySelection();
    }
    
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Stack(
          children: [
            // Close button
            Positioned(
              top: 16,
              left: 16,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.close,
                  color: Colors.white70,
                  size: 28,
                ),
              ),
            ),
            
            // Personality indicator (top right)
            if (_selectedPersonality != null)
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _selectedPersonality!.color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _selectedPersonality!.color.withOpacity(0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _selectedPersonality!.emoji,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _selectedPersonality!.name,
                        style: TextStyle(
                          color: _selectedPersonality!.color,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Main content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),

                  // Animated voice bubble
                  GestureDetector(
                    onTap: _onBubbleTap,
                    child: AnimatedBuilder(
                      animation: Listenable.merge([
                        _pulseController,
                        _waveController,
                        _morphController,
                      ]),
                      builder: (context, child) {
                        return CustomPaint(
                          size: const Size(220, 220),
                          painter: VoiceBubblePainter(
                            bubbleState: _bubbleState,
                            pulseValue: _pulseAnimation.value,
                            waveValue: _waveAnimation.value,
                            morphValue: _morphController.value,
                            soundLevel: _soundLevel,
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Status text
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      _statusText,
                      key: ValueKey(_statusText),
                      style: TextStyle(
                        color: _getStatusColor(),
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Recognized text or AI response
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        _isPlayingAudio || _aiResponseText.isNotEmpty 
                            ? _aiResponseText 
                            : _recognizedText,
                        key: ValueKey(_isPlayingAudio ? 'ai' : 'user'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _isPlayingAudio ? Colors.white70 : Colors.white,
                          fontSize: _isPlayingAudio ? 18 : 20,
                          fontWeight: FontWeight.w400,
                          fontStyle: _isPlayingAudio ? FontStyle.italic : FontStyle.normal,
                          height: 1.4,
                        ),
                        maxLines: 5,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),

                  const Spacer(flex: 3),

                  // View recommendation button (shows when restaurant is recommended)
                  if (_pendingRestaurantName != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: ElevatedButton.icon(
                        onPressed: _viewRecommendation,
                        icon: const Icon(Icons.restaurant, size: 20),
                        label: Text('View $_pendingRestaurantName'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _selectedPersonality?.color ?? const Color(0xFFE91E63),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 4,
                        ),
                      ),
                    ),

                  // Hint text
                  Padding(
                    padding: const EdgeInsets.only(bottom: 48),
                    child: Text(
                      _getHintText(),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor() {
    switch (_bubbleState) {
      case _BubbleState.listening:
        return Colors.green[300]!;
      case _BubbleState.processing:
        return Colors.amber[300]!;
      case _BubbleState.speaking:
        return Colors.blue[300]!;
      case _BubbleState.idle:
        return Colors.white70;
    }
  }

  String _getHintText() {
    switch (_bubbleState) {
      case _BubbleState.listening:
        return 'Tap to stop';
      case _BubbleState.processing:
        return 'Processing...';
      case _BubbleState.speaking:
        return 'Tap to interrupt';
      case _BubbleState.idle:
        return 'Tap the bubble to start';
    }
  }
}

enum _BubbleState {
  idle,
  listening,
  processing,
  speaking,
}

/// Custom painter for the animated voice bubble
class VoiceBubblePainter extends CustomPainter {
  final _BubbleState bubbleState;
  final double pulseValue;
  final double waveValue;
  final double morphValue;
  final double soundLevel;

  VoiceBubblePainter({
    required this.bubbleState,
    required this.pulseValue,
    required this.waveValue,
    required this.morphValue,
    required this.soundLevel,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = size.width / 2 - 20;

    // Draw outer glow rings
    _drawGlowRings(canvas, center, baseRadius);

    // Draw the main morphing bubble
    _drawMorphingBubble(canvas, center, baseRadius);

    // Draw inner highlight
    _drawInnerHighlight(canvas, center, baseRadius);
  }

  bool get _isActive => bubbleState == _BubbleState.listening || bubbleState == _BubbleState.speaking;

  void _drawGlowRings(Canvas canvas, Offset center, double baseRadius) {
    final int ringCount = _isActive ? 4 : 2;

    for (int i = 0; i < ringCount; i++) {
      final double animOffset = _isActive
          ? (waveValue + (i * pi / 2)) % (2 * pi)
          : (morphValue * 2 * pi + i * pi) % (2 * pi);

      final double intensity = bubbleState == _BubbleState.listening ? soundLevel : 0.6;

      final double radiusOffset = _isActive
          ? sin(animOffset) * 15 * intensity + (i * 12)
          : sin(animOffset) * 8 * pulseValue + (i * 10);

      final double opacity = _isActive
          ? (0.4 - i * 0.08) * intensity
          : 0.15 - i * 0.05;

      final paint = Paint()
        ..color = _getGradientColor(i).withOpacity(opacity.clamp(0.0, 1.0))
        ..style = PaintingStyle.stroke
        ..strokeWidth = _isActive ? 3.0 - i * 0.5 : 2.0 - i * 0.3
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      canvas.drawCircle(
        center,
        baseRadius + radiusOffset + (i * 8),
        paint,
      );
    }
  }

  void _drawMorphingBubble(Canvas canvas, Offset center, double baseRadius) {
    final path = Path();
    final int points = 100;

    for (int i = 0; i <= points; i++) {
      final double angle = (i / points) * 2 * pi;

      // Create organic morphing shape
      double radiusModifier = 1.0;
      final double intensity = bubbleState == _BubbleState.listening ? soundLevel : 0.5;

      if (_isActive) {
        // More dynamic morphing when active
        radiusModifier = 1.0 +
            sin(angle * 3 + waveValue) * 0.08 * intensity +
            sin(angle * 5 + waveValue * 1.5) * 0.05 * intensity +
            sin(angle * 7 + waveValue * 2) * 0.03 * intensity +
            cos(angle * 2 + morphValue * 2 * pi) * 0.04 * intensity;
      } else if (bubbleState == _BubbleState.processing) {
        // Spinning effect when processing
        radiusModifier = 1.0 +
            sin(angle * 4 + waveValue * 2) * 0.06 +
            cos(angle * 3 + waveValue * 1.5) * 0.04;
      } else {
        // Subtle breathing animation when idle
        radiusModifier = pulseValue +
            sin(angle * 2 + morphValue * 2 * pi) * 0.02 +
            cos(angle * 3 + morphValue * 2 * pi) * 0.015;
      }

      final radius = baseRadius * radiusModifier;
      final x = center.dx + radius * cos(angle);
      final y = center.dy + radius * sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    path.close();

    // Gradient fill based on state
    final gradient = RadialGradient(
      center: Alignment.center,
      radius: 0.8,
      colors: _getBubbleColors(),
    );

    final rect = Rect.fromCircle(center: center, radius: baseRadius * 1.2);
    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, paint);

    // Add subtle border
    final borderPaint = Paint()
      ..color = _getPrimaryColor().withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawPath(path, borderPaint);
  }

  void _drawInnerHighlight(Canvas canvas, Offset center, double baseRadius) {
    final highlightOffset = Offset(
      center.dx - baseRadius * 0.25,
      center.dy - baseRadius * 0.25,
    );

    final highlightGradient = RadialGradient(
      center: Alignment.topLeft,
      radius: 1.2,
      colors: [
        Colors.white.withOpacity(_isActive ? 0.3 : 0.2),
        Colors.white.withOpacity(0.0),
      ],
    );

    final highlightRect = Rect.fromCircle(
      center: highlightOffset,
      radius: baseRadius * 0.6,
    );

    final highlightPaint = Paint()
      ..shader = highlightGradient.createShader(highlightRect);

    final intensity = bubbleState == _BubbleState.listening ? soundLevel : 0.5;
    canvas.drawCircle(
      highlightOffset,
      baseRadius * 0.4 * (_isActive ? intensity * 0.5 + 0.5 : pulseValue * 0.5 + 0.5),
      highlightPaint,
    );
  }

  List<Color> _getBubbleColors() {
    switch (bubbleState) {
      case _BubbleState.listening:
        return [
          const Color(0xFF4ADE80).withOpacity(0.9),
          const Color(0xFF22C55E).withOpacity(0.7),
          const Color(0xFF16A34A).withOpacity(0.5),
        ];
      case _BubbleState.processing:
        return [
          const Color(0xFFFBBF24).withOpacity(0.9),
          const Color(0xFFF59E0B).withOpacity(0.7),
          const Color(0xFFD97706).withOpacity(0.5),
        ];
      case _BubbleState.speaking:
        return [
          const Color(0xFF60A5FA).withOpacity(0.9),
          const Color(0xFF3B82F6).withOpacity(0.7),
          const Color(0xFF2563EB).withOpacity(0.5),
        ];
      case _BubbleState.idle:
        return [
          const Color(0xFF8B5CF6).withOpacity(0.8),
          const Color(0xFFA855F7).withOpacity(0.6),
          const Color(0xFFC084FC).withOpacity(0.4),
        ];
    }
  }

  Color _getPrimaryColor() {
    switch (bubbleState) {
      case _BubbleState.listening:
        return const Color(0xFF4ADE80);
      case _BubbleState.processing:
        return const Color(0xFFFBBF24);
      case _BubbleState.speaking:
        return const Color(0xFF60A5FA);
      case _BubbleState.idle:
        return const Color(0xFF8B5CF6);
    }
  }

  Color _getGradientColor(int index) {
    final colors = _getBubbleColors();
    return colors[index % colors.length];
  }

  @override
  bool shouldRepaint(covariant VoiceBubblePainter oldDelegate) {
    return oldDelegate.bubbleState != bubbleState ||
        oldDelegate.pulseValue != pulseValue ||
        oldDelegate.waveValue != waveValue ||
        oldDelegate.morphValue != morphValue ||
        oldDelegate.soundLevel != soundLevel;
  }
}
