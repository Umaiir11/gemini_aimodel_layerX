import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../repo/ai_repo.dart';
import '../model/body_model/chat_message.dart';

class AIChatController extends GetxController {
  final AIRepository _aiRepository = Get.find<AIRepository>();
  final RxList<ChatMessage> messages = <ChatMessage>[].obs; // Kept for internal tracking, not displayed
  final RxString streamedText = ''.obs;
  final RxBool isStreaming = false.obs;
  final RxBool isLoading = false.obs; // Added for loading state
  final RxString errorMessage = ''.obs;
  final TextEditingController textController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  final RxBool isListening = false.obs;
  final RxBool isRecording = false.obs;
  final RxBool isSpeaking = false.obs;
  final RxInt speakingMessageIndex = (-1).obs;
  final RxBool isTtsAvailable = true.obs;
  Timer? _scrollDebounceTimer;
  int _ttsRetryCount = 0;
  static const int _maxTtsRetries = 2;

  @override
  void onInit() {
    super.onInit();
    _initializeModel();
    _initializeSpeech();
    _initializeTts();
  }

  Future<void> _initializeModel() async {
    try {
      await _aiRepository.initializeModel();
      developer.log('AIChatController initialized model', name: 'JesusAI');
    } catch (e, stackTrace) {
      errorMessage.value = 'Failed to initialize Jesus AI. Please try again later.';
      developer.log('Error initializing model: $e', name: 'JesusAI', error: e, stackTrace: stackTrace);
    }
  }

  Future<void> _initializeSpeech() async {
    try {
      var status = await Permission.microphone.status;
      developer.log('Microphone permission status: $status', name: 'JesusAI');
      if (!status.isGranted) {
        status = await Permission.microphone.request();
        developer.log('Microphone permission request result: $status', name: 'JesusAI');
        if (!status.isGranted) {
          errorMessage.value = 'Microphone permission denied. Please enable it in device settings.';
          developer.log('Microphone permission denied', name: 'JesusAI');
          return;
        }
      }

      bool available = await _speech.initialize(
        onStatus: (status) {
          isListening.value = status == 'listening';
          if (status != 'listening') {
            isRecording.value = false;
          }
          developer.log('Speech status: $status', name: 'JesusAI');
        },
        onError: (error) {
          isListening.value = false;
          isRecording.value = false;
          errorMessage.value = 'Speech recognition error: ${error.errorMsg}.';
          developer.log('Speech error: ${error.errorMsg}, Permanent: ${error.permanent}', name: 'JesusAI');
        },
      );
      developer.log('Speech initialization result: $available', name: 'JesusAI');
      if (!available) {
        errorMessage.value = 'Speech recognition not available. Please check device settings or install Google Speech Services.';
        developer.log('Speech recognition not available.', name: 'JesusAI');
      }
    } catch (e, stackTrace) {
      isListening.value = false;
      isRecording.value = false;
      errorMessage.value = 'Failed to initialize speech recognition: $e';
      developer.log('Error initializing speech: $e', name: 'JesusAI', error: e, stackTrace: stackTrace);
    }
  }

  Future<void> _initializeTts() async {
    try {
      List<dynamic> engines = await _tts.getEngines;
      developer.log('Available TTS engines: $engines', name: 'JesusAI');
      if (engines.isEmpty) {
        isTtsAvailable.value = false;
        errorMessage.value = 'No TTS engine available. Please install Google Text-to-Speech.';
        developer.log('No TTS engines found', name: 'JesusAI');
        return;
      }

      bool languageAvailable = await _trySetLanguage('en-US');
      if (!languageAvailable && _ttsRetryCount < _maxTtsRetries) {
        _ttsRetryCount++;
        developer.log('Retrying TTS initialization with fallback language (en-GB), attempt: $_ttsRetryCount', name: 'JesusAI');
        languageAvailable = await _trySetLanguage('en-GB');
      }

      if (!languageAvailable) {
        isTtsAvailable.value = false;
        errorMessage.value = 'TTS language not supported. Please ensure English is available in TTS settings.';
        developer.log('TTS language not supported', name: 'JesusAI');
        return;
      }

      await _tts.setPitch(1.0);
      await _tts.setSpeechRate(0.5);
      _tts.setCompletionHandler(() {
        isSpeaking.value = false;
        speakingMessageIndex.value = -1;
        developer.log('TTS completed', name: 'JesusAI');
      });
      _tts.setErrorHandler((msg) {
        isSpeaking.value = false;
        speakingMessageIndex.value = -1;
        errorMessage.value = 'TTS error: $msg.';
        isTtsAvailable.value = false;
        developer.log('TTS error: $msg', name: 'JesusAI');
      });
      developer.log('TTS initialized successfully', name: 'JesusAI');
      isTtsAvailable.value = true;
    } catch (e, stackTrace) {
      isTtsAvailable.value = false;
      errorMessage.value = 'Failed to initialize text-to-speech: $e.';
      developer.log('Error initializing TTS: $e', name: 'JesusAI', error: e, stackTrace: stackTrace);
    }
  }

