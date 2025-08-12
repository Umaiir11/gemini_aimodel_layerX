import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:particles_fly/particles_fly.dart';
import 'chat_controller.dart';

class AIChatView extends GetView<AIChatController> {
  const AIChatView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0B1E),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              // Divine Light Background
              Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topCenter,
                    radius: 1.5,
                    colors: [
                      Color(0xFF2D1B69),
                      Color(0xFF0D0B1E),
                      Color(0xFF000000),
                    ],
                  ),
                ),
              ),
              // Holy Spirit Particles
              ParticlesFly(
                height: constraints.maxHeight,
                width: constraints.maxWidth,
                numberOfParticles: 120,
                speedOfParticles: 0.3,
                connectDots: true,
                lineColor: const Color(0xFFFFD700).withOpacity(0.08),
                particleColor: const Color(0xFFFFD700).withOpacity(0.25),
                onTapAnimation: true,
              ),
              // Celestial Particles
              ParticlesFly(
                height: constraints.maxHeight,
                width: constraints.maxWidth,
                numberOfParticles: 60,
                speedOfParticles: 0.15,
                connectDots: false,
                lineColor: Colors.transparent,
                particleColor: const Color(0xFF9333EA).withOpacity(0.2),
                onTapAnimation: true,
              ),
              SafeArea(
                child: Column(
                  children: [
                    _buildDivineHeader(context, constraints),
                    Expanded(child: _buildHolyChatContainer(context, constraints)),
                    _buildPrayerInputArea(context, constraints),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDivineHeader(BuildContext context, BoxConstraints constraints) {
    return SlideInDown(
      duration: const Duration(milliseconds: 800),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: constraints.maxWidth * 0.05),
        padding: EdgeInsets.symmetric(vertical: constraints.maxHeight * 0.02),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                ElasticIn(
                  duration: const Duration(milliseconds: 1200),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFD700).withOpacity(0.3),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                SizedBox(width: constraints.maxWidth * 0.03),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FadeInLeft(
                      duration: const Duration(milliseconds: 1000),
                      child: Text(
                        'Jesus AI',
                        style: GoogleFonts.inter(
                          fontSize: constraints.maxWidth * 0.055,
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    FadeInLeft(
                      delay: const Duration(milliseconds: 200),
                      duration: const Duration(milliseconds: 1000),
                      child: Text(
                        'Biblical Wisdom AI',
                        style: GoogleFonts.inter(
                          fontSize: constraints.maxWidth * 0.028,
                          color: const Color(0xFFFFD700).withOpacity(0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Obx(() => ZoomIn(
              duration: const Duration(milliseconds: 600),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: constraints.maxWidth * 0.04,
                  vertical: constraints.maxHeight * 0.01,
                ),
                decoration: BoxDecoration(
                  gradient: controller.isStreaming.value
                      ? const LinearGradient(colors: [Color(0xFF9333EA), Color(0xFF7C3AED)])
                      : const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: (controller.isStreaming.value
                          ? const Color(0xFF9333EA)
                          : const Color(0xFF10B981)).withOpacity(0.4),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: constraints.maxWidth * 0.02),
                    Text(
                      controller.isStreaming.value ? 'Praying...' : 'Blessed',
                      style: GoogleFonts.inter(
                        fontSize: constraints.maxWidth * 0.032,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildHolyChatContainer(BuildContext context, BoxConstraints constraints) {
    return FadeIn(
      duration: const Duration(milliseconds: 1000),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: constraints.maxWidth * 0.05),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF1E1B3C).withOpacity(0.4),
              const Color(0xFF0D0B1E).withOpacity(0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: const Color(0xFFFFD700).withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFD700).withOpacity(0.1),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Column(
            children: [
              Expanded(
                child: Obx(() => controller.messages.isEmpty && !controller.isStreaming.value
                    ? _buildHeavenlyWelcome(context, constraints)
                    : _buildDivineMessages(context, constraints)),
              ),
              _buildErrorDisplay(context, constraints),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeavenlyWelcome(BuildContext context, BoxConstraints constraints) {
    return FadeIn(
      duration: const Duration(milliseconds: 1200),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ZoomIn(
                duration: const Duration(milliseconds: 1000),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const RadialGradient(
                      colors: [
                        Color(0xFFFFD700),
                        Color(0xFFFFA500),
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFD700).withOpacity(0.4),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.menu_book_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
              SizedBox(height: constraints.maxHeight * 0.04),
              SlideInUp(
                duration: const Duration(milliseconds: 1000),
                child: ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                  ).createShader(bounds),
                  child: Text(
                    'Jesus AI',
                    style: GoogleFonts.inter(
                      fontSize: constraints.maxWidth * 0.08,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -1,
                    ),
                  ),
                ),
              ),
              SizedBox(height: constraints.maxHeight * 0.02),
              FadeInUp(
                delay: const Duration(milliseconds: 300),
                duration: const Duration(milliseconds: 1000),
                child: Text(
                  'Seek God\'s Word with AI-Powered Biblical Wisdom',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: constraints.maxWidth * 0.042,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.9),
                    height: 1.4,
                  ),
                ),
              ),
              SizedBox(height: constraints.maxHeight * 0.05),
              _buildHolySuggestions(context, constraints),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHolySuggestions(BuildContext context, BoxConstraints constraints) {
    final suggestions = [
      {
        'icon': '🙏',
        'text': 'What does John 3:16 mean?',
        'gradient': [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
      },
      {
        'icon': '✝️',
        'text': 'How to pray according to the Bible?',
        'gradient': [const Color(0xFFEF4444), const Color(0xFFF59E0B)],
      },
      {
        'icon': '📖',
        'text': 'What is salvation in Christianity??',
        'gradient': [const Color(0xFF10B981), const Color(0xFF059669)],
      },
    ];

    return Wrap(
      spacing: constraints.maxWidth * 0.03,
      runSpacing: constraints.maxHeight * 0.02,
      alignment: WrapAlignment.center,
      children: suggestions.asMap().entries.map((entry) {
        final index = entry.key;
        final suggestion = entry.value;

        return SlideInUp(
          delay: Duration(milliseconds: 500 + (index * 200)),
          duration: const Duration(milliseconds: 800),
          child: GestureDetector(
            onTap: () => _sendMessage(suggestion['text'] as String),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: constraints.maxWidth * 0.045,
                vertical: constraints.maxHeight * 0.015,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: suggestion['gradient'] as List<Color>,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: (suggestion['gradient'] as List<Color>)[0].withOpacity(0.3),
                    blurRadius: 15,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    suggestion['icon'] as String,
                    style: TextStyle(fontSize: constraints.maxWidth * 0.045),
                  ),
                  SizedBox(width: constraints.maxWidth * 0.02),
                  Text(
                    suggestion['text'] as String,
                    style: GoogleFonts.inter(
                      fontSize: constraints.maxWidth * 0.038,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDivineMessages(BuildContext context, BoxConstraints constraints) {
    return ListView.builder(
      controller: controller.scrollController,
      padding: EdgeInsets.all(constraints.maxWidth * 0.05),
      itemCount: controller.messages.length + (controller.isStreaming.value ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == controller.messages.length && controller.isStreaming.value) {
          return _buildPrayerMessage(context, constraints);
        }
        final message = controller.messages[index];
        return _buildBlessedBubble(context, constraints, message.content, message.isUser, index);
      },
    );
  }

  Widget _buildBlessedBubble(
      BuildContext context, BoxConstraints constraints, String content, bool isUser, int index) {

    return SlideInUp(
      duration: Duration(milliseconds: 400 + (index * 100)),
      child: GestureDetector(
        onLongPress: () {
          HapticFeedback.mediumImpact();
          Clipboard.setData(ClipboardData(text: content));
          Get.snackbar(
            'Blessed!',
            'Message copied to clipboard',
            snackPosition: SnackPosition.TOP,
            backgroundColor: const Color(0xFF10B981).withOpacity(0.9),
            colorText: Colors.white,
            duration: const Duration(seconds: 2),
            borderRadius: 15,
            margin: const EdgeInsets.all(20),
          );
        },
        child: Padding(
          padding: EdgeInsets.only(bottom: constraints.maxHeight * 0.025),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isUser) _buildHolyAvatar(context, constraints, false),
              if (!isUser) SizedBox(width: constraints.maxWidth * 0.03),
              Expanded(
                child: Column(
                  crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    if (!isUser)
                      Padding(
                        padding: EdgeInsets.only(bottom: constraints.maxHeight * 0.01),
                        child: Row(
                          children: [
                            ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                              ).createShader(bounds),
                              child: Text(
                                'Jesus AI',
                                style: GoogleFonts.inter(
                                  fontSize: constraints.maxWidth * 0.035,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            SizedBox(width: constraints.maxWidth * 0.02),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'Biblical AI',
                                style: GoogleFonts.inter(
                                  fontSize: constraints.maxWidth * 0.025,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    Container(
                      constraints: BoxConstraints(maxWidth: constraints.maxWidth * 0.8),
                      padding: EdgeInsets.all(constraints.maxWidth * 0.045),
                      decoration: BoxDecoration(
                        gradient: isUser
                            ? const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                        )
                            : LinearGradient(
                          colors: [
                            const Color(0xFF1E1B3C).withOpacity(0.9),
                            const Color(0xFF2D1B69).withOpacity(0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isUser
                              ? const Color(0xFF8B5CF6).withOpacity(0.5)
                              : const Color(0xFFFFD700).withOpacity(0.3),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (isUser
                                ? const Color(0xFF6366F1)
                                : const Color(0xFFFFD700)).withOpacity(0.2),
                            blurRadius: 15,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: _buildFormattedText(content, constraints, isUser),
                    ),
                  ],
                ),
              ),
              if (isUser) SizedBox(width: constraints.maxWidth * 0.03),
              if (isUser) _buildHolyAvatar(context, constraints, true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormattedText(String content, BoxConstraints constraints, bool isUser) {
    final verseRegex = RegExp(r'([A-Za-z]+\s*\d+:\d+(?:\s*[-–]\s*\d+)?):?\s*(.*?)(?=\n|$)', multiLine: true);
    final matches = verseRegex.allMatches(content).toList();

    if (!isUser && matches.isNotEmpty) {
      return RichText(
        text: TextSpan(
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: constraints.maxWidth * 0.038,
            fontWeight: FontWeight.w400,
            height: 1.6,
          ),
          children: _parseVerseText(content, matches, constraints),
        ),
      );
    }

    return SelectableText(
      content,
      style: GoogleFonts.inter(
        color: Colors.white,
        fontSize: constraints.maxWidth * 0.038,
        fontWeight: FontWeight.w400,
        height: 1.6,
      ),
    );
  }

  List<TextSpan> _parseVerseText(String content, List<RegExpMatch> matches, BoxConstraints constraints) {
    final spans = <TextSpan>[];
    int lastEnd = 0;

    for (final match in matches) {
      if (lastEnd < match.start) {
        spans.add(TextSpan(text: content.substring(lastEnd, match.start)));
      }

      spans.add(TextSpan(
        text: '${match.group(1)}: ',
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w800,
          color: const Color(0xFFFFD700),
          fontSize: constraints.maxWidth * 0.038,
          shadows: [
            Shadow(
              color: const Color(0xFFFFD700).withOpacity(0.3),
              blurRadius: 5,
            ),
          ],
        ),
      ));

      if (match.group(2) != null) {
        spans.add(TextSpan(
          text: match.group(2),
          style: GoogleFonts.inter(
            fontStyle: FontStyle.italic,
            color: Colors.white.withOpacity(0.95),
            fontSize: constraints.maxWidth * 0.038,
          ),
        ));
      }

      lastEnd = match.end;
    }

    if (lastEnd < content.length) {
      spans.add(TextSpan(text: content.substring(lastEnd)));
    }

    return spans;
  }

  Widget _buildHolyAvatar(BuildContext context, BoxConstraints constraints, bool isUser) {
    return ZoomIn(
      duration: const Duration(milliseconds: 600),
      child: Container(
        width: constraints.maxWidth * 0.1,
        height: constraints.maxWidth * 0.1,
        decoration: BoxDecoration(
          gradient: isUser
              ? const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)])
              : const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA500)]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: (isUser ? const Color(0xFF6366F1) : const Color(0xFFFFD700)).withOpacity(0.4),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(
          isUser ? Icons.person_rounded : Icons.menu_book_rounded,
          color: Colors.white,
          size: constraints.maxWidth * 0.05,
        ),
      ),
    );
  }

  Widget _buildPrayerMessage(BuildContext context, BoxConstraints constraints) {
    return SlideInUp(
      duration: const Duration(milliseconds: 600),
      child: Padding(
        padding: EdgeInsets.only(bottom: constraints.maxHeight * 0.025),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHolyAvatar(context, constraints, false),
            SizedBox(width: constraints.maxWidth * 0.03),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(bottom: constraints.maxHeight * 0.01),
                    child: Row(
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                          ).createShader(bounds),
                          child: Text(
                            'Jesus AI',
                            style: GoogleFonts.inter(
                              fontSize: constraints.maxWidth * 0.035,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(width: constraints.maxWidth * 0.03),
                        _buildPrayerIndicator(constraints),
                      ],
                    ),
                  ),
                  Container(
                    constraints: BoxConstraints(maxWidth: constraints.maxWidth * 0.8),
                    padding: EdgeInsets.all(constraints.maxWidth * 0.045),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF1E1B3C).withOpacity(0.9),
                          const Color(0xFF2D1B69).withOpacity(0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFFFD700).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '🙏',
                          style: TextStyle(fontSize: constraints.maxWidth * 0.04),
                        ),
                        SizedBox(width: constraints.maxWidth * 0.03),
                        Text(
                          'Seeking Jesus wisdom...',
                          style: GoogleFonts.inter(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: constraints.maxWidth * 0.038,
                            fontWeight: FontWeight.w500,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrayerIndicator(BoxConstraints constraints) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return Bounce(
          duration: const Duration(milliseconds: 800),
          delay: Duration(milliseconds: index * 200),
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: constraints.maxWidth * 0.005),
            width: constraints.maxWidth * 0.015,
            height: constraints.maxWidth * 0.015,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFD700).withOpacity(0.5),
                  blurRadius: 5,
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildErrorDisplay(BuildContext context, BoxConstraints constraints) {
    return Obx(() => controller.errorMessage.value.isNotEmpty
        ? SlideInUp(
      duration: const Duration(milliseconds: 500),
      child: Container(
        margin: EdgeInsets.all(constraints.maxWidth * 0.05),
        padding: EdgeInsets.all(constraints.maxWidth * 0.04),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFEF4444).withOpacity(0.3),
              blurRadius: 15,
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_rounded, color: Colors.white),
            SizedBox(width: constraints.maxWidth * 0.03),
            Expanded(
              child: Text(
                controller.errorMessage.value,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: constraints.maxWidth * 0.035,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            GestureDetector(
              onTap: () => controller.errorMessage.value = '',
              child: const Icon(Icons.close_rounded, color: Colors.white),
            ),
          ],
        ),
      ),
    )
        : const SizedBox.shrink());
  }

  Widget _buildPrayerInputArea(BuildContext context, BoxConstraints constraints) {
    return SlideInUp(
      duration: const Duration(milliseconds: 800),
      child: Container(
        margin: EdgeInsets.all(constraints.maxWidth * 0.05),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1E1B3C), Color(0xFF2D1B69)],
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: const Color(0xFFFFD700).withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFD700).withOpacity(0.2),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller.textController,
                maxLines: null,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: constraints.maxWidth * 0.038,
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                ),
                decoration: InputDecoration(
                  hintText: 'Ask me about God\'s Word...',
                  hintStyle: GoogleFonts.inter(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: constraints.maxWidth * 0.038,
                    fontWeight: FontWeight.w400,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: constraints.maxWidth * 0.05,
                    vertical: constraints.maxHeight * 0.02,
                  ),
                ),
                onSubmitted: _sendMessage,
              ),
            ),
            _buildDivineSendButton(context, constraints),
            SizedBox(width: constraints.maxWidth * 0.02),
          ],
        ),
      ),
    );
  }

  Widget _buildDivineSendButton(BuildContext context, BoxConstraints constraints) {
    return Obx(() => Pulse(
      duration: controller.isStreaming.value
          ? const Duration(milliseconds: 1000)
          : const Duration(milliseconds: 2000),
      child: GestureDetector(
        onTap: controller.isStreaming.value
            ? null
            : () => _sendMessage(controller.textController.text),
        child: Container(
          width: constraints.maxWidth * 0.12,
          height: constraints.maxWidth * 0.12,
          decoration: BoxDecoration(
            gradient: controller.isStreaming.value
                ? LinearGradient(
              colors: [
                const Color(0xFF9333EA).withOpacity(0.7),
                const Color(0xFF7C3AED).withOpacity(0.7),
              ],
            )
                : const LinearGradient(
              colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: (controller.isStreaming.value
                    ? const Color(0xFF9333EA)
                    : const Color(0xFFFFD700)).withOpacity(0.4),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Icon(
            controller.isStreaming.value
                ? Icons.pause_rounded
                : Icons.send_rounded,
            color: Colors.white,
            size: constraints.maxWidth * 0.05,
          ),
        ),
      ),
    ));
  }

  void _sendMessage(String text) {
    final message = text.trim();
    if (message.isNotEmpty && !controller.isStreaming.value) {
      HapticFeedback.lightImpact();
      controller.sendMessage(message);
      controller.textController.clear();
    }
  }
}