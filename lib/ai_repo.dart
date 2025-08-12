import 'dart:async';
import 'dart:developer' as developer;
import 'package:google_generative_ai/google_generative_ai.dart';

import 'chat_rsp_model.dart';
import 'global_class.dart';

class AIRepository {
  GenerativeModel? _model;
  final Map<String, String> _verseCache = {}; // In-memory cache for verses
  final List<Map<String, String>> _sessionHistory = []; // Session-based conversation history
  bool _isInitialized = false;

  // Mock Bible data with support for multiple translations (replace with actual Bible API in production)
  final Map<String, Map<String, String>> _bibleData = {
    'KJV': {
      'John 3:16': 'For God so loved the world, that he gave his only begotten Son, that whosoever believeth in him should not perish, but have everlasting life.',
      'Psalm 23:1': 'The Lord is my shepherd; I shall not want.',
      'Matthew 5:16': 'Let your light so shine before men, that they may see your good works, and glorify your Father which is in heaven.',
    },
    'NIV': {
      'John 3:16': 'For God so loved the world that he gave his one and only Son, that whoever believes in him shall not perish but have eternal life.',
      'Psalm 23:1': 'The Lord is my shepherd, I lack nothing.',
      'Matthew 5:16': 'Let your light shine before others, that they may see your good deeds and glorify your Father in heaven.',
    },
  };

