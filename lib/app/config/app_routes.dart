import 'package:get/get.dart';

import '../mvvm/view/chat_view.dart';
import '../mvvm/view_model/chat_controller.dart';
import '../repo/ai_repo.dart';
import '../service/ai_promnt_service.dart';

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
        Get.lazyPut<AIPromptService>(() => AIPromptService());
      }),
    ),
  ];
}