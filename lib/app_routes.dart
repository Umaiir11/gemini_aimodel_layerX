import 'package:get/get.dart';

import 'ai_repo.dart';
import 'chat_controller.dart';
import 'chat_view.dart';

class AppRoutes {
  static const String aiChat = '/ai-chat';
}

abstract class AppPages {
  AppPages._();

  static final routes = <GetPage>[
    GetPage(
      name: AppRoutes.aiChat,
      page: () => const AIChatView(),
      transition: Transition.fade,
      binding: BindingsBuilder(() {
        Get.lazyPut<AIRepository>(() => AIRepository());
        Get.lazyPut<AIChatController>(() => AIChatController());
      }),
    ),
  ];
}