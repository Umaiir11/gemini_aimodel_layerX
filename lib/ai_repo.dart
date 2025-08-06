import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';

import 'chat_rsp_model.dart';
import 'global_class.dart';

class AIRepository {
  GenerativeModel? _model;

  void initializeModel() {
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: GlobalVariables.geminiApiKey,
      safetySettings: [
        SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.medium),
        SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.medium),
      ],
    );
  }

  Stream<ChatResponse> generateTextStream(String prompt) async* {
    if (_model == null) throw Exception('Model not initialized');
    final content = [Content.text(prompt)];
    final responseStream = _model!.generateContentStream(content);
    await for (final response in responseStream) {
      yield ChatResponse(text: response.text ?? '');
    }
  }

  Future<ChatResponse> analyzeImage(String imagePath, String prompt) async {
    if (_model == null) throw Exception('Model not initialized');
    final imageBytes = await File(imagePath).readAsBytes();
    final content = [
      Content.multi([
        TextPart(prompt),
        DataPart('image/jpeg', imageBytes),
      ])
    ];
    final response = await _model!.generateContent(content);
    return ChatResponse(text: response.text ?? 'No response');
  }
}