  Future<bool> _trySetLanguage(String language) async {
    try {
      List<dynamic> languages = await _tts.getLanguages;
      developer.log('Available TTS languages: $languages', name: 'JesusAI');
      if (languages.contains(language)) {
        await _tts.setLanguage(language);
        developer.log('TTS language set to: $language', name: 'JesusAI');
        return true;
      }
      return false;
    } catch (e) {
      developer.log('Failed to set TTS language $language: $e', name: 'JesusAI');
      return false;
    }
  }

  Future<void> startRecording() async {
    if (isRecording.value || isListening.value || isStreaming.value || isLoading.value) return;
    if (isSpeaking.value) await stopSpeaking();
    try {
      var status = await Permission.microphone.status;
      if (!status.isGranted) {
        status = await Permission.microphone.request();
        if (!status.isGranted) {
          errorMessage.value = 'Microphone permission denied. Please enable it in device settings.';
          developer.log('Microphone permission denied', name: 'JesusAI');
          return;
        }
      }

      bool available = await _speech.initialize();
      if (available) {
        isRecording.value = true;
        isListening.value = true;
        textController.clear();
        _speech.listen(
          onResult: (result) {
            textController.text = result.recognizedWords;
            if (result.finalResult) {
              isListening.value = false;
              isRecording.value = false;
              if (result.recognizedWords.isNotEmpty) {
                sendMessage(result.recognizedWords);
              } else {
                errorMessage.value = 'No speech detected. Please try again.';
                developer.log('No speech detected', name: 'JesusAI');
              }
            }
          },
          listenFor: const Duration(seconds: 60),
          pauseFor: const Duration(seconds: 5),
          partialResults: true,
          cancelOnError: true,
          listenMode: stt.ListenMode.dictation,
        );
        developer.log('Started recording', name: 'JesusAI');
      } else {
        isRecording.value = false;
        isListening.value = false;
        errorMessage.value = 'Speech recognition not available. Please check device settings or install Google Speech Services.';
        developer.log('Speech recognition not available', name: 'JesusAI');
      }
    } catch (e, stackTrace) {
      isRecording.value = false;
      isListening.value = false;
      errorMessage.value = 'Error starting speech recording: $e';
      developer.log('Error starting recording: $e', name: 'JesusAI', error: e, stackTrace: stackTrace);
    }
  }

  Future<void> stopRecording() async {
    if (!isRecording.value && !isListening.value) return;
    await _speech.stop();
    isRecording.value = false;
    isListening.value = false;
    developer.log('Stopped recording', name: 'JesusAI');
  }

