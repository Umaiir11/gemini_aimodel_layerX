import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'app_routes.dart';
import 'chat_controller.dart';
import 'global_class.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  GlobalBindings().dependencies();
  runApp(const AIStudioAgentApp());
}

class AIStudioAgentApp extends StatelessWidget {
  const AIStudioAgentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'AI Studio Agent',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      initialRoute: AppRoutes.aiChat,
      getPages: AppRoutes.routes,
      initialBinding: BindingsBuilder(() {
        Get.lazyPut<AIChatController>(() => AIChatController());
      }),
    );
  }
}