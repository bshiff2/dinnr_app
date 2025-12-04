import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

/// OpenAI Realtime API Service for voice-to-voice conversations
/// Uses WebSocket for bidirectional audio streaming
class OpenAIRealtimeService {
  final String apiKey;
  final String model;
  final String voice;
  final String instructions;
  
  WebSocketChannel? _channel;
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  bool _isConnected = false;
  bool _isRecording = false;
  bool _isPlaying = false;
  bool _isResponding = false;
  
  // Audio buffer for playback
  final List<int> _audioBuffer = [];
  Timer? _audioBufferTimer;
  String? _tempAudioPath;
  
  // Callbacks
  Function(String text)? onTranscript;
  Function(String text)? onResponse;
  Function(String fullText)? onFullResponse;  // Called with complete response transcript
  Function(String error)? onError;
  Function()? onResponseStart;
  Function()? onAudioStart;
  Function()? onAudioEnd;
  Function(double level)? onInputLevel;
  
  // Stream subscriptions
  StreamSubscription? _recordingSubscription;
  StreamSubscription? _amplitudeSubscription;

  OpenAIRealtimeService({
    required this.apiKey,
    this.model = 'gpt-4o-realtime-preview-2024-12-17',
    this.voice = 'nova',
    this.instructions = 'You are a helpful food and restaurant assistant. Keep responses concise and conversational.',
  });

  bool get isConnected => _isConnected;
  bool get isRecording => _isRecording;
  bool get isPlaying => _isPlaying;
  bool get isResponding => _isResponding;

  /// Connect to the Realtime API WebSocket
  Future<void> connect() async {
    if (_isConnected) return;

    try {
      final uri = Uri.parse(
        'wss://api.openai.com/v1/realtime?model=$model',
      );

      _channel = WebSocketChannel.connect(
        uri,
        protocols: ['realtime', 'openai-insecure-api-key.$apiKey', 'openai-beta.realtime-v1'],
      );

      // Wait for connection
      await _channel!.ready;
      _isConnected = true;
      debugPrint('Realtime API connected');

      // Configure the session
      _sendSessionUpdate();

      // Listen for messages
      _channel!.stream.listen(
        _handleMessage,
        onError: (error) {
          debugPrint('WebSocket error: $error');
          onError?.call('Connection error: $error');
          _isConnected = false;
        },
        onDone: () {
          debugPrint('WebSocket closed');
          _isConnected = false;
        },
      );
    } catch (e) {
      debugPrint('Failed to connect: $e');
      onError?.call('Failed to connect: $e');
      _isConnected = false;
    }
  }

  /// Send session configuration
  void _sendSessionUpdate() {
    _sendEvent({
      'type': 'session.update',
      'session': {
        'modalities': ['text', 'audio'],
        'instructions': instructions,
        'voice': voice,
        'input_audio_format': 'pcm16',
        'output_audio_format': 'pcm16',
        'input_audio_transcription': {
          'model': 'whisper-1',
        },
        // Use manual turn detection (push-to-talk) to prevent multiple responses
        'turn_detection': null,
      },
    });
  }

  /// Handle incoming WebSocket messages
  void _handleMessage(dynamic message) async {
    try {
      final data = jsonDecode(message as String) as Map<String, dynamic>;
      final type = data['type'] as String?;

      debugPrint('Realtime event: $type');

      switch (type) {
        case 'session.created':
        case 'session.updated':
          debugPrint('Session configured');
          break;

        case 'input_audio_buffer.speech_started':
          debugPrint('Speech detected');
          break;

        case 'input_audio_buffer.speech_stopped':
          debugPrint('Speech ended');
          break;

        case 'conversation.item.input_audio_transcription.completed':
          final transcript = data['transcript'] as String?;
          if (transcript != null && transcript.isNotEmpty) {
            debugPrint('Transcript: $transcript');
            onTranscript?.call(transcript);
          }
          break;

        case 'response.audio_transcript.delta':
          final delta = data['delta'] as String?;
          if (delta != null) {
            onResponse?.call(delta);
          }
          break;

        case 'response.audio_transcript.done':
          final transcript = data['transcript'] as String?;
          debugPrint('Response transcript: $transcript');
          if (transcript != null && transcript.isNotEmpty) {
            onFullResponse?.call(transcript);
          }
          break;

        case 'response.created':
          _isResponding = true;
          onResponseStart?.call();
          // Stop recording while AI responds to prevent echo
          _pauseRecording();
          break;

        case 'response.audio.delta':
          // Receive audio chunks - just buffer them, play when complete
          final audioBase64 = data['delta'] as String?;
          if (audioBase64 != null) {
            final audioBytes = base64Decode(audioBase64);
            _audioBuffer.addAll(audioBytes);
          }
          break;

        case 'response.audio.done':
          debugPrint('Audio response complete, playing ${_audioBuffer.length} bytes');
          await _playAllBufferedAudio();
          break;

        case 'response.done':
          debugPrint('Response complete');
          _isResponding = false;
          onAudioEnd?.call();
          // Resume recording if still in listening mode
          _resumeRecording();
          break;

        case 'error':
          final error = data['error'] as Map<String, dynamic>?;
          final message = error?['message'] as String? ?? 'Unknown error';
          debugPrint('Realtime API error: $message');
          onError?.call(message);
          break;
      }
    } catch (e) {
      debugPrint('Error handling message: $e');
    }
  }