  Future<void> sendMessage(String userMessage) async {
    if (userMessage.trim().isEmpty) {
      errorMessage.value = 'Please say a valid question.';
      developer.log('Empty message received', name: 'JesusAI');
      return;
    }

    try {
      // Store message internally, not displayed in UI
      messages.add(ChatMessage(content: userMessage, isUser: true));
      isLoading.value = true; // Show loading indicator
      errorMessage.value = '';

      StringBuffer responseBuffer = StringBuffer();
      await for (final response in _aiRepository.generateTextStream(userMessage)) {
        isLoading.value = false; // Stop loading once streaming starts
        isStreaming.value = true;
        if (response.text.isNotEmpty) {
          responseBuffer.write(response.text);
          streamedText.value = responseBuffer.toString();
        }
      }

      final fullResponse = responseBuffer.toString();
      if (fullResponse.isNotEmpty) {
        messages.add(ChatMessage(content: fullResponse, isUser: false));
        developer.log('Full response: $fullResponse', name: 'JesusAI');
        if (isTtsAvailable.value) {
          await speakResponse(fullResponse, messages.length - 1);
        } else {
          errorMessage.value = 'TTS unavailable. Please check device TTS settings.';
          developer.log('TTS unavailable, skipping speakResponse', name: 'JesusAI');
        }
      } else {
        errorMessage.value = 'No response available. Please try again.';
        developer.log('Empty response received', name: 'JesusAI');
      }
    } catch (e, stackTrace) {
      errorMessage.value = 'Error processing request: ${e.toString()}';
      developer.log('Error sending message: $e', name: 'JesusAI', error: e, stackTrace: stackTrace);
    } finally {
      isStreaming.value = false;
      isLoading.value = false;
      streamedText.value = '';
      textController.clear();
    }
  }

  Future<void> speakResponse(String text, int messageIndex) async {
    if (!isTtsAvailable.value) {
      errorMessage.value = 'TTS unavailable. Please check device TTS settings.';
      developer.log('TTS unavailable, skipping speakResponse', name: 'JesusAI');
      return;
    }
    if (isSpeaking.value) {
      await stopSpeaking();
    }
    try {
      isSpeaking.value = true;
      speakingMessageIndex.value = messageIndex;
      int retryCount = 0;
      bool success = false;
      while (retryCount < _maxTtsRetries && !success) {
        try {
          await _tts.speak(text);
          success = true;
          developer.log('Speaking response: $text', name: 'JesusAI');
        } catch (e) {
          retryCount++;
          developer.log('TTS speak attempt $retryCount failed: $e', name: 'JesusAI');
          if (retryCount < _maxTtsRetries) {
            await Future.delayed(const Duration(milliseconds: 500));
            await _initializeTts();
          } else {
            throw e;
          }
        }
      }
    } catch (e, stackTrace) {
      isSpeaking.value = false;
      speakingMessageIndex.value = -1;
      isTtsAvailable.value = false;
      errorMessage.value = 'Error speaking response: $e.';
      developer.log('Error speaking: $e', name: 'JesusAI', error: e, stackTrace: stackTrace);
    }
  }

  Future<void> stopSpeaking() async {
    if (!isSpeaking.value) return;
    try {
      await _tts.stop();
      isSpeaking.value = false;
      speakingMessageIndex.value = -1;
      developer.log('Stopped speaking', name: 'JesusAI');
    } catch (e, stackTrace) {
      errorMessage.value = 'Error stopping TTS: $e';
      developer.log('Error stopping TTS: $e', name: 'JesusAI', error: e, stackTrace: stackTrace);
    }
  }

  Future<void> cancelRequest() async {
    try {
      if (isSpeaking.value) {
        await stopSpeaking();
      }
      if (isStreaming.value || isLoading.value) {
        // Assuming AIRepository supports canceling streams
        await _aiRepository.cancelStream();
        isStreaming.value = false;
        isLoading.value = false;
        streamedText.value = '';
        errorMessage.value = '';
        developer.log('Request canceled', name: 'JesusAI');
      }
      if (isRecording.value || isListening.value) {
        await stopRecording();
      }
    } catch (e, stackTrace) {
      errorMessage.value = 'Error canceling request: $e';
      developer.log('Error canceling request: $e', name: 'JesusAI', error: e, stackTrace: stackTrace);
    }
  }

  void _scrollToBottom() {
    // Kept for potential future use, not needed for voice-only UI
    if (scrollController.hasClients) {
      _scrollDebounceTimer?.cancel();
      _scrollDebounceTimer = Timer(const Duration(milliseconds: 200), () {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          scrollController.animateTo(
            scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        });
      });
    }
  }

  @override
  void onClose() {
    _scrollDebounceTimer?.cancel();
    textController.dispose();
    scrollController.dispose();
    _speech.stop();
    _tts.stop();
    super.onClose();
  }
}