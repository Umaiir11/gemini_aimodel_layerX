import 'dart:async';
import 'dart:developer' as developer;
import 'package:google_generative_ai/google_generative_ai.dart';

import 'chat_rsp_model.dart';
import 'global_class.dart';

class AIRepository {
  GenerativeModel? _model;
  final Map<String, String> _verseCache = {}; // In-memory cache for verses
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
        model: 'gemini-1.5-flash', // Corrected from 'gemini-2.5-flash'
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

  /// Generates a stream of responses for the given user prompt
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

    // Check if the prompt is religious/Bible-related
    bool isReligious = await _isReligiousPrompt(sanitizedPrompt);
    if (!isReligious) {
      developer.log('Non-religious prompt detected: $sanitizedPrompt', name: 'JesusAI');
      yield ChatResponse(text: 'I am not trained for this...');
      return;
    }

    // Check cache for relevant verses
    final cachedResponse = _checkCache(sanitizedPrompt);
    if (cachedResponse != null) {
      developer.log('Serving response from cache for prompt: $sanitizedPrompt', name: 'JesusAI');
      yield ChatResponse(text: cachedResponse);
      return;
    }

    try {
      // Ultra-expanded, production-ready Jesus AI system prompt
      String aiPrompt = '''
You are “Jesus AI” — a purpose-built assistant whose mission is to guide, teach, and answer every question solely through the living Word of God as revealed in the Holy Bible.  

You operate as a faithful servant of Scripture, never giving personal opinion, worldly bias, or information that contradicts God’s Word.  

For every response:  
1. Scripture First — Provide relevant Bible verses in full, with exact book, chapter, and verse references. Use both Old and New Testament when applicable.  
2. Faithful Explanation — Interpret the verses in simple, clear, and spiritually accurate language, staying true to biblical context.  
3. Christ-Centered Connection — Always link the answer to the life, teachings, and message of Jesus Christ.  
4. Universal Relevance — Even if the user’s question is not explicitly about the Bible, find and present Scripture that offers wisdom or guidance on the topic.  
5. Tone & Reverence — Respond with respect, humility, and reverence, honoring God’s Word and reflecting the love and truth of Christ.  
6. No Contradictions — Never provide advice, facts, or claims that conflict with Scripture.  

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
          yield ChatResponse(text: responseText);
        } else {
          developer.log('Empty response received from API', name: 'JesusAI');
          yield ChatResponse(text: 'No response available from the Scriptures.');
        }
      }
    } catch (e, stackTrace) {
      developer.log('Error generating response: $e', name: 'JesusAI', error: e, stackTrace: stackTrace);
      if (e.toString().contains('Quota exceeded') || e.toString().contains('rate limit')) {
        yield ChatResponse(text: 'I am currently unable to respond due to API limits. Please try again later.');
      } else {
        yield ChatResponse(text: 'An error occurred while searching the Scriptures. Please try again.');
      }
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
      'peter', 'jude', 'revelation', 'genesis', 'exodus', 'leviticus',
      'numbers', 'deuteronomy', 'job', 'ecclesiastes', 'isaiah', 'jeremiah',
      'ezekiel', 'daniel', 'hosea', 'joel', 'amos', 'obadiah', 'jonah', 'micah',
      'nahum', 'habakkuk', 'zephaniah', 'haggai', 'zechariah', 'malachi'
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
      'concert', 'party', 'shopping', 'sale', 'discount'
    ];

    // Normalize prompt
    final promptWords = prompt
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();

    // Check for religious keywords
    bool containsReligiousKeyword = promptWords.any(
          (word) => religiousKeywords.any((keyword) => word.contains(keyword)),
    );

    // Check for non-religious keywords
    bool containsNonReligiousKeyword = promptWords.any(
          (word) => nonReligiousKeywords.any((keyword) => word.contains(keyword)),
    );

    // Handle ambiguous cases
    if (!containsReligiousKeyword && !containsNonReligiousKeyword) {
      developer.log('Ambiguous prompt: $prompt, defaulting to non-religious', name: 'JesusAI');
      return false;
    }

    // Log decision
    developer.log(
      'Prompt: $prompt, Religious: $containsReligiousKeyword, Non-Religious: $containsNonReligiousKeyword',
      name: 'JesusAI',
    );

    // Prompt is religious if it has religious keywords and no strong non-religious indicators
    return containsReligiousKeyword && !containsNonReligiousKeyword;
  }
}