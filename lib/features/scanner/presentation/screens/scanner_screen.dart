// lib/features/scanner/presentation/screens/scanner_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';

class ScannerScreen extends ConsumerWidget {
  const ScannerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Camera Placeholder ──────────────────────────────────────────
          Container(
            width: size.width,
            height: size.height,
            color: const Color(0xFF0A1A0D),
            child: const Center(
              child: Icon(
                Icons.camera_alt_rounded,
                size: 80,
                color: Color(0xFF1A3A1F),
              ),
            ),
          ),

          // ── QR Frame Overlay ────────────────────────────────────────────
          Center(
            child: SizedBox(
              width: 260,
              height: 260,
              child: CustomPaint(
                painter: _QRFramePainter(),
              ),
            ),
          ),

          // ── Top Bar ─────────────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppDimens.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _ScannerIconButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => context.go(AppRoutes.home),
                  ),
                  Text(
                    'Escanear QR',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  _ScannerIconButton(
                    icon: Icons.flash_off_rounded,
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ),

          // ── Bottom Info ─────────────────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(AppDimens.lg),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.85),
                  ],
                ),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Acerca el QR del Oscarito',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'La IA clasificará tus residuos en tiempo real',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white60,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppDimens.lg),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _FeatureChip(
                          label: 'IA en tiempo real',
                          icon: Icons.auto_awesome_rounded,
                        ),
                        const SizedBox(width: 8),
                        _FeatureChip(
                          label: 'Jackpot',
                          icon: Icons.casino_rounded,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimens.xl),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScannerIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _ScannerIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final String label;
  final IconData icon;
  const _FeatureChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.25),
        borderRadius: BorderRadius.circular(AppDimens.radiusFull),
        border: Border.all(color: AppColors.primary.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.primaryLight, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.primaryLight,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── QR Corner Frame Painter ──────────────────────────────────────────────────
class _QRFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const cornerLen = 32.0;
    const radius = 12.0;

    // Top-left
    canvas.drawLine(const Offset(radius, 0), const Offset(cornerLen, 0), paint);
    canvas.drawLine(const Offset(0, radius), const Offset(0, cornerLen), paint);
    canvas.drawArc(const Rect.fromLTWH(0, 0, radius * 2, radius * 2), 3.14159,
        3.14159 / 2, false, paint);

    // Top-right
    canvas.drawLine(Offset(size.width - cornerLen, 0),
        Offset(size.width - radius, 0), paint);
    canvas.drawLine(
        Offset(size.width, radius), Offset(size.width, cornerLen), paint);
    canvas.drawArc(
        Rect.fromLTWH(size.width - radius * 2, 0, radius * 2, radius * 2),
        3.14159 * 1.5,
        3.14159 / 2,
        false,
        paint);

    // Bottom-left
    canvas.drawLine(Offset(0, size.height - cornerLen),
        Offset(0, size.height - radius), paint);
    canvas.drawLine(
        Offset(radius, size.height), Offset(cornerLen, size.height), paint);
    canvas.drawArc(
        Rect.fromLTWH(0, size.height - radius * 2, radius * 2, radius * 2),
        3.14159 / 2,
        3.14159 / 2,
        false,
        paint);

    // Bottom-right
    canvas.drawLine(Offset(size.width - cornerLen, size.height),
        Offset(size.width - radius, size.height), paint);
    canvas.drawLine(Offset(size.width, size.height - cornerLen),
        Offset(size.width, size.height - radius), paint);
    canvas.drawArc(
        Rect.fromLTWH(size.width - radius * 2, size.height - radius * 2,
            radius * 2, radius * 2),
        0,
        3.14159 / 2,
        false,
        paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
