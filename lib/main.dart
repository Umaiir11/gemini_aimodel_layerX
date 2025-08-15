import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'app/config/app_routes.dart';


void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // GlobalBindings().dependencies();
  runApp(const JesusAIApp());
}

class JesusAIApp extends StatelessWidget {
  const JesusAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Veritas AI',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
        initialRoute: AppRoutes.aiChat,
        getPages: AppPages.routes,
    );
  }
}