  /// Play all buffered audio at once
  Future<void> _playAllBufferedAudio() async {
    if (_audioBuffer.isEmpty) return;

    try {
      // Get all buffered audio
      final pcmData = Uint8List.fromList(_audioBuffer);
      _audioBuffer.clear();
      
      debugPrint('Playing ${pcmData.length} bytes of audio');

      // Create WAV header for PCM16 mono 24kHz
      final wavData = _createWavFile(pcmData, 24000, 1, 16);

      // Save to temp file and play
      final tempDir = await getTemporaryDirectory();
      _tempAudioPath = '${tempDir.path}/realtime_audio_${DateTime.now().millisecondsSinceEpoch}.wav';
      final file = File(_tempAudioPath!);
      await file.writeAsBytes(wavData);

      _isPlaying = true;
      onAudioStart?.call();

      await _audioPlayer.setFilePath(_tempAudioPath!);
      
      // Use a completer to wait for playback to finish
      final completer = Completer<void>();
      StreamSubscription? subscription;
      
      subscription = _audioPlayer.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          if (!completer.isCompleted) {
            completer.complete();
          }
          subscription?.cancel();
        }
      });
      
      await _audioPlayer.play();
      
      // Wait for playback to complete (with timeout)
      await completer.future.timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          debugPrint('Audio playback timed out');
          subscription?.cancel();
        },
      );
      
      // Clean up
      _isPlaying = false;
      file.delete().ignore();
      
      debugPrint('Audio playback complete');
    } catch (e) {
      debugPrint('Error playing audio: $e');
      _isPlaying = false;
    }
  }

  /// Create WAV file from PCM data
  Uint8List _createWavFile(Uint8List pcmData, int sampleRate, int channels, int bitsPerSample) {
    final byteRate = sampleRate * channels * bitsPerSample ~/ 8;
    final blockAlign = channels * bitsPerSample ~/ 8;
    final dataSize = pcmData.length;
    final fileSize = 36 + dataSize;

    final buffer = BytesBuilder();
    
    // RIFF header
    buffer.add(utf8.encode('RIFF'));
    buffer.add(_int32ToBytes(fileSize));
    buffer.add(utf8.encode('WAVE'));
    
    // fmt chunk
    buffer.add(utf8.encode('fmt '));
    buffer.add(_int32ToBytes(16)); // chunk size
    buffer.add(_int16ToBytes(1)); // audio format (PCM)
    buffer.add(_int16ToBytes(channels));
    buffer.add(_int32ToBytes(sampleRate));
    buffer.add(_int32ToBytes(byteRate));
    buffer.add(_int16ToBytes(blockAlign));
    buffer.add(_int16ToBytes(bitsPerSample));
    
    // data chunk
    buffer.add(utf8.encode('data'));
    buffer.add(_int32ToBytes(dataSize));
    buffer.add(pcmData);

    return buffer.toBytes();
  }

  Uint8List _int16ToBytes(int value) {
    return Uint8List(2)..buffer.asByteData().setInt16(0, value, Endian.little);
  }

  Uint8List _int32ToBytes(int value) {
    return Uint8List(4)..buffer.asByteData().setInt32(0, value, Endian.little);
  }

  /// Pause recording temporarily (to prevent echo while AI speaks)
  Future<void> _pauseRecording() async {
    if (!_isRecording) return;
    await _recordingSubscription?.cancel();
    await _amplitudeSubscription?.cancel();
    await _recorder.stop();
    debugPrint('Recording paused (AI speaking)');
  }
  
  /// Resume recording after AI finishes speaking
  Future<void> _resumeRecording() async {
    if (!_isRecording || !_isConnected) return;
    
    try {
      // Small delay to let audio finish playing
      await Future.delayed(const Duration(milliseconds: 200));
      
      final stream = await _recorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 24000,
          numChannels: 1,
        ),
      );

      _recordingSubscription = stream.listen((data) {
        if (_isConnected && _isRecording && !_isResponding) {
          _sendAudioChunk(data);
        }
      });

      _amplitudeSubscription = _recorder.onAmplitudeChanged(
        const Duration(milliseconds: 100),
      ).listen((amp) {
        final level = ((amp.current + 40) / 40).clamp(0.0, 1.0);
        onInputLevel?.call(level);
      });
      
      debugPrint('Recording resumed');
    } catch (e) {
      debugPrint('Failed to resume recording: $e');
    }
  }

  /// Start recording and streaming audio
  Future<void> startRecording() async {
    if (!_isConnected) {
      await connect();
    }

    if (_isRecording) return;

    try {
      // Check permission
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        onError?.call('Microphone permission denied');
        return;
      }

      _isRecording = true;

      // Start recording as a stream
      final stream = await _recorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 24000,
          numChannels: 1,
        ),
      );

      // Listen to the audio stream and send to API (only when not responding)
      _recordingSubscription = stream.listen((data) {
        if (_isConnected && _isRecording && !_isResponding) {
          _sendAudioChunk(data);
        }
      });

      // Monitor amplitude for UI feedback
      _amplitudeSubscription = _recorder.onAmplitudeChanged(
        const Duration(milliseconds: 100),
      ).listen((amp) {
        final level = ((amp.current + 40) / 40).clamp(0.0, 1.0);
        onInputLevel?.call(level);
      });

      debugPrint('Recording started');
    } catch (e) {
      debugPrint('Failed to start recording: $e');
      onError?.call('Failed to start recording: $e');
      _isRecording = false;
    }
  }

  /// Send audio chunk to the API
  void _sendAudioChunk(Uint8List audioData) {
    final base64Audio = base64Encode(audioData);
    _sendEvent({
      'type': 'input_audio_buffer.append',
      'audio': base64Audio,
    });
  }

  /// Stop recording
  Future<void> stopRecording() async {
    if (!_isRecording) return;

    _isRecording = false;
    await _recordingSubscription?.cancel();
    await _amplitudeSubscription?.cancel();
    await _recorder.stop();

    // Only commit and create response if not already responding
    if (!_isResponding) {
      // Commit the audio buffer to trigger response
      _sendEvent({
        'type': 'input_audio_buffer.commit',
      });

      // Create a response
      _sendEvent({
        'type': 'response.create',
      });
      
      debugPrint('Recording stopped, requesting response');
    } else {
      debugPrint('Recording stopped (response already in progress)');
    }
  }

  /// Send a text message instead of audio
  void sendTextMessage(String text) {
    if (!_isConnected) return;

    _sendEvent({
      'type': 'conversation.item.create',
      'item': {
        'type': 'message',
        'role': 'user',
        'content': [
          {
            'type': 'input_text',
            'text': text,
          }
        ],
      },
    });

    _sendEvent({
      'type': 'response.create',
    });
  }

  /// Send event to WebSocket
  void _sendEvent(Map<String, dynamic> event) {
    if (_channel != null && _isConnected) {
      _channel!.sink.add(jsonEncode(event));
    }
  }

  /// Stop/interrupt audio playback and cancel current response
  Future<void> stopAudio() async {
    // Cancel the current response if one is in progress
    if (_isResponding) {
      _sendEvent({'type': 'response.cancel'});
      _isResponding = false;
    }
    
    await _audioPlayer.stop();
    _audioBuffer.clear();
    _isPlaying = false;
    
    // Clear the input buffer for fresh start
    _sendEvent({'type': 'input_audio_buffer.clear'});
  }

  /// Disconnect from the API
  Future<void> disconnect() async {
    _isRecording = false;
    _isConnected = false;
    
    await _recordingSubscription?.cancel();
    await _amplitudeSubscription?.cancel();
    await _recorder.stop();
    await _recorder.dispose();
    await _audioPlayer.dispose();
    _audioBufferTimer?.cancel();
    
    _channel?.sink.close();
    _channel = null;
    
    debugPrint('Realtime API disconnected');
  }

  void dispose() {
    disconnect();
  }
}
