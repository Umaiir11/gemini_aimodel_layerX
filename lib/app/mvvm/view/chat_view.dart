import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:particles_fly/particles_fly.dart';

import '../../widget.dart';
import '../view_model/chat_controller.dart';

class AIChatView extends StatefulWidget {
  const AIChatView({super.key});

  @override
  _AIChatViewState createState() => _AIChatViewState();
}

class _AIChatViewState extends State<AIChatView> with SingleTickerProviderStateMixin {
  final AIChatController _aiController = Get.find();
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0B1E),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                // Background Gradient
                Container(
                  decoration: const BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.topCenter,
                      radius: 1.5,
                      colors: [Color(0xFF2D1B69), Color(0xFF0D0B1E), Color(0xFF000000)],
                    ),
                  ),
                ),
                // Particle Effects
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
                      Expanded(child: _buildBotInteractionArea(context, constraints)),
                      _buildErrorDisplay(context, constraints),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElasticIn(
              duration: const Duration(milliseconds: 1200),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA500)]),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFFFFD700).withOpacity(0.3), blurRadius: 15, spreadRadius: 2),
                  ],
                ),
                child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
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
                    'Speak to Receive Biblical Wisdom',
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
      ),
    );
  }

  Widget _buildBotInteractionArea(BuildContext context, BoxConstraints constraints) {
    return Center(
      child: Obx(
            () => _aiController.isRecording.value
            ? _buildRecordingIndicator(context, constraints)
            : _aiController.isSpeaking.value
            ? _buildSpeakingBot(context, constraints)
            : _buildVoiceButton(context, constraints),
      ),
    );
  }

  Widget _buildVoiceButton(BuildContext context, BoxConstraints constraints) {
    return GestureDetector(
      onLongPress: () {
        if (!_aiController.isStreaming.value &&
            !_aiController.errorMessage.value.contains('Speech recognition not available')) {
          HapticFeedback.heavyImpact();
          _aiController.startRecording();
        }
      },
      child: ScaleTransition(
        scale: Tween(begin: 0.95, end: 1.05).animate(_pulseController),
        child: Container(
          width: constraints.maxWidth * 0.3,
          height: constraints.maxWidth * 0.3,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withOpacity(0.4),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Icon(
            Icons.mic_none,
            color: Colors.white,
            size: constraints.maxWidth * 0.1,
          ),
        ),
      ),
    );
  }

  Widget _buildRecordingIndicator(BuildContext context, BoxConstraints constraints) {
    return Pulse(
      duration: const Duration(milliseconds: 800),
      child: Container(
        width: constraints.maxWidth * 0.3,
        height: constraints.maxWidth * 0.3,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFDC2626)]),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFEF4444).withOpacity(0.4),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.mic,
              color: Colors.white,
              size: constraints.maxWidth * 0.1,
            ),
            SizedBox(height: constraints.maxHeight * 0.01),
            Text(
              'Listening...',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: constraints.maxWidth * 0.04,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpeakingBot(BuildContext context, BoxConstraints constraints) {
    return ScaleTransition(
      scale: Tween(begin: 0.9, end: 1.1).animate(_pulseController),
      child: Container(
        width: constraints.maxWidth * 0.4,
        height: constraints.maxWidth * 0.4,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA500)]),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFD700).withOpacity(0.4),
              blurRadius: 30,
              spreadRadius: 10,
            ),
          ],
        ),
        child: Icon(
          Icons.menu_book_rounded,
          color: Colors.white,
          size: constraints.maxWidth * 0.15,
        ),
      ),
    );
  }

  Widget _buildErrorDisplay(BuildContext context, BoxConstraints constraints) {
    return Obx(
          () => _aiController.errorMessage.value.isNotEmpty
          ? SlideInUp(
        duration: const Duration(milliseconds: 500),
        child: Container(
          margin: EdgeInsets.all(constraints.maxWidth * 0.05),
          padding: EdgeInsets.all(constraints.maxWidth * 0.04),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFDC2626)]),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: const Color(0xFFEF4444).withOpacity(0.3), blurRadius: 15),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.warning_rounded, color: Colors.white),
              SizedBox(width: constraints.maxWidth * 0.03),
              Expanded(
                child: Text(
                  _aiController.errorMessage.value +
                      (_aiController.errorMessage.value.contains('TTS')
                          ? '\nTry installing Google Text-to-Speech or check TTS settings.'
                          : _aiController.errorMessage.value.contains('Speech recognition')
                          ? '\nTry installing Google Speech Services or check device settings.'
                          : ''),
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: constraints.maxWidth * 0.035,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => _aiController.errorMessage.value = '',
                child: const Icon(Icons.close_rounded, color: Colors.white),
              ),
            ],
          ),
        ),
      )
          : const SizedBox.shrink(),
    );
  }
}