import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'app_routes.dart';
import 'chat_controller.dart';
import 'global_class.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  GlobalBindings().dependencies();
  runApp(const JesusAIApp());
}

class JesusAIApp extends StatelessWidget {
  const JesusAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Jesus AI',
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