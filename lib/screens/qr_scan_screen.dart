import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../theme.dart';
import 'home_screen.dart';
import 'voting_screen.dart';

/// Pantalla de escaneo QR.
///
/// Retorna el eventId (String) al hacer pop, o null si se cancela.
///
/// El QR del DJ tiene el formato:
///   https://dominio.com/votar/EVENT_UUID
///   o directamente EVENT_UUID
///
/// Setup requerido (se genera con `flutter create`):
///   Android: añadir en android/app/src/main/AndroidManifest.xml:
///     <uses-permission android:name="android.permission.CAMERA"/>
///   iOS: añadir en ios/Runner/Info.plist:
///     <key>NSCameraUsageDescription</key>
///     <string>Necesitamos la cámara para escanear el QR del evento</string>
class QrScanScreen extends StatefulWidget {
  final bool isHome;

  const QrScanScreen({super.key, this.isHome = false});

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  final _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );
  bool _handled = false;

  // UUID v4 estándar
  static final _uuidRegex = RegExp(
    r'[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}',
    caseSensitive: false,
  );

  // Patrón de URL del DJ: /votar/<uuid>
  static final _urlRegex = RegExp(
    r'/votar/([0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12})',
    caseSensitive: false,
  );

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;

    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw == null) continue;

      String? eventId;

      // Caso 1: URL con /votar/UUID
      final urlMatch = _urlRegex.firstMatch(raw);
      if (urlMatch != null) {
        eventId = urlMatch.group(1);
      }
      // Caso 2: UUID directo
      else if (_uuidRegex.hasMatch(raw)) {
        final match = _uuidRegex.firstMatch(raw);
        eventId = match?.group(0);
      }

      if (eventId != null) {
        _handled = true;
        _controller.stop();
        if (widget.isHome) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => VotingScreen(eventId: eventId!),
            ),
          );
        } else {
          Navigator.pop(context, eventId);
        }
        return;
      }
    }

    // QR no reconocido
    if (!_handled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('QR no reconocido — no es un evento MusicParty'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Escanear QR del evento'),
        leading: const BackButton(color: Colors.white),
      ),
      body: Stack(
        children: [
          // ── Vista de cámara ──────────────────────────────────────────────
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),

          // ── Marco de escaneo ─────────────────────────────────────────────
          Center(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.neonCyan, width: 2.5),
                borderRadius: BorderRadius.circular(16),
              ),
              // Esquinas decorativas
              child: Stack(
                children: _corners(),
              ),
            ),
          ),

          // ── Instrucción ───────────────────────────────────────────────────
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 48),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Apunta al código QR del evento',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  if (widget.isHome) ...[
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const HomeScreen(),
                        ),
                      ),
                      icon: const Icon(Icons.list_rounded, size: 18),
                      label: const Text('Ver lista de eventos'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.darkCard,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Esquinas decorativas del marco de escaneo.
  List<Widget> _corners() {
    const size = 20.0;
    const thickness = 3.0;
    const color = AppTheme.neonCyan;

    return [
      // Top-left
      Positioned(
        top: 0,
        left: 0,
        child: Container(
          width: size,
          height: thickness,
          color: color,
        ),
      ),
      Positioned(
        top: 0,
        left: 0,
        child: Container(
          width: thickness,
          height: size,
          color: color,
        ),
      ),
      // Top-right
      Positioned(
        top: 0,
        right: 0,
        child: Container(
          width: size,
          height: thickness,
          color: color,
        ),
      ),
      Positioned(
        top: 0,
        right: 0,
        child: Container(
          width: thickness,
          height: size,
          color: color,
        ),
      ),
      // Bottom-left
      Positioned(
        bottom: 0,
        left: 0,
        child: Container(
          width: size,
          height: thickness,
          color: color,
        ),
      ),
      Positioned(
        bottom: 0,
        left: 0,
        child: Container(
          width: thickness,
          height: size,
          color: color,
        ),
      ),
      // Bottom-right
      Positioned(
        bottom: 0,
        right: 0,
        child: Container(
          width: size,
          height: thickness,
          color: color,
        ),
      ),
      Positioned(
        bottom: 0,
        right: 0,
        child: Container(
          width: thickness,
          height: size,
          color: color,
        ),
      ),
    ];
  }
}
