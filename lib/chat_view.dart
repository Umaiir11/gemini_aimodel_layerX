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
      backgroundColor: const Color(0xFF0A0A0A),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              // Particle Layer 1: Subtle, fast-moving
              ParticlesFly(
                height: constraints.maxHeight,
                width: constraints.maxWidth,
                numberOfParticles: 80,
                speedOfParticles: 0.4,
                connectDots: true,
                lineColor: const Color(0xFF60A5FA).withOpacity(0.05),
                particleColor: const Color(0xFF60A5FA).withOpacity(0.2),

                onTapAnimation: true,
              ),
              // Particle Layer 2: Sparse, medium speed
              ParticlesFly(
                height: constraints.maxHeight,
                width: constraints.maxWidth,
                numberOfParticles: 50,
                speedOfParticles: 0.25,
                connectDots: false,
                lineColor: Colors.transparent,
                particleColor: const Color(0xFF1E3A8A).withOpacity(0.15),

                onTapAnimation: true,
              ),
              // Particle Layer 3: Minimal, slow-moving
              ParticlesFly(
                height: constraints.maxHeight,
                width: constraints.maxWidth,
                numberOfParticles: 10,
                speedOfParticles: 0.15,
                connectDots: false,
                lineColor: Colors.transparent,
                particleColor: const Color(0xFF60A5FA).withOpacity(0.1),

                onTapAnimation: true,
              ),
              SafeArea(
                child: Column(
                  children: [
                    _buildCompactHeader(context, constraints),
                    Expanded(child: _buildChatContainer(context, constraints)),
                    _buildInputArea(context, constraints),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCompactHeader(BuildContext context, BoxConstraints constraints) {
    return FadeInDown(
      duration: const Duration(milliseconds: 400),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: constraints.maxWidth * 0.04,
          vertical: constraints.maxHeight * 0.015,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Nexus AI',
              style: GoogleFonts.spaceGrotesk(
                fontSize: constraints.maxWidth * 0.05,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFFFFFFF),
                letterSpacing: -0.5,
              ),
            ),
            Obx(() => ZoomIn(
              duration: const Duration(milliseconds: 300),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: constraints.maxWidth * 0.03,
                  vertical: constraints.maxHeight * 0.008,
                ),
                decoration: BoxDecoration(
                  color: controller.isStreaming.value
                      ? const Color(0xFF1E3A8A).withOpacity(0.8)
                      : const Color(0xFF60A5FA).withOpacity(0.8),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  controller.isStreaming.value ? 'Thinking' : 'Online',
                  style: GoogleFonts.inter(
                    fontSize: constraints.maxWidth * 0.03,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFFFFFFF),
                  ),
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildChatContainer(BuildContext context, BoxConstraints constraints) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: constraints.maxWidth * 0.04,
        vertical: constraints.maxHeight * 0.01,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF1E3A8A).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF60A5FA).withOpacity(0.2),
          width: 1.0,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            Expanded(
              child: Obx(() => controller.messages.isEmpty && !controller.isStreaming.value
                  ? _buildWelcomeScreen(context, constraints)
                  : _buildMessagesList(context, constraints)),
            ),
            _buildErrorDisplay(context, constraints),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeScreen(BuildContext context, BoxConstraints constraints) {
    return FadeIn(
      duration: const Duration(milliseconds: 600),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Nexus AI',
              style: GoogleFonts.spaceGrotesk(
                fontSize: constraints.maxWidth * 0.07,
                fontWeight: FontWeight.w800,
                color: const Color(0xFFFFFFFF),
                letterSpacing: -0.8,
              ),
            ),
            SizedBox(height: constraints.maxHeight * 0.02),
            Text(
              'Ask anything to spark creativity!',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: constraints.maxWidth * 0.04,
                fontWeight: FontWeight.w400,
                color: const Color(0xFFFFFFFF).withOpacity(0.8),
                height: 1.5,
              ),
            ),
            SizedBox(height: constraints.maxHeight * 0.04),
            _buildSuggestionChips(context, constraints),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionChips(BuildContext context, BoxConstraints constraints) {
    final suggestions = [
      '✨ Quantum computing basics',
      '🎨 Write a story',
      '🚀 Tech trends 2025',
      '💡 Solve my problem',
    ];

    return Wrap(
      spacing: constraints.maxWidth * 0.03,
      runSpacing: constraints.maxHeight * 0.015,
      alignment: WrapAlignment.center,
      children: suggestions.map((suggestion) => ZoomIn(
        duration: const Duration(milliseconds: 500),
        child: GestureDetector(
          onTap: () {
            controller.textController.text = suggestion.substring(2);
            _sendMessage(suggestion.substring(2));
          },
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: constraints.maxWidth * 0.04,
              vertical: constraints.maxHeight * 0.01,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF1E3A8A),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF60A5FA).withOpacity(0.3),
                width: 1.0,
              ),
            ),
            child: Text(
              suggestion,
              style: GoogleFonts.inter(
                fontSize: constraints.maxWidth * 0.035,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFFFFFFF),
              ),
            ),
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildMessagesList(BuildContext context, BoxConstraints constraints) {
    return ListView.builder(
      controller: controller.scrollController,
      padding: EdgeInsets.all(constraints.maxWidth * 0.04),
      itemCount: controller.messages.length + (controller.isStreaming.value ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == controller.messages.length && controller.isStreaming.value) {
          return _buildStreamingMessage(context, constraints);
        }
        final message = controller.messages[index];
        return _buildMessageBubble(context, constraints, message.content, message.isUser, index);
      },
    );
  }

  Widget _buildMessageBubble(
      BuildContext context, BoxConstraints constraints, String content, bool isUser, int index) {
    return FadeInUp(
      duration: Duration(milliseconds: 250 + (index * 70)),
      child: GestureDetector(
        onPanUpdate: (details) {
          if (details.delta.dx > 10) {
            Clipboard.setData(ClipboardData(text: content));
            Get.snackbar(
              'Copied',
              'Message copied to clipboard',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: const Color(0xFF1E3A8A).withOpacity(0.8),
              colorText: const Color(0xFFFFFFFF),
              duration: const Duration(seconds: 2),
            );
          }
        },
        child: Padding(
          padding: EdgeInsets.only(bottom: constraints.maxHeight * 0.02),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isUser) _buildAvatar(context, constraints, false),
              if (!isUser) SizedBox(width: constraints.maxWidth * 0.03),
              Expanded(
                child: Column(
                  crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    if (!isUser)
                      Padding(
                        padding: EdgeInsets.only(bottom: constraints.maxHeight * 0.01),
                        child: Text(
                          'Nexus AI',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: constraints.maxWidth * 0.03,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF60A5FA),
                          ),
                        ),
                      ),
                    Container(
                      constraints: BoxConstraints(maxWidth: constraints.maxWidth * 0.75),
                      padding: EdgeInsets.all(constraints.maxWidth * 0.04),
                      decoration: BoxDecoration(
                        color: isUser ? const Color(0xFF1E3A8A) : const Color(0xFF0A0A0A).withOpacity(0.8),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isUser
                              ? const Color(0xFF60A5FA).withOpacity(0.3)
                              : const Color(0xFF60A5FA).withOpacity(0.2),
                          width: 1.0,
                        ),
                      ),
                      child: SelectableText(
                        content,
                        style: GoogleFonts.inter(
                          color: const Color(0xFFFFFFFF),
                          fontSize: constraints.maxWidth * 0.035,
                          fontWeight: FontWeight.w400,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (isUser) SizedBox(width: constraints.maxWidth * 0.03),
              if (isUser) _buildAvatar(context, constraints, true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(BuildContext context, BoxConstraints constraints, bool isUser) {
    return ElasticIn(
      duration: const Duration(milliseconds: 500),
      child: Container(
        width: constraints.maxWidth * 0.08,
        height: constraints.maxWidth * 0.08,
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFF60A5FA) : const Color(0xFF1E3A8A),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          isUser ? Icons.person_rounded : Icons.auto_awesome_rounded,
          color: const Color(0xFFFFFFFF),
          size: constraints.maxWidth * 0.04,
        ),
      ),
    );
  }

  Widget _buildStreamingMessage(BuildContext context, BoxConstraints constraints) {
    return FadeInUp(
      duration: const Duration(milliseconds: 400),
      child: Padding(
        padding: EdgeInsets.only(bottom: constraints.maxHeight * 0.02),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAvatar(context, constraints, false),
            SizedBox(width: constraints.maxWidth * 0.03),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(bottom: constraints.maxHeight * 0.01),
                    child: Row(
                      children: [
                        Text(
                          'Nexus AI',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: constraints.maxWidth * 0.03,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF60A5FA),
                          ),
                        ),
                        SizedBox(width: constraints.maxWidth * 0.02),
                        _buildTypingIndicator(),
                      ],
                    ),
                  ),
                  Container(
                    constraints: BoxConstraints(maxWidth: constraints.maxWidth * 0.75),
                    padding: EdgeInsets.all(constraints.maxWidth * 0.04),
                    child: Obx(() => SelectableText(
                      controller.streamedText.value.isEmpty
                          ? 'Crafting response...'
                          : controller.streamedText.value,
                      style: GoogleFonts.inter(
                        color: const Color(0xFFFFFFFF).withOpacity(0.9),
                        fontSize: constraints.maxWidth * 0.035,
                        fontWeight: FontWeight.w400,
                        height: 1.5,
                      ),
                    )),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return Bounce(
          duration: const Duration(milliseconds: 500),
          delay: Duration(milliseconds: index * 120),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            width: 5,
            height: 5,
            decoration: const BoxDecoration(
              color: Color(0xFF60A5FA),
              shape: BoxShape.circle,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildErrorDisplay(BuildContext context, BoxConstraints constraints) {
    return Obx(() => controller.errorMessage.value.isNotEmpty
        ? FadeIn(
      duration: const Duration(milliseconds: 400),
      child: Container(
        margin: EdgeInsets.all(constraints.maxWidth * 0.04),
        padding: EdgeInsets.all(constraints.maxWidth * 0.04),
        decoration: BoxDecoration(
          color: const Color(0xFFB91C1C).withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFB91C1C).withOpacity(0.4),
            width: 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: const Color(0xFFB91C1C),
              size: constraints.maxWidth * 0.05,
            ),
            SizedBox(width: constraints.maxWidth * 0.03),
            Expanded(
              child: Text(
                controller.errorMessage.value,
                style: GoogleFonts.inter(
                  color: const Color(0xFFB91C1C),
                  fontSize: constraints.maxWidth * 0.035,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            GestureDetector(
              onTap: () => controller.errorMessage.value = '',
              child: Icon(
                Icons.close_rounded,
                color: const Color(0xFFB91C1C),
                size: constraints.maxWidth * 0.04,
              ),
            ),
          ],
        ),
      ),
    )
        : const SizedBox.shrink());
  }

  Widget _buildInputArea(BuildContext context, BoxConstraints constraints) {
    return FadeInUp(
      duration: const Duration(milliseconds: 400),
      child: Container(
        margin: EdgeInsets.all(constraints.maxWidth * 0.04),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFF1E3A8A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF60A5FA).withOpacity(0.3),
            width: 1.0,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller.textController,
                maxLines: null,
                style: GoogleFonts.inter(
                  color: const Color(0xFFFFFFFF),
                  fontSize: constraints.maxWidth * 0.035,
                  fontWeight: FontWeight.w400,
                  height: 1.5,
                ),
                decoration: InputDecoration(
                  hintText: 'Ask away...',
                  hintStyle: GoogleFonts.inter(
                    color: const Color(0xFFFFFFFF).withOpacity(0.5),
                    fontSize: constraints.maxWidth * 0.035,
                    fontWeight: FontWeight.w400,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: constraints.maxWidth * 0.04,
                    vertical: constraints.maxHeight * 0.015,
                  ),
                ),
                textInputAction: TextInputAction.newline,
                onSubmitted: _sendMessage,
              ),
            ),
            _buildSendButton(context, constraints),
            SizedBox(width: constraints.maxWidth * 0.02),
          ],
        ),
      ),
    );
  }

  Widget _buildSendButton(BuildContext context, BoxConstraints constraints) {
    return Obx(() => ZoomIn(
      duration: const Duration(milliseconds: 300),
      child: GestureDetector(
        onTap: controller.isStreaming.value
            ? null
            : () => _sendMessage(controller.textController.text),
        child: Container(
          width: constraints.maxWidth * 0.08,
          height: constraints.maxWidth * 0.08,
          decoration: BoxDecoration(
            color: controller.isStreaming.value
                ? const Color(0xFF0A0A0A).withOpacity(0.8)
                : const Color(0xFF60A5FA),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.send_rounded,
            color: const Color(0xFFFFFFFF),
            size: constraints.maxWidth * 0.04,
          ),
        ),
      ),
    ));
  }

  void _sendMessage(String text) {
    final message = text.trim();
    if (message.isNotEmpty && !controller.isStreaming.value) {
      controller.sendMessage(message);
      controller.textController.clear();
    }
  }
}