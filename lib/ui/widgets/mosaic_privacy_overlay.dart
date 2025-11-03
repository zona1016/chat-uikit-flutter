import 'dart:math';
import 'package:flutter/material.dart';
import 'package:tencent_cloud_chat_uikit/tencent_cloud_chat_uikit.dart';

class MosaicPrivacyOverlay extends StatefulWidget {
  final Widget child;
  final bool isVisible;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;
  final String? vanishIconType; // 'file', 'text', 'image', 'video', 'sound'
  final int? burnSeconds;

  const MosaicPrivacyOverlay({
    Key? key,
    required this.child,
    required this.isVisible,
    this.onTap,
    this.borderRadius,
    this.vanishIconType,
    this.burnSeconds,
  }) : super(key: key);

  @override
  State<MosaicPrivacyOverlay> createState() => _MosaicPrivacyOverlayState();
}

class _MosaicPrivacyOverlayState extends State<MosaicPrivacyOverlay>
    with TickerProviderStateMixin {
  late AnimationController _mosaicController;
  late Animation<double> _mosaicAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize mosaic animation
    _mosaicController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    _mosaicAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mosaicController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _mosaicController.dispose();
    super.dispose();
  }

  String _getVanishIconPath(String iconType) {
    switch (iconType.toLowerCase()) {
      case 'file':
        return 'images/vanish_file.png';
      case 'text':
        return 'images/vanish_text.png';
      case 'image':
        return 'images/vanish_img.png';
      case 'video':
        return 'images/vanish_video.png';
      case 'sound':
        return 'images/vanish_sound.png';
      default:
        return 'images/vanish_icon.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (widget.isVisible)
          Positioned.fill(
            child: GestureDetector(
              onTap: widget.onTap,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: widget.borderRadius,
                ),
                constraints: const BoxConstraints(
                  minWidth: 140,
                  minHeight: 80,
                ),
                child: Stack(
                  children: [
                    // Starry night background - ensure it fills the entire container
                    Positioned.fill(
                      child: CustomPaint(
                        painter: MosaicPainter(
                          animation: _mosaicAnimation,
                        ),
                      ),
                    ),
                    // Click to view text in center with proper padding to avoid overlap
                    Positioned(
                      left: 16,
                      right: 60, // Reserve space for top-right icon
                      top: 30,
                      bottom: 16,
                      child: Center(
                        child: Text(
                          TIM_t("点击查看"),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    // Vanish icon and burn seconds at top right
                    if (widget.vanishIconType != null)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              _getVanishIconPath(widget.vanishIconType!),
                              package: 'tencent_cloud_chat_uikit',
                              width: 16,
                              height: 14,
                            ),
                            if (widget.burnSeconds != null) ...[
                              const SizedBox(width: 4),
                              Text(
                                '${widget.burnSeconds}s',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class MosaicPainter extends CustomPainter {
  final Animation<double> animation;

  MosaicPainter({required this.animation}) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Create starry night sky effect with reduced density
    const starSpacing = 25.0; // Much larger spacing between stars
    final rows = (size.height / starSpacing).ceil();
    final cols = (size.width / starSpacing).ceil();

    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < cols; j++) {
        // Create stable random seed for each star position
        final baseSeed = i * cols + j;
        final starRandom = Random(baseSeed);
        
        // Only show stars at 90% of positions for very dense starry effect  
        if (starRandom.nextDouble() > 0.1) {
          // Random position within the cell for natural star distribution
          final baseX = j * starSpacing + starRandom.nextDouble() * starSpacing;
          final baseY = i * starSpacing + starRandom.nextDouble() * starSpacing;
          
          // Gentle twinkling movement (much smaller than before)
          const twinkleRange = 1.5;
          final twinkleX = sin((animation.value * 2 * pi) + starRandom.nextDouble() * 2 * pi) * twinkleRange;
          final twinkleY = cos((animation.value * 2 * pi) + starRandom.nextDouble() * 2 * pi) * twinkleRange;
          
          final x = baseX + twinkleX;
          final y = baseY + twinkleY;
          
          // Keep stars within bounds
          if (x >= 0 && x < size.width - 3 && y >= 0 && y < size.height - 3) {
            // Create twinkling effect with varying opacity and size
            final twinklePhase = (animation.value * 3 * pi + baseSeed) % (2 * pi);
            final twinkleIntensity = (sin(twinklePhase) + 1) / 2;
            final opacity = 0.4 + twinkleIntensity * 0.6;
            
            // Varying star sizes for more natural look
            final starSize = 1.5 + twinkleIntensity * 1.5;
            
            paint.color = Colors.white.withValues(alpha: opacity);
            
            // Draw stars as small circles instead of squares for better star effect
            canvas.drawCircle(
              Offset(x + starSize / 2, y + starSize / 2),
              starSize / 2,
              paint,
            );
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}