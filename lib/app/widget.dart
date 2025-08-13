import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';

class VoiceRecordingWidget extends StatefulWidget {
  final VoidCallback onCancel;
  final VoidCallback onStop;
  final bool isRecording;

  const VoiceRecordingWidget({
    super.key,
    required this.onCancel,
    required this.onStop,
    required this.isRecording,
  });

  @override
  _VoiceRecordingWidgetState createState() => _VoiceRecordingWidgetState();
}

class _VoiceRecordingWidgetState extends State<VoiceRecordingWidget> with SingleTickerProviderStateMixin {
  List<double> _barHeights = List.generate(20, (_) => 10.0);
  Timer? _animationTimer;
  Duration _recordingDuration = Duration.zero;
  Timer? _durationTimer;

  @override
  void initState() {
    super.initState();
    if (widget.isRecording) {
      _startAnimation();
      _startTimer();
    }
  }

  @override
  void didUpdateWidget(covariant VoiceRecordingWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRecording && !oldWidget.isRecording) {
      _startAnimation();
      _startTimer();
    } else if (!widget.isRecording && oldWidget.isRecording) {
      _stopAnimation();
      _stopTimer();
    }
  }

  void _startAnimation() {
    _animationTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() {
        _barHeights = List.generate(20, (_) => 5.0 + (10.0 * (0.5 + 0.5 * (DateTime.now().millisecondsSinceEpoch % 1000 / 1000))));
      });
    });
  }

  void _startTimer() {
    _recordingDuration = Duration.zero;
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _recordingDuration += const Duration(seconds: 1);
      });
    });
  }

  void _stopAnimation() {
    _animationTimer?.cancel();
    _animationTimer = null;
    setState(() {
      _barHeights = List.generate(20, (_) => 10.0);
    });
  }

  void _stopTimer() {
    _durationTimer?.cancel();
    _durationTimer = null;
    setState(() {
      _recordingDuration = Duration.zero;
    });
  }

  @override
  void dispose() {
    _animationTimer?.cancel();
    _durationTimer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final constraints = BoxConstraints(
      maxWidth: MediaQuery.of(context).size.width,
      maxHeight: MediaQuery.of(context).size.height,
    );

    return SlideInUp(
      duration: const Duration(milliseconds: 400),
      child: Container(
        margin: EdgeInsets.all(constraints.maxWidth * 0.05),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFD700).withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          children: [
            Pulse(
              duration: const Duration(milliseconds: 800),
              child: Container(
                width: constraints.maxWidth * 0.12,
                height: constraints.maxWidth * 0.12,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color(0xFFEF4444).withOpacity(0.9), const Color(0xFFDC2626).withOpacity(0.9)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFEF4444).withOpacity(0.5),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.mic,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
            SizedBox(width: constraints.maxWidth * 0.03),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: List.generate(
                  20,
                      (index) => Container(
                    width: 3,
                    height: _barHeights[index],
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                      ),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: constraints.maxWidth * 0.03),
            Text(
              _formatDuration(_recordingDuration),
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: constraints.maxWidth * 0.038,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: constraints.maxWidth * 0.03),
            GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                widget.onCancel();
              },
              child: Container(
                width: constraints.maxWidth * 0.12,
                height: constraints.maxWidth * 0.12,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.grey.shade600, Colors.grey.shade800],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.4),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
            SizedBox(width: constraints.maxWidth * 0.02),
          ],
        ),
      ),
    );
  }
}