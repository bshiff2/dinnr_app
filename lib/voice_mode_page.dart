import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

import 'discover.dart';
import 'services/openai_realtime_service.dart';
import 'services/config_service.dart';
import 'services/location_service.dart';
import 'services/settings_service.dart';

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

  /// Each personality has a distinct voice for Realtime API
  String get voiceName {
    switch (this) {
      case AIPersonality.witty:
        return 'alloy';   // More neutral/sophisticated tone
      case AIPersonality.spicy:
        return 'shimmer'; // More expressive/sultry
      case AIPersonality.bubbly:
        return 'nova';    // Warm and friendly
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
  OpenAIRealtimeService? _realtimeService;
  late LocationService _locationService;
  final _settingsService = SettingsService();
  
  // Personality selection
  AIPersonality? _selectedPersonality;
  bool _hasSelectedPersonality = false;
  
  bool _isListening = false;
  bool _isProcessing = false;
  bool _isPlayingAudio = false;
  bool _isConnected = false;
  bool _showSubtitles = true;
  String _recognizedText = '';
  String _aiResponseText = '';
  String _statusText = 'Tap to speak';
  String? _locationContext;
  
  // Restaurant recommendation
  String? _pendingRestaurantName;

  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late AnimationController _morphController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _waveAnimation;

  // Sound level for reactive animation
  double _soundLevel = 0.0;

  @override
  void initState() {
    super.initState();
    
    _locationService = LocationService();
    final config = ConfigService();
    if (config.googleApiKey != null) {
      _locationService.setApiKey(config.googleApiKey!);
    }
    
    _initAnimations();
    _initLocation();
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    await _settingsService.init();
    if (mounted) {
      setState(() {
        _showSubtitles = _settingsService.showSubtitles;
      });
    }
  }
  
  void _selectPersonality(AIPersonality personality) {
    final config = ConfigService();
    
    // Build instructions with personality and location context
    String instructions = '''${personality.voicePrompt}

You are also Dinnr, a foodie assistant that helps find restaurants. 
When asked about food or restaurants, give helpful recommendations.
Keep responses concise and conversational for voice.
${_locationContext != null ? '\nUser location context: $_locationContext' : ''}''';
    
    // Create Realtime API service with personality-specific voice
    _realtimeService = OpenAIRealtimeService(
      apiKey: config.openAIKey,
      voice: personality.voiceName,
      instructions: instructions,
    );
    
    // Set up callbacks
    _realtimeService!.onTranscript = (text) {
      if (mounted) {
        setState(() {
          _recognizedText = text;
        });
      }
    };
    
    _realtimeService!.onResponse = (text) {
      if (mounted) {
        setState(() {
          _aiResponseText += text;
        });
      }
    };
    
    _realtimeService!.onFullResponse = (fullText) {
      if (mounted) {
        // Extract restaurant name from the full response
        _extractRestaurantName(fullText);
      }
    };
    
    _realtimeService!.onAudioStart = () {
      if (mounted) {
        setState(() {
          _isPlayingAudio = true;
          _isProcessing = false;
          _statusText = 'Speaking...';
        });
      }
    };
    
    _realtimeService!.onResponseStart = () {
      if (mounted) {
        setState(() {
          _isListening = false;
          _isProcessing = true;
          _statusText = 'Processing...';
        });
      }
    };
    
    _realtimeService!.onAudioEnd = () {
      if (mounted) {
        setState(() {
          _isPlayingAudio = false;
          _isProcessing = false;
          _statusText = 'Tap to speak';
        });
      }
    };
    
    _realtimeService!.onInputLevel = (level) {
      if (mounted && _isListening) {
        setState(() {
          _soundLevel = level;
        });
      }
    };
    
    _realtimeService!.onError = (error) {
      if (mounted) {
        setState(() {
          _isListening = false;
          _isProcessing = false;
          _statusText = 'Error: $error';
        });
      }
    };
    
    setState(() {
      _selectedPersonality = personality;
      _hasSelectedPersonality = true;
    });
    
    // Connect to the Realtime API
    _connectToRealtime();
  }
  
  Future<void> _connectToRealtime() async {
    setState(() {
      _statusText = 'Connecting...';
    });
    
    await _realtimeService?.connect();
    
    if (mounted) {
      setState(() {
        _isConnected = _realtimeService?.isConnected ?? false;
        _statusText = _isConnected ? 'Tap to speak' : 'Connection failed';
      });
    }
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

  void _startListening() async {
    if (_isProcessing || _isPlayingAudio) return;
    
    if (!_isConnected) {
      await _connectToRealtime();
      if (!_isConnected) {
        setState(() {
          _statusText = 'Not connected. Tap to retry.';
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

    await _realtimeService?.startRecording();
  }

  void _stopListening() async {
    if (!_isListening) return;
    
    setState(() {
      _isListening = false;
      _isProcessing = true;
      _statusText = 'Processing...';
    });

    await _realtimeService?.stopRecording();
  }

  void _onBubbleTap() {
    if (_isListening) {
      _stopListening();
    } else if (_isPlayingAudio || _isProcessing) {
      // Allow interrupting the AI - stop audio and start listening
      _stopAudioAndListen();
    } else {
      _startListening();
    }
  }
  
  void _stopAudioAndListen() async {
    await _realtimeService?.stopAudio();
    if (mounted) {
      setState(() {
        _isPlayingAudio = false;
        _isProcessing = false;
      });
      // Immediately start listening after interrupting
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
  
  void _extractRestaurantName(String text) {
    debugPrint('Extracting restaurant from: $text');
    
    // Common patterns for restaurant recommendations
    final patterns = [
      // "check out [Name]" or "try [Name]" - capture what comes AFTER the verb
      RegExp(r"(?:check out|try|visit|go to|recommend)\s+([A-Z][a-zA-Z']+(?:\s+[A-Z][a-zA-Z']+){0,3})(?:\s*[,.]|\s+(?:for|where|and|or|if|they|it|—|-)|\s*$)", caseSensitive: false),
      // Names ending with "Café", "Coffee", "Restaurant", "Pizza", etc.
      RegExp(r"\b([A-Z][a-zA-Z']+(?:\s+[A-Z][a-zA-Z']+)*\s*(?:Café|Cafe|Coffee|Restaurant|Kitchen|Grill|Bistro|Diner|Bar|House|Truck|Bakery|Pizza|Pizzeria))\b", caseSensitive: false),
      // "CC's" or "Name's" style names with optional suffix
      RegExp(r"\b([A-Z]+[a-z]*'s(?:\s+[A-Z][a-zA-Z]+)*(?:\s+(?:Coffee|House|Kitchen|Place|Cafe|Bar))?)\b", caseSensitive: false),
      // Known local patterns: Magpie Cafe, French Truck, etc.
      RegExp(r"\b((?:Magpie|French\s+Truck|Highland|Brew\s+Ha-Ha|Light\s*House|Red\s+Zeppelin)\s*(?:[A-Z][a-zA-Z]+)?)\b", caseSensitive: false),
    ];
    
    String? foundRestaurant;
    
    for (int i = 0; i < patterns.length; i++) {
      final pattern = patterns[i];
      final matches = pattern.allMatches(text);
      for (final match in matches) {
        if (match.group(1) != null) {
          String candidate = match.group(1)!.trim();
          // Clean up the name
          candidate = candidate
              .replaceAll(RegExp(r'\s+'), ' ')
              .replaceAll(RegExp(r'[,.\-—]+$'), '')
              .trim();
          debugPrint('Pattern $i found candidate: "$candidate"');
          // Make sure it's a reasonable restaurant name (3-40 chars, not common words)
          final lowerCandidate = candidate.toLowerCase();
          final excludeWords = ['the', 'a', 'an', 'for', 'and', 'or', 'is', 'are', 'ready', 'let', 'sounds', 'like', 'great', 'perfect', 'try', 'check', 'visit', 'go'];
          if (candidate.length >= 3 && 
              candidate.length <= 40 &&
              !excludeWords.contains(lowerCandidate) &&
              !lowerCandidate.startsWith('try ') &&
              !lowerCandidate.startsWith('check ') &&
              !lowerCandidate.startsWith('visit ') &&
              !lowerCandidate.startsWith('ready ') &&
              !lowerCandidate.startsWith('let ')) {
            foundRestaurant = candidate;
            break;
          }
        }
      }
      if (foundRestaurant != null) break;
    }
    
    if (foundRestaurant != null) {
      setState(() {
        _pendingRestaurantName = foundRestaurant;
      });
      debugPrint('✓ Extracted restaurant: $foundRestaurant');
    } else {
      debugPrint('✗ No restaurant found in response');
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    _morphController.dispose();
    _realtimeService?.dispose();
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

                  // Recognized text or AI response (only if subtitles enabled)
                  if (_showSubtitles)
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
                            fontStyle: _isPlayingAudio ? FontStyle.normal : FontStyle.normal,
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
