import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';

import 'ai_repo.dart';
import 'chat_message.dart';

class AIChatController extends GetxController {
  final AIRepository _aiRepository = Get.find<AIRepository>();
  final RxList<ChatMessage> messages = <ChatMessage>[].obs;
  final RxString streamedText = ''.obs;
  final RxBool isStreaming = false.obs;
  final RxString errorMessage = ''.obs;
  final TextEditingController textController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  final RxBool isListening = false.obs;
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
          developer.log('Speech status: $status', name: 'JesusAI');
        },
        onError: (error) {
          isListening.value = false;
          errorMessage.value = 'Speech recognition error: ${error.errorMsg}. Please try again or use text input.';
          developer.log('Speech error: ${error.errorMsg}, Permanent: ${error.permanent}', name: 'JesusAI');
        },
      );
      developer.log('Speech initialization result: $available', name: 'JesusAI');
      if (!available) {
        errorMessage.value = 'Speech recognition not available. Please check device settings or install Google Speech Services.';
        developer.log('Speech recognition not available. Possible causes: no speech engine, no internet, or device incompatibility.', name: 'JesusAI');
      }
    } catch (e, stackTrace) {
      isListening.value = false;
      errorMessage.value = 'Failed to initialize speech recognition: $e';
      developer.log('Error initializing speech: $e', name: 'JesusAI', error: e, stackTrace: stackTrace);
    }
  }

  Future<void> _initializeTts() async {
    try {
      // Check available TTS engines
      List<dynamic> engines = await _tts.getEngines;
      developer.log('Available TTS engines: $engines', name: 'JesusAI');
      if (engines.isEmpty) {
        isTtsAvailable.value = false;
        errorMessage.value = 'No TTS engine available. Please install Google Text-to-Speech from your app store.';
        developer.log('No TTS engines found', name: 'JesusAI');
        return;
      }

      // Try primary language (en-US)
      bool languageAvailable = await _trySetLanguage('en-US');
      if (!languageAvailable && _ttsRetryCount < _maxTtsRetries) {
        _ttsRetryCount++;
        developer.log('Retrying TTS initialization with fallback language (en-GB), attempt: $_ttsRetryCount', name: 'JesusAI');
        languageAvailable = await _trySetLanguage('en-GB');
      }

      if (!languageAvailable) {
        isTtsAvailable.value = false;
        errorMessage.value = 'TTS language not supported. Please ensure English is available in your device’s TTS settings.';
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
        errorMessage.value = 'TTS error: $msg. Please check your device’s TTS settings.';
        isTtsAvailable.value = false;
        developer.log('TTS error: $msg', name: 'JesusAI');
      });
      developer.log('TTS initialized successfully', name: 'JesusAI');
      isTtsAvailable.value = true;
    } catch (e, stackTrace) {
      isTtsAvailable.value = false;
      errorMessage.value = 'Failed to initialize text-to-speech: $e. Please install a TTS engine or check settings.';
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

  Future<void> sendMessage(String userMessage) async {
    if (userMessage.trim().isEmpty) {
      errorMessage.value = 'Please enter or say a valid question.';
      developer.log('Empty message received', name: 'JesusAI');
      return;
    }

    try {
      messages.add(ChatMessage(content: userMessage, isUser: true));
      _scrollToBottom();
      isStreaming.value = true;
      streamedText.value = '';
      errorMessage.value = '';

      StringBuffer responseBuffer = StringBuffer();
      await for (final response in _aiRepository.generateTextStream(userMessage)) {
        if (response.text.isNotEmpty) {
          responseBuffer.write(response.text);
          streamedText.value = responseBuffer.toString();
          _scrollToBottom();
        }
      }

      final fullResponse = responseBuffer.toString();
      if (fullResponse.isNotEmpty) {
        messages.add(ChatMessage(content: fullResponse, isUser: false));
        developer.log('Full response added to messages: $fullResponse', name: 'JesusAI');
        if (isTtsAvailable.value) {
          await speakResponse(fullResponse, messages.length - 1);
        } else {
          errorMessage.value = 'TTS unavailable. Please use text to read the response.';
          developer.log('TTS unavailable, skipping speakResponse', name: 'JesusAI');
        }
      } else {
        errorMessage.value = 'No response available from the Scriptures.';
        developer.log('Empty response received after buffering', name: 'JesusAI');
      }
    } catch (e, stackTrace) {
      errorMessage.value = 'Error processing message: ${e.toString()}';
      developer.log('Error sending message: $e', name: 'JesusAI', error: e, stackTrace: stackTrace);
    } finally {
      isStreaming.value = false;
      streamedText.value = '';
      textController.clear();
      _scrollToBottom();
    }
  }

  Future<void> startListening() async {
    if (isListening.value || isStreaming.value) return;
    if (isSpeaking.value) await stopSpeaking(); // Stop TTS before STT
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
        isListening.value = true;
        textController.clear();
        _speech.listen(
          onResult: (result) {
            textController.text = result.recognizedWords;
            if (result.finalResult) {
              isListening.value = false;
              if (result.recognizedWords.isNotEmpty) {
                sendMessage(result.recognizedWords);
              }
            }
          },
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 5),
          partialResults: true,
          cancelOnError: true,
          listenMode: stt.ListenMode.confirmation,
        );
        developer.log('Started listening', name: 'JesusAI');
      } else {
        errorMessage.value = 'Speech recognition not available. Please check device settings or install Google Speech Services.';
        developer.log('Speech recognition not available', name: 'JesusAI');
      }
    } catch (e, stackTrace) {
      isListening.value = false;
      errorMessage.value = 'Error starting speech recognition: $e';
      developer.log('Error starting speech: $e', name: 'JesusAI', error: e, stackTrace: stackTrace);
    }
  }

  Future<void> stopListening() async {
    if (!isListening.value) return;
    await _speech.stop();
    isListening.value = false;
    developer.log('Stopped listening', name: 'JesusAI');
  }

  Future<void> speakResponse(String text, int messageIndex) async {
    if (!isTtsAvailable.value) {
      errorMessage.value = 'TTS unavailable. Please check device TTS settings or install Google Text-to-Speech.';
      developer.log('TTS unavailable, skipping speakResponse', name: 'JesusAI');
      return;
    }
    if (isSpeaking.value) {
      await stopSpeaking();
    }
    try {
      isSpeaking.value = true;
      speakingMessageIndex.value = messageIndex;
      // Retry speaking up to 2 times
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
            await _initializeTts(); // Reinitialize TTS
          } else {
            throw e;
          }
        }
      }
    } catch (e, stackTrace) {
      isSpeaking.value = false;
      speakingMessageIndex.value = -1;
      isTtsAvailable.value = false;
      errorMessage.value = 'Error speaking response: $e. Please check TTS settings or try again.';
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

  void _scrollToBottom() {
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