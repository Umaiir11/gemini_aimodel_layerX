import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math' as math;
import 'package:google_generative_ai/google_generative_ai.dart';

import 'chat_rsp_model.dart';
import 'global_class.dart';

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return '';
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}

class AIRepository {
  GenerativeModel? _model;
  final Map<String, String> _verseCache = {}; // In-memory cache for verses
  final List<Map<String, String>> _sessionHistory = []; // Session-based conversation history
  bool _isInitialized = false;

  // Expanded dictionary for spell-checking (religious terms, common words, and common misspellings)
  final Set<String> _dictionary = {
    // Core religious terms (lowercased)
    'jesus', 'god', 'bible', 'christ', 'holy', 'spirit', 'faith', 'prayer', 'salvation', 'sin', 'grace', 'mercy',
    'forgiveness', 'heaven', 'hell', 'love', 'lord', 'scripture', 'apostle', 'disciple', 'gospel', 'messiah',
    'resurrection', 'baptism', 'parable', 'prophet', 'church', 'testament', 'covenant', 'miracle', 'sermon',
    'psalm', 'proverb', 'moses', 'abraham', 'david', 'solomon', 'paul', 'peter', 'john', 'matthew', 'mark',
    'luke', 'acts', 'romans', 'corinthians', 'galatians', 'ephesians', 'philippians', 'colossians',
    'thessalonians', 'timothy', 'titus', 'hebrews', 'james', 'jude', 'revelation', 'genesis', 'exodus',
    'leviticus', 'numbers', 'deuteronomy', 'isaiah', 'jeremiah', 'ezekiel', 'daniel',
    // Additional religious terms
    'savior', 'redeemer', 'shepherd', 'lamb', 'cross', 'resurrection', 'eternal', 'life', 'hope', 'charity',
    'repentance', 'atonement', 'sacrament', 'disciples', 'apostles', 'trinity', 'holyspirit', 'father', 'son',
    'virgin', 'mary', 'joseph', 'bethlehem', 'nazareth', 'jerusalem', 'calvary', 'crucifixion', 'ascension',
    'pentecost', 'sabbath', 'temple', 'altar', 'sacrifice', 'blessing', 'commandment', 'law', 'torah',
    // Common misspellings and phonetic variations
    'jeezus', 'jeusus', 'jsus', 'jesu', 'jessus', 'bibble', 'bibel', 'byble', 'preyer', 'pryer', 'prayr',
    'saviour', 'redeemer', 'crucifiction', 'resurection', 'heven', 'heavan', 'salvaton', 'forgivness',
    'grase', 'mercie', 'chuch', 'chirst', 'gospal', 'discipel', 'proffet', 'serman', 'pslam', 'prover',
    'mozes', 'abrahem', 'davvid', 'soloman', 'mathew', 'jonh', 'luc', 'actes', 'romens', 'corinthans',
    'ephesans', 'philipians', 'colosians', 'thesalonians', 'timoty', 'hebrus', 'revilation', 'genisis',
    'exodis', 'levitcus', 'numer', 'deutronomy', 'isiah', 'jeramiah', 'ezekial', 'danial',
    // Common English words (expanded for better coverage)
    'a', 'about', 'after', 'all', 'also', 'and', 'any', 'as', 'at', 'be', 'because', 'but', 'by', 'can',
    'do', 'for', 'from', 'have', 'how', 'in', 'is', 'it', 'not', 'of', 'on', 'or', 'that', 'the', 'this',
    'to', 'what', 'when', 'where', 'who', 'why', 'with', 'ask', 'tell', 'say', 'know', 'believe', 'think',
    'want', 'need', 'give', 'take', 'see', 'hear', 'learn', 'teach', 'guide', 'help', 'show', 'mean', 'meaning',
    'life', 'love', 'hope', 'peace', 'joy', 'truth', 'way', 'light', 'word', 'world', 'people', 'person',
    'good', 'evil', 'right', 'wrong', 'heart', 'soul', 'mind', 'spirit', 'body',
  };

