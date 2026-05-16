// lib/features/scanner/presentation/screens/scanner_screen.dart
//
//  Integra mobile_scanner para lectura real de QR.
//  Flujo:
//    1. Cámara activa con MobileScanner
//    2. Al detectar un QR → muestra bottom sheet con el resultado
//    3. Botón de linterna funcional
//    4. Back → context.go(AppRoutes.home)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../core/constants/app_constants.dart';

class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  // ── Scanner controller ────────────────────────────────────────────────────
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );

  bool _torchOn = false;
  bool _escaneado = false; // evita procesar múltiples lecturas simultáneas

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  // ── Toggle linterna ───────────────────────────────────────────────────────
  Future<void> _toggleTorch() async {
    await _scannerController.toggleTorch();
    setState(() => _torchOn = !_torchOn);
  }

  // ── Callback al detectar un QR ────────────────────────────────────────────
  void _onDetect(BarcodeCapture capture) {
    if (_escaneado) return;

    final Barcode? barcode = capture.barcodes.firstOrNull;
    final String? valor = barcode?.rawValue;

    if (valor != null && valor.isNotEmpty) {
      _escaneado = true;
      HapticFeedback.mediumImpact();

      // Pausa la cámara mientras se muestra el resultado
      _scannerController.stop();
      _mostrarResultado(valor);
    }
  }

  // ── Bottom sheet con el resultado ─────────────────────────────────────────
// ── Reemplaza _mostrarResultado ───────────────────────────────────────────
  void _mostrarResultado(String contenido) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (_) => _ResultadoDialog(
        contenido: contenido,
        onEscanearOtro: () {
          Navigator.pop(context);
          setState(() => _escaneado = false);
          _scannerController.start();
        },
        onCerrar: () => context.go(AppRoutes.home),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Cámara real ─────────────────────────────────────────────────
          MobileScanner(
            controller: _scannerController,
            onDetect: _onDetect,
          ),

          // ── Overlay oscuro alrededor del frame ──────────────────────────
          const _ScanOverlay(),

          // ── Marco QR (esquinas verdes) ──────────────────────────────────
          Center(
            child: SizedBox(
              width: 260,
              height: 260,
              child: CustomPaint(painter: _QRFramePainter()),
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
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  _ScannerIconButton(
                    icon: _torchOn
                        ? Icons.flashlight_on_rounded
                        : Icons.flashlight_off_rounded,
                    onTap: _toggleTorch,
                  ),
                ],
              ),
            ),
          ),

          // ── Bottom hint (sin chips) ──────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(
                AppDimens.lg,
                AppDimens.xl,
                AppDimens.lg,
                AppDimens.xl,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.80),
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
                    const SizedBox(height: 6),
                    Text(
                      'La cámara detectará el código automáticamente',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white54,
                      ),
                      textAlign: TextAlign.center,
                    ),
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

// ─────────────────────────────────────────────────────────────────────────────
//  OVERLAY — oscurece todo excepto el área del frame QR
// ─────────────────────────────────────────────────────────────────────────────
class _ScanOverlay extends StatelessWidget {
  const _ScanOverlay();

  static const double _frameSize = 260.0;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final half = _frameSize / 2;

    return CustomPaint(
      size: size,
      painter: _OverlayPainter(
        frameRect: Rect.fromLTRB(
          centerX - half,
          centerY - half,
          centerX + half,
          centerY + half,
        ),
      ),
    );
  }
}

class _OverlayPainter extends CustomPainter {
  final Rect frameRect;
  const _OverlayPainter({required this.frameRect});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withOpacity(0.55);
    final fullRect = Rect.fromLTWH(0, 0, size.width, size.height);

    final path = Path()
      ..addRect(fullRect)
      ..addRRect(RRect.fromRectAndRadius(frameRect, const Radius.circular(16)))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_OverlayPainter oldDelegate) =>
      oldDelegate.frameRect != frameRect;
}

// ─────────────────────────────────────────────────────────────────────────────
//  RESULTADO DIALOG — modal centrado
// ─────────────────────────────────────────────────────────────────────────────
class _ResultadoDialog extends StatelessWidget {
  final String contenido;
  final VoidCallback onEscanearOtro;
  final VoidCallback onCerrar;

  const _ResultadoDialog({
    required this.contenido,
    required this.onEscanearOtro,
    required this.onCerrar,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(AppDimens.lg),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppDimens.radiusXl),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Ícono de éxito ───────────────────────────────────────────
            Container(
              width: 68,
              height: 68,
              decoration: const BoxDecoration(
                color: AppColors.primarySurface,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: AppColors.primary,
                size: 38,
              ),
            ),
            const SizedBox(height: AppDimens.md),

            // ── Título ───────────────────────────────────────────────────
            Text(
              '¡QR detectado!',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppDimens.sm),

            Text(
              'Contenido del código escaneado',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textPrimary.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: AppDimens.md),

            // ── Contenido escaneado ──────────────────────────────────────
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxHeight: 120),
              padding: const EdgeInsets.all(AppDimens.md),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                border: Border.all(color: const Color(0xFFE2ECE7)),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  contenido,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontFamily: 'monospace',
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: AppDimens.lg),

            // ── Acciones ─────────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onEscanearOtro,
                    child: const Text('Escanear otro'),
                  ),
                ),
                const SizedBox(width: AppDimens.md),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onCerrar,
                    child: const Text('Continuar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  SCANNER ICON BUTTON
// ─────────────────────────────────────────────────────────────────────────────
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
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  QR FRAME PAINTER — Esquinas redondeadas verdes
// ─────────────────────────────────────────────────────────────────────────────
class _QRFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const cornerLen = 36.0;
    const r = 14.0;

    // Top-left
    canvas.drawLine(const Offset(r, 0), const Offset(cornerLen, 0), paint);
    canvas.drawLine(const Offset(0, r), const Offset(0, cornerLen), paint);
    canvas.drawArc(const Rect.fromLTWH(0, 0, r * 2, r * 2), 3.14159,
        3.14159 / 2, false, paint);

    // Top-right
    canvas.drawLine(
        Offset(size.width - cornerLen, 0), Offset(size.width - r, 0), paint);
    canvas.drawLine(
        Offset(size.width, r), Offset(size.width, cornerLen), paint);
    canvas.drawArc(Rect.fromLTWH(size.width - r * 2, 0, r * 2, r * 2),
        3.14159 * 1.5, 3.14159 / 2, false, paint);

    // Bottom-left
    canvas.drawLine(
        Offset(0, size.height - cornerLen), Offset(0, size.height - r), paint);
    canvas.drawLine(
        Offset(r, size.height), Offset(cornerLen, size.height), paint);
    canvas.drawArc(Rect.fromLTWH(0, size.height - r * 2, r * 2, r * 2),
        3.14159 / 2, 3.14159 / 2, false, paint);

    // Bottom-right
    canvas.drawLine(Offset(size.width - cornerLen, size.height),
        Offset(size.width - r, size.height), paint);
    canvas.drawLine(Offset(size.width, size.height - cornerLen),
        Offset(size.width, size.height - r), paint);
    canvas.drawArc(
        Rect.fromLTWH(size.width - r * 2, size.height - r * 2, r * 2, r * 2),
        0,
        3.14159 / 2,
        false,
        paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
