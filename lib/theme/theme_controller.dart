import 'dart:math' as math;
import 'package:flutter/material.dart';

class EleesaPalette {
  final bool isDark;
  final Color canvas;
  final Color surface;
  final Color surfaceElevated;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color accent;

  const EleesaPalette({
    required this.isDark,
    required this.canvas,
    required this.surface,
    required this.surfaceElevated,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.accent,
  });

  factory EleesaPalette.obsidian({Color accent = const Color(0xFF00E5FF)}) {
    return EleesaPalette(
      isDark: true,
      canvas: const Color(0xFF0E1116),
      surface: const Color(0xFF161A22),
      surfaceElevated: const Color(0xFF1E2430),
      border: const Color(0xFF262C3A),
      textPrimary: const Color(0xFFF3F6FA),
      textSecondary: const Color(0xFF94A3B8),
      accent: accent,
    );
  }

  factory EleesaPalette.daylight({Color accent = const Color(0xFF0284C7)}) {
    return EleesaPalette(
      isDark: false,
      canvas: const Color(0xFFF3F6FA),
      surface: Colors.white,
      surfaceElevated: const Color(0xFFE8EEF6),
      border: const Color(0xFFD5DCE6),
      textPrimary: const Color(0xFF0F172A),
      textSecondary: const Color(0xFF475569),
      accent: accent,
    );
  }
}

class EleesaThemeController extends ChangeNotifier {
  bool _isDark = true;
  bool _publicInDirectory = true;
  bool _notifyNotices = true;
  bool _notifyTimetable = true;

  bool get isDark => _isDark;
  bool get publicInDirectory => _publicInDirectory;
  bool get notifyNotices => _notifyNotices;
  bool get notifyTimetable => _notifyTimetable;

  void toggleTheme() {
    _isDark = !_isDark;
    notifyListeners();
  }

  void setDarkMode(bool value) {
    if (_isDark == value) return;
    _isDark = value;
    notifyListeners();
  }

  void setPublicInDirectory(bool value) {
    _publicInDirectory = value;
    notifyListeners();
  }

  void setNotifyNotices(bool value) {
    _notifyNotices = value;
    notifyListeners();
  }

  void setNotifyTimetable(bool value) {
    _notifyTimetable = value;
    notifyListeners();
  }

  Color accentForRole(String roleKey) {
    if (roleKey == 'hod_admin' || roleKey == 'hodAdmin') {
      return const Color(0xFF10B981); // Grid Emerald
    }
    if (roleKey == 'lecturer') {
      return const Color(0xFFF59E0B); // 3-Phase Amber
    }
    return _isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7); // Electric Cyan
  }

  EleesaPalette paletteForRole(String roleKey) {
    final accent = accentForRole(roleKey);
    return _isDark
        ? EleesaPalette.obsidian(accent: accent)
        : EleesaPalette.daylight(accent: accent);
  }

  ThemeData buildThemeData() {
    final p = _isDark ? EleesaPalette.obsidian() : EleesaPalette.daylight();
    return ThemeData(
      brightness: _isDark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: p.canvas,
      colorScheme: ColorScheme(
        brightness: _isDark ? Brightness.dark : Brightness.light,
        primary: p.accent,
        onPrimary: _isDark ? const Color(0xFF061018) : Colors.white,
        secondary: const Color(0xFFF59E0B),
        onSecondary: Colors.black,
        error: const Color(0xFFEF4444),
        onError: Colors.white,
        surface: p.surface,
        onSurface: p.textPrimary,
      ),
      cardTheme: CardThemeData(
        color: p.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: p.border, width: 1),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: p.surface,
        foregroundColor: p.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      dividerColor: p.border,
      useMaterial3: true,
    );
  }
}

final EleesaThemeController eleesaTheme = EleesaThemeController();

/// Custom ELEESA Crest Emblem (Item #16 & #12)
class EleesaCrestLogo extends StatelessWidget {
  final double size;
  final Color accent;

  const EleesaCrestLogo({
    super.key,
    this.size = 44,
    this.accent = const Color(0xFF00E5FF),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _EleesaCrestPainter(accent: accent),
      ),
    );
  }
}

class _EleesaCrestPainter extends CustomPainter {
  final Color accent;
  _EleesaCrestPainter({required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final bgPaint = Paint()..color = const Color(0xFF0B1320);
    canvas.drawCircle(center, radius, bgPaint);

    final outerRing = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.055;
    canvas.drawCircle(center, radius * 0.90, outerRing);

    final innerRing = Paint()
      ..color = const Color(0xFFF59E0B).withValues(alpha: 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.03;
    canvas.drawCircle(center, radius * 0.70, innerRing);

    // High-voltage lightning bolt core
    final bolt = Path()
      ..moveTo(center.dx + radius * 0.08, center.dy - radius * 0.46)
      ..lineTo(center.dx - radius * 0.24, center.dy + radius * 0.05)
      ..lineTo(center.dx - radius * 0.02, center.dy + radius * 0.05)
      ..lineTo(center.dx - radius * 0.12, center.dy + radius * 0.46)
      ..lineTo(center.dx + radius * 0.25, center.dy - radius * 0.06)
      ..lineTo(center.dx + radius * 0.02, center.dy - radius * 0.06)
      ..close();

    final boltPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [accent, const Color(0xFFF59E0B)],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 0.5));
    canvas.drawPath(bolt, boltPaint);
  }

  @override
  bool shouldRepaint(covariant _EleesaCrestPainter oldDelegate) =>
      oldDelegate.accent != accent;
}

/// Live Animated AC Waveform & Current Pulse Strip (Item #12)
class AnimatedCircuitStrip extends StatefulWidget {
  final Color accent;
  final double height;

  const AnimatedCircuitStrip({
    super.key,
    this.accent = const Color(0xFF00E5FF),
    this.height = 28,
  });

  @override
  State<AnimatedCircuitStrip> createState() => _AnimatedCircuitStripState();
}

class _AnimatedCircuitStripState extends State<AnimatedCircuitStrip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _WaveStripPainter(
              phase: _controller.value * 2 * math.pi,
              accent: widget.accent,
            ),
          );
        },
      ),
    );
  }
}

class _WaveStripPainter extends CustomPainter {
  final double phase;
  final Color accent;

  _WaveStripPainter({required this.phase, required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    final midY = size.height / 2;
    final gridPaint = Paint()
      ..color = accent.withValues(alpha: 0.16)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, midY), Offset(size.width, midY), gridPaint);

    final wavePaint = Paint()
      ..color = accent.withValues(alpha: 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    final path = Path();
    for (double x = 0; x <= size.width; x += 3) {
      final norm = x / size.width;
      final envelope = math.sin(norm * math.pi);
      final y = midY +
          math.sin((norm * 4 * math.pi) - phase) *
              (size.height * 0.36) *
              envelope;
      if (x == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, wavePaint);

    // Travelling electron pulse dot
    final pulseX = ((phase / (2 * math.pi)) % 1.0) * size.width;
    final pulseEnv = math.sin((pulseX / size.width) * math.pi);
    final pulseY = midY +
        math.sin(((pulseX / size.width) * 4 * math.pi) - phase) *
            (size.height * 0.36) *
            pulseEnv;

    canvas.drawCircle(
      Offset(pulseX, pulseY),
      3.5,
      Paint()..color = const Color(0xFFF59E0B),
    );
  }

  @override
  bool shouldRepaint(covariant _WaveStripPainter oldDelegate) =>
      oldDelegate.phase != phase || oldDelegate.accent != accent;
}