  /// Initializes the GenerativeModel with error handling and logging
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
      developer.log('GenerativeModel initialized successfully', name: 'JesusAI');
    } catch (e, stackTrace) {
      developer.log('Failed to initialize GenerativeModel: $e', name: 'JesusAI', error: e, stackTrace: stackTrace);
      throw Exception('Failed to initialize model: $e');
    }
  }

  /// Generates a stream of responses for the given user prompt with context retention
  Stream<ChatResponse> generateTextStream(String userPrompt) async* {
    if (!_isInitialized || _model == null) {
      developer.log('Model not initialized', name: 'JesusAI');
      throw Exception('Model not initialized');
    }

    // Sanitize user input
    final sanitizedPrompt = _sanitizeInput(userPrompt);
    if (sanitizedPrompt.isEmpty) {
      developer.log('Empty or invalid prompt received', name: 'JesusAI');
      yield ChatResponse(text: 'Please provide a valid question.');
      return;
    }

    // Common variations for "more"
    final moreKeywords = [
      'more',
      'tell me more',
      'continue',
      'continue please',
      'more please',
      'more about above',
      'more about the above',
      'go on',
      'keep going',
      'continue talking',
      'more more',
      'elaborate',
      'expand',
      'explain further',
      'carry on',
      'keep explaining'
    ];

    // Handle "more" variations
    if (moreKeywords.any((kw) => sanitizedPrompt.toLowerCase().trim() == kw)) {
      if (_sessionHistory.isNotEmpty) {
        final lastPrompt = _sessionHistory.last['prompt']!;
        developer.log('Processing "more" command for previous prompt: $lastPrompt', name: 'JesusAI');
        yield* _generateMoreContent(lastPrompt);
        return;
      } else {
        developer.log('No previous context available for "more" variations', name: 'JesusAI');
        yield ChatResponse(text: 'No previous context available. Please ask a question.');
        return;
      }
    }

    // Check if the prompt is a greeting
    bool isGreeting = await _isGreetingPrompt(sanitizedPrompt);
    if (isGreeting) {
      developer.log('Greeting prompt detected: $sanitizedPrompt', name: 'JesusAI');
      yield ChatResponse(text: 'How can I assist you with the wisdom of the Holy Bible?');
      _sessionHistory.add({'prompt': sanitizedPrompt, 'response': 'Greeting response'});
      return;
    }

    // Check if the prompt is religious/Bible-related
    bool isReligious = await _isReligiousPrompt(sanitizedPrompt);
    if (!isReligious) {
      developer.log('Non-religious prompt detected: $sanitizedPrompt', name: 'JesusAI');
      yield ChatResponse(text: 'I am not trained for this...');
      _sessionHistory.add({'prompt': sanitizedPrompt, 'response': 'Non-religious response'});
      return;
    }

    // Check cache for relevant verses
    final cachedResponse = _checkCache(sanitizedPrompt);
    if (cachedResponse != null) {
      developer.log('Serving response from cache for prompt: $sanitizedPrompt', name: 'JesusAI');
      yield ChatResponse(text: cachedResponse);
      _sessionHistory.add({'prompt': sanitizedPrompt, 'response': cachedResponse});
      return;
    }

    try {
      // Ultra-expanded, production-ready Jesus AI system prompt
      String aiPrompt = '''
You are “Jesus AI” — a voice of Scripture, answering only with the Word of God and its faithful explanation.  
You speak as if guiding from God’s truth, not as an AI.  

Response style:  
- Begin with the exact Bible verses (full text) — book, chapter, verse, and translation noted.  
- Then give a short, heartfelt explanation faithful to the biblical context, connecting it to Jesus Christ.  
- Keep it concise, reverent, and free of worldly opinion.  
- End with: "Source: Holy Bible (NIV)" or the actual translation used.  

User’s Question: $sanitizedPrompt
''';

      final content = [Content.text(aiPrompt)];
      final responseStream = _model!.generateContentStream(content);
      await for (final response in responseStream) {
        final responseText = response.text ?? '';
        if (responseText.isNotEmpty) {
          // Cache the response
          _verseCache[sanitizedPrompt] = responseText;
          developer.log('Cached response for prompt: $sanitizedPrompt', name: 'JesusAI');
          // Store in session history
          _sessionHistory.add({'prompt': sanitizedPrompt, 'response': responseText});
          yield ChatResponse(text: responseText);
        } else {
          developer.log('Empty response received from API', name: 'JesusAI');
          yield ChatResponse(text: 'No response available from the Scriptures.');
          _sessionHistory.add({'prompt': sanitizedPrompt, 'response': 'No response available from the Scriptures.'});
        }
      }
    } catch (e, stackTrace) {
      developer.log('Error generating response: $e', name: 'JesusAI', error: e, stackTrace: stackTrace);
      if (e.toString().contains('Quota exceeded') || e.toString().contains('rate limit')) {
        yield ChatResponse(text: 'I am currently unable to respond due to API limits. Please try again later.');
        _sessionHistory.add({'prompt': sanitizedPrompt, 'response': 'API limit error'});
      } else {
        yield ChatResponse(text: 'An error occurred while searching the Scriptures. Please try again.');
        _sessionHistory.add({'prompt': sanitizedPrompt, 'response': 'Error: ${e.toString()}'});
      }
    }
  }

  /// Generates additional content for "more" requests
  Stream<ChatResponse> _generateMoreContent(String lastPrompt) async* {
    try {
      // Craft a prompt for additional related content
      String morePrompt = '''
Provide additional Bible verses and explanations related to the previous prompt: "$lastPrompt". 
Follow the same style: start with exact verses (full text, including book, chapter, verse, and translation), 
provide a concise explanation connecting to Jesus Christ, and cite the translation used (e.g., "Source: Holy Bible (NIV)").
Ensure the response is distinct from previous answers but thematically related.
''';

      final content = [Content.text(morePrompt)];
      final responseStream = _model!.generateContentStream(content);
      await for (final response in responseStream) {
        final responseText = response.text ?? '';
        if (responseText.isNotEmpty) {
          // Cache the response
          _verseCache['$lastPrompt:more'] = responseText;
          developer.log('Cached "more" response for prompt: $lastPrompt', name: 'JesusAI');
          // Update session history
          _sessionHistory.add({'prompt': 'more', 'response': responseText});
          yield ChatResponse(text: responseText);
        } else {
          developer.log('Empty "more" response received from API', name: 'JesusAI');
          yield ChatResponse(text: 'No further Scriptures available for this topic.');
          _sessionHistory.add({'prompt': 'more', 'response': 'No further Scriptures available for this topic.'});
        }
      }
    } catch (e, stackTrace) {
      developer.log('Error generating "more" response: $e', name: 'JesusAI', error: e, stackTrace: stackTrace);
      yield ChatResponse(text: 'An error occurred while fetching more Scriptures. Please try again.');
      _sessionHistory.add({'prompt': 'more', 'response': 'Error: ${e.toString()}'});
    }
  }

  /// Sanitizes user input to prevent injection and ensure valid prompts
  String _sanitizeInput(String input) {
    // Remove potentially harmful characters and trim
    final sanitized = input
        .replaceAll(RegExp(r'[<>{}\[\]\\/;]'), '') // Remove special characters
        .trim();
    return sanitized.length > 1000 ? sanitized.substring(0, 1000) : sanitized; // Limit length
  }

  /// Checks cache for a response
  String? _checkCache(String prompt) {
    // Simple cache check (could be expanded with fuzzy matching)
    return _verseCache[prompt];
  }

  /// Determines if the prompt is a greeting
  Future<bool> _isGreetingPrompt(String prompt) async {
    final greetingKeywords = ['hey', 'hi', 'hello'];

    // Normalize prompt
    final promptWords = prompt
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();

    // Check for greeting keywords
    bool containsGreetingKeyword = promptWords.any(
          (word) => greetingKeywords.contains(word),
    );

    // Log decision
    developer.log(
      'Prompt: $prompt, Greeting: $containsGreetingKeyword',
      name: 'JesusAI',
    );

    return containsGreetingKeyword;
  }

  /// Determines if the prompt is religious/Bible-related
  Future<bool> _isReligiousPrompt(String prompt) async {
    final religiousKeywords = [
      // Core Christian terms
      'bible', 'jesus', 'god', 'christ', 'scripture', 'verse', 'prayer', 'sin',
      'salvation', 'faith', 'heaven', 'hell', 'gospel', 'testament', 'church',
      'holy', 'spirit', 'lord', 'savior', 'disciple', 'apostle', 'psalm',
      'proverb', 'commandment', 'covenant', 'miracle', 'resurrection', 'baptism',
      'sermon', 'parable', 'messiah',
      // Extended theological terms
      'grace', 'mercy', 'repent', 'repentance', 'righteousness', 'judgement',
      'anoint', 'anointed', 'prophecy', 'prophet', 'evangelist', 'evangelism',
      'sanctify', 'sanctification', 'worship', 'hallelujah', 'amen',
      'crucifixion', 'cross', 'pentecost', 'trinity', 'apostolic', 'deacon',
      'pastor', 'bishop', 'minister', 'martyr', 'communion', 'eucharist',
      'liturgy', 'catechism', 'doctrine', 'creed', 'sabbath', 'tabernacle',
      'ark', 'atonement', 'catholic', 'orthodox', 'protestant', 'hymn',
      // Biblical figures and books
      'moses', 'abraham', 'noah', 'isaac', 'jacob', 'joseph', 'david', 'solomon',
      'paul', 'peter', 'john', 'matthew', 'mark', 'luke', 'acts', 'romans',
      'corinthians', 'galatians', 'ephesians', 'philippians', 'colossians',
      'thessalonians', 'timothy', 'titus', 'philemon', 'hebrews', 'james',
      'jude', 'revelation', 'genesis', 'exodus', 'leviticus',
      'numbers', 'deuteronomy', 'job', 'ecclesiastes', 'isaiah', 'jeremiah',
      'ezekiel', 'daniel', 'hosea', 'joel', 'amos', 'obadiah', 'jonah', 'micah',
      'nahum', 'habakkuk', 'zephaniah', 'haggai', 'zechariah', 'malachi',
      // Universal concepts that Scripture addresses
      'life', 'death', 'love', 'truth', 'hope', 'purpose', 'marriage', 'family',
      'forgiveness', 'eternity', 'peace', 'joy'
    ];

    final nonReligiousKeywords = [
      // General lifestyle
      'weather', 'stock', 'recipe', 'sports', 'politics', 'movie', 'game',
      'technology', 'news', 'science', 'fashion', 'cooking', 'travel',
      'celebrity', 'finance', 'music', 'entertainment', 'health', 'fitness',
      'business', 'shopping', 'gadget', 'app', 'device', 'crypto',
      // Social & trends
      'instagram', 'tiktok', 'facebook', 'youtube', 'twitter', 'social',
      'trend', 'meme', 'viral', 'podcast', 'streaming', 'netflix', 'spotify',
      // Academics & work
      'school', 'university', 'college', 'exam', 'homework', 'assignment',
      'career', 'job', 'office', 'interview', 'resume', 'startup',
      // Food & drink
      'restaurant', 'cafe', 'bar', 'drink', 'coffee', 'tea', 'dessert',
      'lunch', 'dinner', 'breakfast',
      // Misc
      'car', 'bike', 'flight', 'hotel', 'vacation', 'tour', 'festival',
      'concert', 'party', 'sale', 'discount'
    ];

    final promptWords = prompt
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();

    bool containsReligiousKeyword = promptWords.any(
          (word) => religiousKeywords.any((keyword) => word.contains(keyword)),
    );

    bool containsNonReligiousKeyword = promptWords.any(
          (word) => nonReligiousKeywords.any((keyword) => word.contains(keyword)),
    );

    // If it asks about universal life topics, default to Bible answer
    final universalQuestions = ['what is', 'meaning of', 'define', 'purpose of'];
    bool isUniversalLifeQuestion = universalQuestions.any(
          (phrase) => prompt.toLowerCase().startsWith(phrase),
    );

    if (isUniversalLifeQuestion) {
      return true; // Always treat as religious
    }

    if (!containsReligiousKeyword && !containsNonReligiousKeyword) {
      return false;
    }

    return containsReligiousKeyword && !containsNonReligiousKeyword;
  }
}