  // Mock Bible data with support for multiple translations (replace with actual Bible API in production)
  final Map<String, Map<String, String>> _bibleData = {
    'KJV': {
      'John 3:16':
          'For God so loved the world, that he gave his only begotten Son, that whosoever believeth in him should not perish, but have everlasting life.',
      'Psalm 23:1': 'The Lord is my shepherd; I shall not want.',
      'Matthew 5:16': 'Let your light so shine before men, that they may see your good works, and glorify your Father which is in heaven.',
      'Matthew 6:9-13':
          'After this manner therefore pray ye: Our Father which art in heaven, Hallowed be thy name. Thy kingdom come, Thy will be done in earth, as it is in heaven. Give us this day our daily bread. And forgive us our debts, as we forgive our debtors. And lead us not into temptation, but deliver us from evil: For thine is the kingdom, and the power, and the glory, for ever. Amen.',
      'Philippians 4:6-7':
          'Be careful for nothing; but in every thing by prayer and supplication with thanksgiving let your requests be made known unto God. And the peace of God, which passeth all understanding, shall keep your hearts and minds through Christ Jesus.',
    },
    'NIV': {
      'John 3:16':
          'For God so loved the world that he gave his one and only Son, that whoever believes in him shall not perish but have eternal life.',
      'Psalm 23:1': 'The Lord is my shepherd, I lack nothing.',
      'Matthew 5:16': 'Let your light shine before others, that they may see your good deeds and glorify your Father in heaven.',
      'Matthew 6:9-13':
          'This, then, is how you should pray: Our Father in heaven, hallowed be your name, your kingdom come, your will be done, on earth as it is in heaven. Give us today our daily bread. And forgive us our debts, as we also have forgiven our debtors. And lead us not into temptation, but deliver us from the evil one.',
      'Philippians 4:6-7':
          'Do not be anxious about anything, but in every situation, by prayer and petition, with thanksgiving, present your requests to God. And the peace of God, which transcends all understanding, will guard your hearts and your minds in Christ Jesus.',
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

    // Sanitize and correct spelling in user input
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
      'keep explaining',
      'more?',
      'more.',
      'more??',
      'more???',
    ];

    // Handle "more" variations
    final normalizedPrompt = sanitizedPrompt.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '').trim();
    if (moreKeywords.any((kw) => normalizedPrompt == kw.replaceAll(RegExp(r'[^\w\s]'), ''))) {
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

    // Check mock Bible data for exact verse matches
    final verseMatch = _checkBibleData(sanitizedPrompt);
    if (verseMatch != null) {
      developer.log('Serving response from mock Bible data for prompt: $sanitizedPrompt', name: 'JesusAI');
      yield ChatResponse(text: verseMatch);
      _verseCache[sanitizedPrompt] = verseMatch;
      _sessionHistory.add({'prompt': sanitizedPrompt, 'response': verseMatch});
      return;
    }

    try {
      // Ultra-expanded, production-ready Jesus AI system prompt
      String aiPrompt =
          '''
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
        _verseCache[sanitizedPrompt] = finalResponse;
        developer.log('Cached response for prompt: $sanitizedPrompt', name: 'JesusAI');
        _sessionHistory.add({'prompt': sanitizedPrompt, 'response': finalResponse});
      } else {
        developer.log('Empty response received from API', name: 'JesusAI');
        yield ChatResponse(text: 'No response available from the Scriptures.');
        _sessionHistory.add({'prompt': sanitizedPrompt, 'response': 'No response available from the Scriptures.'});
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
      // Check mock Bible data for additional verses
      final additionalVerse = _checkAdditionalBibleData(lastPrompt);
      if (additionalVerse != null) {
        developer.log('Serving additional verse from mock Bible data for prompt: $lastPrompt', name: 'JesusAI');
        yield ChatResponse(text: additionalVerse);
        _verseCache['$lastPrompt:more'] = additionalVerse;
        _sessionHistory.add({'prompt': 'more', 'response': additionalVerse});
        return;
      }

      // Craft a prompt for additional related content
      String morePrompt =
          '''
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
        _verseCache['$lastPrompt:more'] = finalResponse;
        developer.log('Cached "more" response for prompt: $lastPrompt', name: 'JesusAI');
        _sessionHistory.add({'prompt': 'more', 'response': finalResponse});
      } else {
        developer.log('Empty "more" response received from API', name: 'JesusAI');
        yield ChatResponse(text: 'No further Scriptures available for this topic.');
        _sessionHistory.add({'prompt': 'more', 'response': 'No further Scriptures available for this topic.'});
      }
    } catch (e, stackTrace) {
      developer.log('Error generating "more" response: $e', name: 'JesusAI', error: e, stackTrace: stackTrace);
      yield ChatResponse(text: 'An error occurred while fetching more Scriptures. Please try again.');
      _sessionHistory.add({'prompt': 'more', 'response': 'Error: ${e.toString()}'});
    }
  }

  /// Sanitizes user input and corrects spelling mistakes
  String _sanitizeInput(String input) {
    // Remove harmful characters, preserve punctuation
    String sanitized = input
        .replaceAll(RegExp(r'[<>{}\[\]\\/;]'), '') // Remove harmful characters
        .trim();
    // Limit length
    sanitized = sanitized.length > 1000 ? sanitized.substring(0, 1000) : sanitized;
    // Correct spelling
    return _correctSpelling(sanitized);
  }

  /// Corrects spelling in the input prompt with context-aware logic
  String _correctSpelling(String message) {
    if (message.isEmpty) return message;

    // Split into words, preserving punctuation
    List<String> words = message.split(RegExp(r'(\s+|[.!?,:;])'));
    List<String> correctedWords = [];
    bool isReligiousContext = _isLikelyReligious(message.toLowerCase());

    for (String word in words) {
      // Skip if it's just punctuation
      if (RegExp(r'^[.!?,:;]+$').hasMatch(word)) {
        correctedWords.add(word);
        continue;
      }

      // Extract punctuation (leading or trailing)
      String leadingPunctuation = '';
      String trailingPunctuation = '';
      String cleanWord = word;

      // Handle leading punctuation (e.g., "(word")
      if (cleanWord.isNotEmpty && RegExp(r'^[.!?,:;]').hasMatch(cleanWord)) {
        leadingPunctuation = cleanWord[0];
        cleanWord = cleanWord.substring(1);
      }
      // Handle trailing punctuation (e.g., "word?")
      if (cleanWord.isNotEmpty && RegExp(r'[.!?,:;]$').hasMatch(cleanWord)) {
        trailingPunctuation = cleanWord[cleanWord.length - 1];
        cleanWord = cleanWord.substring(0, cleanWord.length - 1);
      }
      // Handle mid-word punctuation (e.g., "god's")
      String midPunctuation = '';
      if (cleanWord.contains("'")) {
        final parts = cleanWord.split("'");
        if (parts.length == 2) {
          cleanWord = parts[0];
          midPunctuation = "'" + parts[1];
        }
      }

      String lowerWord = cleanWord.toLowerCase();
      String corrected = _correctWord(lowerWord, isReligiousContext);

      // Preserve original capitalization
      if (cleanWord.isNotEmpty) {
        if (RegExp(r'^[A-Z][a-z]*$').hasMatch(cleanWord)) {
          corrected = corrected.capitalize();
        } else if (RegExp(r'^[A-Z]+$').hasMatch(cleanWord)) {
          corrected = corrected.toUpperCase();
        }
      }

      correctedWords.add(leadingPunctuation + corrected + midPunctuation + trailingPunctuation);
    }

    String correctedPrompt = correctedWords.join('');
    developer.log('Original prompt: $message, Corrected prompt: $correctedPrompt', name: 'JesusAI');
    return correctedPrompt;
  }

  /// Corrects a single word using the dictionary with dynamic threshold
  String _correctWord(String word, bool isReligiousContext) {
    if (word.isEmpty || _dictionary.contains(word)) {
      return word;
    }

    // Dynamic Levenshtein threshold based on word length
    int threshold = math.max(2, (word.length / 3).floor());
    if (isReligiousContext) {
      threshold = math.min(threshold, 4); // More lenient for religious terms
    }

    String closest = word;
    int minDist = threshold + 1;

    // Prioritize religious terms if in religious context
    final candidates = isReligiousContext
        ? _dictionary.where((w) => w.length >= word.length - 2 && w.length <= word.length + 2).toList()
        : _dictionary.toList();

    // Optimize by checking prefix matches first
    for (String dictWord in candidates) {
      if (dictWord.startsWith(word.substring(0, math.min(2, word.length))) || word.startsWith(dictWord.substring(0, math.min(2, dictWord.length)))) {
        int dist = _levenshtein(word, dictWord);
        if (dist < minDist) {
          minDist = dist;
          closest = dictWord;
        }
      }
    }

    // If no prefix match, check all dictionary words
    if (minDist > threshold) {
      for (String dictWord in candidates) {
        int dist = _levenshtein(word, dictWord);
        if (dist < minDist) {
          minDist = dist;
          closest = dictWord;
        }
      }
    }

    // Basic n-gram similarity for phonetic matching
    if (minDist > threshold) {
      final wordNgrams = _generateNgrams(word, 3);
      String bestNgramMatch = word;
      int maxNgramScore = 0;
      for (String dictWord in candidates) {
        final dictNgrams = _generateNgrams(dictWord, 3);
        int score = wordNgrams.intersection(dictNgrams).length;
        if (score > maxNgramScore) {
          maxNgramScore = score;
          bestNgramMatch = dictWord;
        }
      }
      if (maxNgramScore > wordNgrams.length / 2) {
        closest = bestNgramMatch;
      }
    }

    return closest;
  }

  /// Generates n-grams for a word
  Set<String> _generateNgrams(String word, int n) {
    Set<String> ngrams = {};
    for (int i = 0; i <= word.length - n; i++) {
      ngrams.add(word.substring(i, i + n));
    }
    return ngrams;
  }

  /// Checks if the prompt is likely religious for context-aware correction
  bool _isLikelyReligious(String prompt) {
    final religiousKeywords = _dictionary
        .where(
          (word) => [
            'jesus',
            'god',
            'bible',
            'christ',
            'holy',
            'spirit',
            'faith',
            'prayer',
            'salvation',
            'sin',
            'grace',
            'mercy',
            'forgiveness',
            'heaven',
            'hell',
            'lord',
            'scripture',
            'gospel',
            'messiah',
            'resurrection',
            'baptism',
            'church',
          ].contains(word),
        )
        .toList();

    final cleanPrompt = prompt.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '');
    return religiousKeywords.any((keyword) => cleanPrompt.contains(keyword));
  }

  /// Checks cache for a response
  String? _checkCache(String prompt) {
    // Normalize prompt for cache lookup (remove punctuation)
    final normalizedPrompt = prompt.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '');
    return _verseCache[normalizedPrompt] ?? _verseCache[prompt];
  }

  /// Checks mock Bible data for exact verse matches
  String? _checkBibleData(String prompt) {
    final cleanPrompt = prompt.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '');
    for (var translation in _bibleData.keys) {
      for (var verse in _bibleData[translation]!.keys) {
        if (cleanPrompt.contains(verse.toLowerCase()) || cleanPrompt.contains(verse.replaceAll(':', '').toLowerCase())) {
          final verseText = _bibleData[translation]![verse]!;
          return '''
$verse ($translation): $verseText

This verse reflects the truth of God's Word, guiding us to Jesus Christ, our Savior.
Source: Holy Bible ($translation)
''';
        }
      }
    }
    // Check for prayer-related prompts
    if (cleanPrompt.contains('pray') || cleanPrompt.contains('prayer')) {
      const verse = 'Matthew 6:9-13';
      const translation = 'NIV';
      final verseText = _bibleData[translation]![verse]!;
      return '''
$verse ($translation): $verseText

This is the Lord’s Prayer, taught by Jesus Christ to His disciples as a model for prayer. It reflects a heart of reverence, submission to God’s will, and dependence on Him for daily needs, forgiveness, and protection. Through prayer, we draw near to God, trusting in Jesus, who intercedes for us.
Source: Holy Bible ($translation)
''';
    }
    return null;
  }

  /// Checks mock Bible data for additional verses for "more" requests
  String? _checkAdditionalBibleData(String lastPrompt) {
    final cleanPrompt = lastPrompt.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '');
    if (cleanPrompt.contains('pray') || cleanPrompt.contains('prayer')) {
      const verse = 'Philippians 4:6-7';
      const translation = 'NIV';
      final verseText = _bibleData[translation]![verse]!;
      return '''
$verse ($translation): $verseText

This passage encourages us to bring all our concerns to God through prayer, trusting in Jesus Christ, who brings us the peace that surpasses understanding.
Source: Holy Bible ($translation)
''';
    }
    return null;
  }

  /// Determines if the prompt is a greeting
  Future<bool> _isGreetingPrompt(String prompt) async {
    final greetingKeywords = ['hey', 'hi', 'hello'];
    final cleanPrompt = prompt.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '');
    final promptWords = cleanPrompt.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).toList();
    bool containsGreetingKeyword = promptWords.any((word) => greetingKeywords.any((keyword) => word.contains(keyword) || keyword.contains(word)));
    developer.log('Prompt: $prompt, Greeting: $containsGreetingKeyword', name: 'JesusAI');
    return containsGreetingKeyword;
  }

  /// Determines if the prompt is religious/Bible-related
  Future<bool> _isReligiousPrompt(String prompt) async {
    final religiousKeywords = _dictionary
        .where(
          (word) => [
            // Core Christian terms from dictionary
            'jesus', 'god', 'bible', 'christ', 'holy', 'spirit', 'faith', 'prayer', 'salvation', 'sin', 'grace', 'mercy',
            'forgiveness', 'heaven', 'hell', 'love', 'lord', 'scripture', 'apostle', 'disciple', 'gospel', 'messiah',
            'resurrection', 'baptism', 'parable', 'prophet', 'church', 'testament', 'covenant', 'miracle', 'sermon',
            'psalm', 'proverb',
            // Biblical figures and books
            'moses', 'abraham', 'david', 'solomon', 'paul', 'peter', 'john', 'matthew', 'mark', 'luke', 'acts',
            'romans', 'corinthians', 'galatians', 'ephesians', 'philippians', 'colossians', 'thessalonians',
            'timothy', 'titus', 'hebrews', 'james', 'jude', 'revelation', 'genesis', 'exodus', 'leviticus',
            'numbers', 'deuteronomy', 'isaiah', 'jeremiah', 'ezekiel', 'daniel',
          ].contains(word),
        )
        .toList();

    final nonReligiousKeywords = [
      'weather',
      'stock',
      'recipe',
      'sports',
      'politics',
      'movie',
      'game',
      'technology',
      'news',
      'science',
      'fashion',
      'cook',
      'travel',
      'celebrity',
      'finance',
      'music',
      'entertainment',
      'health',
      'fitness',
      'business',
      'shopping',
      'gadget',
      'app',
      'device',
      'crypto',
      'instagram',
      'tiktok',
      'facebook',
      'youtube',
      'twitter',
      'social',
      'trend',
      'meme',
      'viral',
      'podcast',
      'streaming',
      'netflix',
      'spotify',
      'school',
      'university',
      'college',
      'exam',
      'homework',
      'assignment',
      'career',
      'job',
      'office',
      'interview',
      'resume',
      'startup',
      'restaurant',
      'cafe',
      'bar',
      'drink',
      'coffee',
      'tea',
      'dessert',
      'lunch',
      'dinner',
      'breakfast',
      'car',
      'bike',
      'flight',
      'hotel',
      'vacation',
      'tour',
      'festival',
      'concert',
      'party',
      'sale',
      'discount',
    ];

    final cleanPrompt = prompt.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '');
    final promptWords = cleanPrompt.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).toList();

    final religiousMatches = promptWords.where((word) {
      return religiousKeywords.any((keyword) {
        final wordClean = word.replaceAll(RegExp(r'[^\w]'), '');
        final keywordClean = keyword.replaceAll(RegExp(r'[^\w]'), '');
        return wordClean.contains(keywordClean) || keywordClean.contains(wordClean) || _isSimilar(wordClean, keywordClean);
      });
    }).toList();
    final nonReligiousMatches = promptWords.where((word) {
      return nonReligiousKeywords.any((keyword) {
        final wordClean = word.replaceAll(RegExp(r'[^\w]'), '');
        final keywordClean = keyword.replaceAll(RegExp(r'[^\w]'), '');
        return wordClean.contains(keywordClean) || keywordClean.contains(wordClean);
      });
    }).toList();

    developer.log('Prompt: $prompt, Religious matches: $religiousMatches, Non-religious matches: $nonReligiousMatches', name: 'JesusAI');

    if (religiousMatches.isNotEmpty) {
      developer.log('Religious prompt confirmed due to keywords: $religiousMatches', name: 'JesusAI');
      return true;
    }

    final universalQuestions = ['what is', 'meaning of', 'define', 'purpose of', 'how do', 'how to'];
    bool isUniversalQuestion = universalQuestions.any(
      (phrase) => cleanPrompt.replaceAll(RegExp(r'[^\w\s]'), '').startsWith(phrase.replaceAll(RegExp(r'[^\w\s]'), '')),
    );

    if (isUniversalQuestion && nonReligiousMatches.isEmpty) {
      developer.log('Universal question detected, treating as religious: $prompt', name: 'JesusAI');
      return true;
    }

    developer.log('No clear religious context, defaulting to non-religious: $prompt', name: 'JesusAI');
    return false;
  }

  /// Simple Levenshtein distance for fuzzy matching
  bool _isSimilar(String s1, String s2, {int threshold = 2}) {
    int getLevenshteinDistance(String s, String t) {
      if (s == t) return 0;
      if (s.isEmpty) return t.length;
      if (t.isEmpty) return s.length;

      List<int> v0 = List<int>.filled(t.length + 1, 0);
      List<int> v1 = List<int>.filled(t.length + 1, 0);

      for (int i = 0; i < v0.length; i++) {
        v0[i] = i;
      }

      for (int i = 0; i < s.length; i++) {
        v1[0] = i + 1;
        for (int j = 0; j < t.length; j++) {
          int cost = (s[i] == t[j]) ? 0 : 1;
          v1[j + 1] = ([v1[j] + 1, v0[j + 1] + 1, v0[j] + cost]).reduce((a, b) => a < b ? a : b);
        }
        for (int j = 0; j < v0.length; j++) {
          v0[j] = v1[j];
        }
      }
      return v1[t.length];
    }

    return getLevenshteinDistance(s1, s2) <= threshold;
  }

  /// Levenshtein distance for spell-checking
  int _levenshtein(String term1, String term2) {
    if (term1.isEmpty || term2.isEmpty) return math.max(term1.length, term2.length);
    final m = term1.length + 1;
    final n = term2.length + 1;
    final d = List.generate(m, (i) => List.generate(n, (j) => 0));
    for (int i = 0; i < m; i++) {
      d[i][0] = i;
    }
    for (int j = 0; j < n; j++) {
      d[0][j] = j;
    }
    for (int i = 1; i < m; i++) {
      for (int j = 1; j < n; j++) {
        final cost = (term1[i - 1] == term2[j - 1]) ? 0 : 1;
        d[i][j] = math.min(math.min(d[i - 1][j] + 1, d[i][j - 1] + 1), d[i - 1][j - 1] + cost);
      }
    }
    return d[m - 1][n - 1];
  }
}
