import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

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

  @override
  void onInit() {
    super.onInit();
    _initializeModel();
  }

  Future<void> _initializeModel() async {
    try {
      await _aiRepository.initializeModel();
      developer.log('AIChatController initialized model', name: 'JesusAI');
    } catch (e) {
      errorMessage.value = 'Failed to initialize Jesus AI. Please try again later.';
      developer.log('Error initializing model: $e', name: 'JesusAI');
    }
  }

  void sendMessage(String userMessage) async {
    if (userMessage.trim().isEmpty) {
      errorMessage.value = 'Please enter a valid question.';
      developer.log('Empty message received', name: 'JesusAI');
      return;
    }

    try {
      messages.add(ChatMessage(content: userMessage, isUser: true));
      _scrollToBottom();
      isStreaming.value = true;
      streamedText.value = '';

      // Buffer the streamed response
      StringBuffer responseBuffer = StringBuffer();
      await for (final response in _aiRepository.generateTextStream(userMessage)) {
        if (response.text.isNotEmpty) {
          responseBuffer.write(response.text);
        }
      }

      final fullResponse = responseBuffer.toString();
      if (fullResponse.isNotEmpty) {
        messages.add(ChatMessage(content: fullResponse, isUser: false));
        developer.log('Full response added to messages: $fullResponse', name: 'JesusAI');
      } else {
        errorMessage.value = 'No response available from the Scriptures.';
        developer.log('Empty response received after buffering', name: 'JesusAI');
      }
    } catch (e) {
      errorMessage.value = 'Error: $e';
      developer.log('Error sending message: $e', name: 'JesusAI');
    } finally {
      isStreaming.value = false;
      streamedText.value = '';
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    if (scrollController.hasClients) {
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void onClose() {
    textController.dispose();
    scrollController.dispose();
    super.onClose();
  }
}