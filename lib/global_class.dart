import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:dio/dio.dart';

import 'ai_repo.dart';
import 'api_client.dart';

class GlobalVariables {
  static const String geminiApiKey = 'AIzaSyCN_Uu067S2AYNY3h7R9HA15Y79ajQvwVg'; // Store securely in .env or equivalent
  static const String baseApiUrl = 'https://generativelanguage.googleapis.com'; // Official Gemini API base URL
}

class GlobalBindings extends Bindings {
  @override
  void dependencies() {
    // Initialize GetStorage for local preferences
    Get.putAsync<GetStorage>(() async {
      await GetStorage.init();
      return GetStorage();
    }, permanent: true);

    // Initialize Dio for HTTP requests
    Get.put<Dio>(Dio(BaseOptions(
      baseUrl: GlobalVariables.baseApiUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    )), permanent: true);

    // Initialize ApiClient for network operations
    Get.put<ApiClient>(ApiClient(Get.find<Dio>()), permanent: true);

    // Initialize AIRepository for Gemini API interactions
    Get.put<AIRepository>(AIRepository(), permanent: true);
  }
}