import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

void main() {
  runApp(const FigmaToCodeApp());
}

class FigmaToCodeApp extends StatelessWidget {
  const FigmaToCodeApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color.fromARGB(255, 18, 32, 47),
      ),
      initialRoute: '/chat',
      routes: {
        '/': (context) => Scaffold(
          body: Center(child: Text('Main Page - Import your main.dart content here')),
        ),
        '/chat': (context) => Scaffold(
          body: ChatOngoing(),
        ),
        '/profile': (context) => Scaffold(
          body: Center(child: Text('Profile Page - Import your profile.dart content here')),
        ),
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
  final List<String> _messages = [];
  
  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _speechAvailable = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initSpeech();
  }

  void _initSpeech() async {
    _speechAvailable = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' && _isListening) {
          // User stopped speaking, auto-send
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

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    
    setState(() {
      _messages.add(text);
    });
    _controller.clear();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        try {
          final max = _scrollController.position.maxScrollExtent;
          _scrollController.animateTo(
            max,
            duration: const Duration(milliseconds: 200),
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF121212),
      child: Container(
        width: double.infinity,
        height: MediaQuery.of(context).size.height,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(color: const Color(0xFF121212)),
        child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            right: 0,
            bottom: 140,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  child: _messages.isEmpty
                      ? const SingleChildScrollView(
                          child: SizedBox.shrink(),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final msg = _messages[index];
                            return Align(
                              alignment: Alignment.topRight,
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.green[400],
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(16),
                                    topRight: Radius.circular(16),
                                    bottomLeft: Radius.circular(16),
                                    bottomRight: Radius.circular(4),
                                  ),
                                ),
                                child: Text(
                                  msg,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ),
              Positioned(
                left: 0,
                top: 712,
                child: Container(
                  width: 393,
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 56,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 500),
                          child: Container(
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
                                // Voice input button
                                IconButton(
                                  onPressed: _isListening ? _stopListening : _startListening,
                                  icon: Icon(
                                    _isListening ? Icons.mic : Icons.mic_none,
                                    color: _isListening ? Colors.red : Colors.white70,
                                  ),
                                ),
                                IconButton(
                                  onPressed: _sendMessage,
                                  icon: const Icon(Icons.send, color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        height: 67,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 500),
                              child: Container(
                                width: double.infinity,
                                height: 67,
                                decoration: ShapeDecoration(
                                  color: const Color(0xCC222222),
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(20),
                                      topRight: Radius.circular(20),
                                    ),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    // Home button
                                    IconButton(
                                      onPressed: () {
                                        Navigator.pushReplacementNamed(context, '/');
                                      },
                                      icon: Icon(
                                        Icons.home,
                                        color: Colors.white38,
                                        size: 28,
                                      ),
                                    ),
                                    // Chat button (current page)
                                    IconButton(
                                      onPressed: () {},
                                      icon: Icon(
                                        Icons.chat_bubble,
                                        color: Colors.white,
                                        size: 28,
                                      ),
                                    ),
                                    // Profile button
                                    IconButton(
                                      onPressed: () {
                                        Navigator.pushReplacementNamed(context, '/profile');
                                      },
                                      icon: Icon(
                                        Icons.person,
                                        color: Colors.white38,
                                        size: 28,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
    );
  }
}