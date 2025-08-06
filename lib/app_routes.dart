import 'package:get/get.dart';

import 'chat_controller.dart';
import 'chat_view.dart';

class AppRoutes {
  static const String aiChat = '/ai-chat';

  static final routes = [
    GetPage(
      name: aiChat,
      page: () => const AIChatView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<AIChatController>(() => AIChatController());
      }),
    ),
    // Add more routes for Text Utilities, Image Analyzer, etc.
  ];
}