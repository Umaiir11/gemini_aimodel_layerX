import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:particles_fly/particles_fly.dart';

import '../../widget.dart';
import '../view_model/chat_controller.dart';
// Add this import at the top of the file
import 'dart:math' as math;
class AIChatView extends StatefulWidget {
  const AIChatView({super.key});

  @override
  _AIChatViewState createState() => _AIChatViewState();
}

class _AIChatViewState extends State<AIChatView> with TickerProviderStateMixin {
  final AIChatController _aiController = Get.find();
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late AnimationController _robotController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _waveController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    _robotController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    _robotController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                // Dark gradient background like Siri
                Container(
                  decoration: const BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 1.2,
                      colors: [
                        Color(0xFF1A1A1A),
                        Color(0xFF0A0A0A),
                        Color(0xFF000000),
                      ],
                    ),
                  ),
                ),
                // Subtle particle effects
                ParticlesFly(
                  height: constraints.maxHeight,
                  width: constraints.maxWidth,
                  numberOfParticles: 80,
                  speedOfParticles: 0.2,
                  connectDots: true,
                  lineColor: Colors.blue.withOpacity(0.05),
                  particleColor: Colors.blue.withOpacity(0.15),
                  onTapAnimation: true,
                ),
                SafeArea(
                  child: Column(
                    children: [
                      _buildMinimalHeader(context, constraints),
                      Expanded(child: _buildMainInteractionArea(context, constraints)),
                      _buildBottomPrompt(context, constraints),
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

  Widget _buildMinimalHeader(BuildContext context, BoxConstraints constraints) {
    return FadeInDown(
      duration: const Duration(milliseconds: 600),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: constraints.maxHeight * 0.02),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.5),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainInteractionArea(BuildContext context, BoxConstraints constraints) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Main interaction element
          Obx(() => _aiController.isRecording.value
              ? _buildRecordingRobot(context, constraints)
              : _aiController.isSpeaking.value
              ? _buildSpeakingVisualizer(context, constraints)
              : _buildSiriButton(context, constraints)),

          SizedBox(height: constraints.maxHeight * 0.08),

          // Status text
          Obx(() => _buildStatusText(context, constraints)),
        ],
      ),
    );
  }

  Widget _buildSiriButton(BuildContext context, BoxConstraints constraints) {
    return GestureDetector(
      onTap: () {
        if (!_aiController.isStreaming.value &&
            !_aiController.errorMessage.value.contains('Speech recognition not available')) {
          HapticFeedback.lightImpact();
          _aiController.startRecording();
        }
      },
      child: ZoomIn(
        duration: const Duration(milliseconds: 800),
        child: Container(
          width: constraints.maxWidth * 0.35,
          height: constraints.maxWidth * 0.35,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.blue.withOpacity(0.8),
                Colors.purple.withOpacity(0.8),
                Colors.pink.withOpacity(0.8),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.3),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Transform.scale(
                scale: 1.0 + (_pulseController.value * 0.05),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.blue.withOpacity(0.9),
                        Colors.purple.withOpacity(0.9),
                        Colors.pink.withOpacity(0.9),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.mic_none_rounded,
                      size: constraints.maxWidth * 0.12,
                      color: Colors.white,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildRecordingRobot(BuildContext context, BoxConstraints constraints) {
    return SlideInUp(
      duration: const Duration(milliseconds: 400),
      child: Column(
        children: [
          // Animated asset image
          AnimatedBuilder(
            animation: _robotController,
            builder: (context, child) {
              return Transform.scale(
                scale: 1.0 + (_robotController.value * 0.1),
                child: Container(
                  width: constraints.maxWidth * 0.4,
                  height: constraints.maxWidth * 0.4,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.cyan.withOpacity(0.8),
                        Colors.blue.withOpacity(0.9),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.cyan.withOpacity(0.4),
                        blurRadius: 40,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/baba.png',
                      fit: BoxFit.contain, // Changed to contain to show full image
                      width: constraints.maxWidth * 0.4,
                      height: constraints.maxWidth * 0.4,
                    ),
                  ),
                ),
              );
            },
          ),
          SizedBox(height: constraints.maxHeight * 0.03),
          // Sound wave visualization
          _buildSoundWaves(context, constraints),
        ],
      ),
    );
  }  Widget _buildSoundWaves(BuildContext context, BoxConstraints constraints) {
    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            double height = 4 + (20 * (0.5 + 0.5 *
                math.sin((_waveController.value * 2 * math.pi) + (index * 0.5))));
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 3,
              height: height,
              decoration: BoxDecoration(
                color: Colors.cyan,
                borderRadius: BorderRadius.circular(2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.cyan.withOpacity(0.5),
                    blurRadius: 5,
                  ),
                ],
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildSpeakingVisualizer(BuildContext context, BoxConstraints constraints) {
    return SlideInUp(
      duration: const Duration(milliseconds: 400),
      child: Container(
        width: constraints.maxWidth * 0.35,
        height: constraints.maxWidth * 0.35,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [
              Colors.green.withOpacity(0.8),
              Colors.teal.withOpacity(0.9),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.4),
              blurRadius: 30,
              spreadRadius: 10,
            ),
          ],
        ),
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Transform.scale(
              scale: 1.0 + (_pulseController.value * 0.15),
              child: Icon(
                Icons.volume_up_rounded,
                size: constraints.maxWidth * 0.12,
                color: Colors.white,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatusText(BuildContext context, BoxConstraints constraints) {
    String statusText = '';
    Color textColor = Colors.white70;

    if (_aiController.isRecording.value) {
      statusText = 'Veritas AI is listening...';
      textColor = Colors.cyan;
    } else if (_aiController.isSpeaking.value) {
      statusText = 'Veritas AI is speaking...';
      textColor = Colors.green;
    } else {
      statusText = 'Tap to speak to Veritas AI';
      textColor = Colors.white70;
    }

    return FadeInUp(
      duration: const Duration(milliseconds: 600),
      child: Text(
        statusText,
        style: GoogleFonts.inter(
          fontSize: constraints.maxWidth * 0.045,
          color: textColor,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
  Widget _buildBottomPrompt(BuildContext context, BoxConstraints constraints) {
    return Obx(() => !_aiController.isRecording.value && !_aiController.isSpeaking.value
        ? FadeInUp(
      duration: const Duration(milliseconds: 800),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: constraints.maxWidth * 0.1,
          vertical: constraints.maxHeight * 0.03,
        ),
        child: Text(
          'Ask me anything about faith, wisdom, or guidance',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: constraints.maxWidth * 0.038,
            color: Colors.white54,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    )
        : const SizedBox.shrink());
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
            color: Colors.red.withOpacity(0.1),
            border: Border.all(color: Colors.red.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.error_outline_rounded,
                  color: Colors.red, size: constraints.maxWidth * 0.06),
              SizedBox(width: constraints.maxWidth * 0.03),
              Expanded(
                child: Text(
                  _aiController.errorMessage.value,
                  style: GoogleFonts.inter(
                    color: Colors.red,
                    fontSize: constraints.maxWidth * 0.035,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => _aiController.errorMessage.value = '',
                child: Icon(Icons.close_rounded,
                    color: Colors.red, size: constraints.maxWidth * 0.05),
              ),
            ],
          ),
        ),
      )
          : const SizedBox.shrink(),
    );
  }
}

