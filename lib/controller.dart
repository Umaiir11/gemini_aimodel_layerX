// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:image_picker/image_picker.dart';
//
// import 'ai_repo.dart';
// import 'chat_message.dart';
//
// class AIChatController extends GetxController {
//   final AIRepository _aiRepository = Get.find<AIRepository>();
//   final RxList<ChatMessage> messages = <ChatMessage>[].obs;
//   final RxString streamedText = ''.obs;
//   final RxBool isStreaming = false.obs;
//   final RxString errorMessage = ''.obs;
//   final TextEditingController textController = TextEditingController();
//   final ScrollController scrollController = ScrollController();
//
//   @override
//   void onInit() {
//     super.onInit();
//     _aiRepository.initializeModel();
//   }
//
//   Future<void> sendMessage(String userMessage) async {
//     try {
//       messages.add(ChatMessage(content: userMessage, isUser: true));
//       _scrollToBottom();
//       isStreaming.value = true;
//       streamedText.value = '';
//
//       // Use streaming API for real-time response
//       await for (final response in _aiRepository.generateTextStream(userMessage)) {
//         streamedText.value = response.text;
//         _scrollToBottom();
//       }
//
//       if (streamedText.value.isNotEmpty) {
//         messages.add(ChatMessage(content: streamedText.value, isUser: false));
//       }
//     } catch (e) {
//       errorMessage.value = 'Error: $e';
//     } finally {
//       isStreaming.value = false;
//       streamedText.value = '';
//       _scrollToBottom();
//     }
//   }
//
//   Future<void> pickImage() async {
//     try {
//       final picker = ImagePicker();
//       final pickedFile = await picker.pickImage(source: ImageSource.gallery);
//       if (pickedFile != null) {
//         final response = await _aiRepository.analyzeImage(pickedFile.path, 'Describe this image');
//         messages.add(ChatMessage(content: response.text, isUser: false));
//         _scrollToBottom();
//       }
//     } catch (e) {
//       errorMessage.value = 'Error: $e';
//     }
//   }
//
//   void _scrollToBottom() {
//     if (scrollController.hasClients) {
//       scrollController.animateTo(
//         scrollController.position.maxScrollExtent,
//         duration: const Duration(milliseconds: 300),
//         curve: Curves.easeOut,
//       );
//     }
//   }
//
//   @override
//   void onClose() {
//     textController.dispose();
//     scrollController.dispose();
//     super.onClose();
//   }
// }