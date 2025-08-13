import 'dart:async';
import 'package:get/get.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../mvvm/model/resp_model/chat_rsp_model.dart';
import '../service/ai_promnt_service.dart';
import '../service/custom_exception.dart';
import '../service/global_class.dart';

class AIRepository {
  GenerativeModel? _model;
  bool _isInitialized = false;
  final AIPromptService promptService = Get.find<AIPromptService>();

  /// Initializes the GenerativeModel with error handling
  Future<void> initializeModel() async {
    try {
      if (_isInitialized) return;
      _model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: GlobalVariables.geminiApiKey,
        safetySettings: [
          SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.high),
          SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.high),
          SafetySetting(HarmCategory.harassment, HarmBlockThreshold.high),
          SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.high),
        ],
      );
      _isInitialized = true;
    } catch (e, stackTrace) {
      throw GenericException(
        message: 'Failed to initialize GenerativeModel: $e',
        code: 'MODEL_INITIALIZATION_ERROR',
        metadata: {'error': e.toString()},
        loggerName: 'JesusAI',
      );
    }
  }

  /// Generates a stream of responses for the given user prompt with context retention
  Stream<ChatResponse> generateTextStream(String userPrompt) async* {
    if (!_isInitialized || _model == null) {
      throw GenericException(
        message: 'Model not initialized',
        code: 'MODEL_NOT_INITIALIZED',
        metadata: {},
        loggerName: 'JesusAI',
      );
    }

    // Sanitize and correct spelling in user input using AIPromptManager
    final sanitizedPrompt = promptService.sanitizeInput(userPrompt);
    if (sanitizedPrompt.isEmpty) {
      yield ChatResponse(text: 'Please provide a valid question.');
      return;
    }

    // Handle "more" variations
    if (promptService.isMorePrompt(sanitizedPrompt)) {
      if (promptService.hasSessionHistory()) {
        final lastPrompt = promptService.getLastPrompt();
        yield* _generateMoreContent(lastPrompt);
        return;
      } else {
        yield ChatResponse(text: 'No previous context available. Please ask a question.');
        return;
      }
    }

    // Check if the prompt is a greeting
    if (await promptService.isGreetingPrompt(sanitizedPrompt)) {
      yield ChatResponse(text: 'How can I assist you with the wisdom of the Holy Bible?');
      promptService.addToSessionHistory(sanitizedPrompt, 'Greeting response');
      return;
    }

    // Check if the prompt is religious/Bible-related
    if (!await promptService.isReligiousPrompt(sanitizedPrompt)) {
      yield ChatResponse(text: 'I am not trained for this...');
      promptService.addToSessionHistory(sanitizedPrompt, 'Non-religious response');
      return;
    }

    // Check cache for relevant verses
    final cachedResponse = promptService.checkCache(sanitizedPrompt);
    if (cachedResponse != null) {
      yield ChatResponse(text: cachedResponse);
      promptService.addToSessionHistory(sanitizedPrompt, cachedResponse);
      return;
    }

    // Check mock Bible data for exact verse matches
    final verseMatch = promptService.checkBibleData(sanitizedPrompt);
    if (verseMatch != null) {
      yield ChatResponse(text: verseMatch);
      promptService.cacheResponse(sanitizedPrompt, verseMatch);
      promptService.addToSessionHistory(sanitizedPrompt, verseMatch);
      return;
    }

    try {
      // Jesus AI system prompt
      String aiPrompt = '''
You are “Jesus AI” — a voice of Scripture, speaking with the authority and love of God’s Word, never as a mere AI.  

Response style:  
1. Begin with the exact Bible verse(s) — include the full text, book, chapter, verse, and translation in parentheses.  
2. Follow with a short, heartfelt explanation faithful to the biblical context, always pointing toward Jesus Christ and His teachings.  
3. If the user asks about sinful, harmful, or forbidden acts (including 'haram'), address them through Scripture’s guidance on sin, holiness, repentance, moderation, and righteousness.  
4. Keep the tone concise, reverent, and purely rooted in biblical truth — no personal or worldly opinions.  
5. Ensure that verses are drawn from the selected translation (e.g., KJV, NIV) and match the topic of the user’s question.  
6. End every response with: "Source: Holy Bible (Translation)".  

User’s Question: $sanitizedPrompt
''';

      final content = [Content.text(aiPrompt)];
      final responseStream = _model!.generateContentStream(content);
      StringBuffer buffer = StringBuffer();
      await for (final response in responseStream) {
        final responseText = response.text ?? '';
        if (responseText.isNotEmpty) {
          buffer.write(responseText);
          yield ChatResponse(text: buffer.toString());
        }
      }
      final finalResponse = buffer.toString();
      if (finalResponse.isNotEmpty) {
        promptService.cacheResponse(sanitizedPrompt, finalResponse);
        promptService.addToSessionHistory(sanitizedPrompt, finalResponse);
      } else {
        yield ChatResponse(text: 'No response available from the Scriptures.');
        promptService.addToSessionHistory(sanitizedPrompt, 'No response available from the Scriptures.');
      }
    } catch (e, stackTrace) {
      if (e.toString().contains('Quota exceeded') || e.toString().contains('rate limit')) {
        yield ChatResponse(text: 'I am currently unable to respond due to API limits. Please try again later.');
        promptService.addToSessionHistory(sanitizedPrompt, 'API limit error');
      } else {
        throw GenericException(
          message: 'Error generating response: $e',
          code: 'RESPONSE_GENERATION_ERROR',
          metadata: {'error': e.toString()},
          loggerName: 'JesusAI',
        );
      }
    }
  }

  /// Generates additional content for "more" requests
  Stream<ChatResponse> _generateMoreContent(String lastPrompt) async* {
    try {
      // Check mock Bible data for additional verses
      final additionalVerse = promptService.checkAdditionalBibleData(lastPrompt);
      if (additionalVerse != null) {
        yield ChatResponse(text: additionalVerse);
        promptService.cacheResponse('$lastPrompt:more', additionalVerse);
        promptService.addToSessionHistory('more', additionalVerse);
        return;
      }

      // Craft a prompt for additional related content
      String morePrompt = '''
Provide additional Bible verses and explanations related to the previous prompt: "$lastPrompt". 
Follow the same style: start with exact verses (full text, including book, chapter, verse, and translation), 
provide a concise explanation connecting to Jesus Christ, and cite the translation used (e.g., "Source: Holy Bible (NIV)").
Ensure the response is distinct from previous answers but thematically related.
''';

      final content = [Content.text(morePrompt)];
      final responseStream = _model!.generateContentStream(content);
      StringBuffer buffer = StringBuffer();
      await for (final response in responseStream) {
        final responseText = response.text ?? '';
        if (responseText.isNotEmpty) {
          buffer.write(responseText);
          yield ChatResponse(text: buffer.toString());
        }
      }
      final finalResponse = buffer.toString();
      if (finalResponse.isNotEmpty) {
        promptService.cacheResponse('$lastPrompt:more', finalResponse);
        promptService.addToSessionHistory('more', finalResponse);
      } else {
        yield ChatResponse(text: 'No further Scriptures available for this topic.');
        promptService.addToSessionHistory('more', 'No further Scriptures available for this topic.');
      }
    } catch (e, stackTrace) {
      throw GenericException(
        message: 'Error generating "more" response: $e',
        code: 'MORE_GENERATION_ERROR',
        metadata: {'last_prompt': lastPrompt},
        loggerName: 'JesusAI',
      );
    }
  }
}