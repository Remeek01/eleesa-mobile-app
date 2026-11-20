import 'dart:math' as math;
import 'package:flutter/material.dart';

class EleesaColors {
  static const Color deepNavy = Color(0xFF0B132B);
  static const Color slateBlue = Color(0xFF1C2541);
  static const Color electricCyan = Color(0xFF00E5FF);
  static const Color highVoltageAmber = Color(0xFFFFB703);
}

/// Animated high-voltage lightning emblem with pulsing energy rings.
class ElectricPulseBadge extends StatefulWidget {
  final bool isActive;
  final double size;

  const ElectricPulseBadge({
    super.key,
    this.isActive = false,
    this.size = 76,
  });

  @override
  State<ElectricPulseBadge> createState() => _ElectricPulseBadgeState();
}

class _ElectricPulseBadgeState extends State<ElectricPulseBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.isActive
        ? EleesaColors.highVoltageAmber
        : EleesaColors.electricCyan;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _ElectricBadgePainter(
              progress: _controller.value,
              accentColor: accent,
            ),
          );
        },
      ),
    );
  }
}

class _ElectricBadgePainter extends CustomPainter {
  final double progress;
  final Color accentColor;

  _ElectricBadgePainter({
    required this.progress,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    // Outer expanding pulse wave
    final pulseRadius = maxRadius * (0.62 + 0.36 * progress);
    final pulseOpacity = (1.0 - progress).clamp(0.0, 1.0) * 0.45;
    final pulsePaint = Paint()
      ..color = accentColor.withValues(alpha: pulseOpacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, pulseRadius, pulsePaint);

    // Core dark circuit disc
    final coreRadius = maxRadius * 0.64;
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [EleesaColors.deepNavy, EleesaColors.slateBlue],
      ).createShader(Rect.fromCircle(center: center, radius: coreRadius));
    canvas.drawCircle(center, coreRadius, bgPaint);

    // Core metallic border
    final borderPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    canvas.drawCircle(center, coreRadius, borderPaint);

    // Custom vector lightning bolt (immune to icon font tree-shaking)
    final w = coreRadius * 0.95;
    final h = coreRadius * 1.15;
    final bolt = Path()
      ..moveTo(center.dx + w * 0.08, center.dy - h * 0.52)
      ..lineTo(center.dx - w * 0.34, center.dy + h * 0.06)
      ..lineTo(center.dx - w * 0.02, center.dy + h * 0.06)
      ..lineTo(center.dx - w * 0.14, center.dy + h * 0.52)
      ..lineTo(center.dx + w * 0.34, center.dy - h * 0.08)
      ..lineTo(center.dx + w * 0.02, center.dy - h * 0.08)
      ..close();

    final boltPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(bolt, boltPaint);
  }

  @override
  bool shouldRepaint(covariant _ElectricBadgePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.accentColor != accentColor;
  }
}

/// Decorative PCB circuit trace header for ELEESA auth screens.
class CircuitGridHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isStepTwo;

  const CircuitGridHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.isStepTwo = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [EleesaColors.deepNavy, EleesaColors.slateBlue],
        ),
        border: Border.all(
          color: EleesaColors.electricCyan.withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: EleesaColors.deepNavy.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(19),
        child: CustomPaint(
          painter: _CircuitTracePainter(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              children: [
                ElectricPulseBadge(isActive: isStepTwo, size: 78),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: EleesaColors.electricCyan.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: EleesaColors.electricCyan.withValues(alpha: 0.45),
                    ),
                  ),
                  child: const Text(
                    'ELEESA SECURITY GRID',
                    style: TextStyle(
                      color: EleesaColors.electricCyan,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFCBD5E1),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CircuitTracePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final tracePaint = Paint()
      ..color = EleesaColors.electricCyan.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    final nodePaint = Paint()
      ..color = EleesaColors.highVoltageAmber.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;

    // Left PCB trace
    final leftPath = Path()
      ..moveTo(0, size.height * 0.28)
      ..lineTo(size.width * 0.16, size.height * 0.28)
      ..lineTo(size.width * 0.24, size.height * 0.45)
      ..lineTo(size.width * 0.34, size.height * 0.45);
    canvas.drawPath(leftPath, tracePaint);
    canvas.drawCircle(Offset(size.width * 0.34, size.height * 0.45), 3.2, nodePaint);

    // Right PCB trace
    final rightPath = Path()
      ..moveTo(size.width, size.height * 0.72)
      ..lineTo(size.width * 0.82, size.height * 0.72)
      ..lineTo(size.width * 0.74, size.height * 0.52)
      ..lineTo(size.width * 0.65, size.height * 0.52);
    canvas.drawPath(rightPath, tracePaint);
    canvas.drawCircle(Offset(size.width * 0.65, size.height * 0.52), 3.2, nodePaint);

    // Subtle sine-wave accent along bottom
    final wavePath = Path();
    for (double x = 0; x <= size.width; x += 4) {
      final y = size.height - 10 + math.sin(x * 0.045) * 4;
      if (x == 0) {
        wavePath.moveTo(x, y);
      } else {
        wavePath.lineTo(x, y);
      }
    }
    canvas.drawPath(wavePath, tracePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Subtle animated banner shown when Render takes > 3s to wake from sleep.
class ColdStartStatusBanner extends StatelessWidget {
  final String? statusMessage;

  const ColdStartStatusBanner({
    super.key,
    required this.statusMessage,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      child: statusMessage == null
          ? const SizedBox.shrink()
          : Container(
              margin: const EdgeInsets.only(top: 14),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: EleesaColors.deepNavy,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: EleesaColors.highVoltageAmber.withValues(alpha: 0.65),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: EleesaColors.highVoltageAmber,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          statusMessage!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      minHeight: 3,
                      backgroundColor: Colors.white.withValues(alpha: 0.12),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        EleesaColors.electricCyan,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
/// 1. STUDENT HUB HEADER: Live AC Oscilloscope Telemetry Deck (Cyan/Navy)
class StudentOscilloscopeHeader extends StatefulWidget {
  final String studentName;
  final String level;
  final String indexNumber;
  final VoidCallback onProfileTap;

  const StudentOscilloscopeHeader({
    super.key,
    required this.studentName,
    required this.level,
    required this.indexNumber,
    required this.onProfileTap,
  });

  @override
  State<StudentOscilloscopeHeader> createState() =>
      _StudentOscilloscopeHeaderState();
}

class _StudentOscilloscopeHeaderState extends State<StudentOscilloscopeHeader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _waveCtrl;

  @override
  void initState() {
    super.initState();
    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _waveCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF070D19), Color(0xFF0F2942)],
        ),
        border: Border.all(
          color: EleesaColors.electricCyan.withValues(alpha: 0.5),
          width: 1.4,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(21),
        child: AnimatedBuilder(
          animation: _waveCtrl,
          builder: (context, child) {
            return CustomPaint(
              painter: _OscilloscopePainter(phase: _waveCtrl.value * 2 * math.pi),
              child: child,
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: EleesaColors.electricCyan.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: EleesaColors.electricCyan),
                      ),
                      child: Text(
                        'STUDENT TELEMETRY • LVL ${widget.level.isEmpty ? "---" : widget.level}',
                        style: const TextStyle(
                          color: EleesaColors.electricCyan,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: widget.onProfileTap,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.badge_outlined, size: 15, color: EleesaColors.electricCyan),
                            SizedBox(width: 6),
                            Text(
                              'My Profile',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  widget.studentName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.indexNumber.isEmpty
                      ? 'Complete your student onboarding card'
                      : 'Index ID: ${widget.indexNumber}  •  DB Node: level_${widget.level}_students',
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OscilloscopePainter extends CustomPainter {
  final double phase;
  _OscilloscopePainter({required this.phase});

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = EleesaColors.electricCyan.withValues(alpha: 0.08)
      ..strokeWidth = 1;

    for (double x = 0; x < size.width; x += 28) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    final wavePaint = Paint()
      ..color = EleesaColors.electricCyan.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final path = Path();
    final baseline = size.height - 18;
    for (double x = 0; x <= size.width; x += 3) {
      final y = baseline + math.sin((x * 0.04) + phase) * 8;
      if (x == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, wavePaint);
  }

  @override
  bool shouldRepaint(covariant _OscilloscopePainter oldDelegate) =>
      oldDelegate.phase != phase;
}

/// 2. LECTURER HUB HEADER: 3-Phase Substation Busbar Console (Amber/Slate)
class LecturerBusbarHeader extends StatelessWidget {
  final String lecturerName;
  final String titleAndSpec;
  final int totalStudents;
  final VoidCallback onProfileTap;

  const LecturerBusbarHeader({
    super.key,
    required this.lecturerName,
    required this.titleAndSpec,
    required this.totalStudents,
    required this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF111827), Color(0xFF292524)],
        ),
        border: Border.all(
          color: EleesaColors.highVoltageAmber.withValues(alpha: 0.6),
          width: 1.4,
        ),
      ),
      child: CustomPaint(
        painter: _BusbarPainter(),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: EleesaColors.highVoltageAmber.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: EleesaColors.highVoltageAmber),
                    ),
                    child: const Text(
                      '3-PHASE FACULTY BUSBAR',
                      style: TextStyle(
                        color: EleesaColors.highVoltageAmber,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: onProfileTap,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.manage_accounts_outlined, size: 15, color: EleesaColors.highVoltageAmber),
                          SizedBox(width: 6),
                          Text(
                            'Faculty Profile',
                            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                lecturerName,
                style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                titleAndSpec,
                style: const TextStyle(color: Color(0xFFD6D3D1), fontSize: 12.5),
              ),
              const SizedBox(height: 12),
              Text(
                'Active Enrolled Registry: $totalStudents Students across 4 Levels',
                style: const TextStyle(
                  color: EleesaColors.highVoltageAmber,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BusbarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final phaseColors = [
      const Color(0xFFEF4444).withValues(alpha: 0.25), // L1 Red
      const Color(0xFFF59E0B).withValues(alpha: 0.25), // L2 Yellow
      const Color(0xFF3B82F6).withValues(alpha: 0.25), // L3 Blue
    ];
    for (int i = 0; i < 3; i++) {
      final y = size.height - 26.0 + (i * 7.0);
      final p = Paint()
        ..color = phaseColors[i]
        ..strokeWidth = 2.0;
      canvas.drawLine(Offset(16, y), Offset(size.width - 16, y), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 3. HoD HUB HEADER: Department Main Grid Control Room (Emerald/Gold/Obsidian)
class HodMainGridHeader extends StatelessWidget {
  final String hodName;
  final Map<String, int> levelCounts;
  final VoidCallback onProfileTap;

  const HodMainGridHeader({
    super.key,
    required this.hodName,
    required this.levelCounts,
    required this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    const emerald = Color(0xFF10B981);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF050B14), Color(0xFF063729)],
        ),
        border: Border.all(
          color: emerald.withValues(alpha: 0.65),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: emerald.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: emerald),
                  ),
                  child: const Text(
                    'MAIN GRID CONTROL • HoD COMMAND',
                    style: TextStyle(
                      color: emerald,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: onProfileTap,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.admin_panel_settings_outlined, size: 15, color: emerald),
                        SizedBox(width: 6),
                        Text(
                          'HoD Profile',
                          style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              hodName,
              style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Departmental Telemetry & Encrypted 4-Level Student Registry',
              style: TextStyle(color: Color(0xFFA7F3D0), fontSize: 12.5),
            ),
            const SizedBox(height: 16),
            Row(
              children: ['100', '200', '300', '400'].map((lvl) {
                final count = levelCounts[lvl] ?? 0;
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(88, 69, 43, 172),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color.fromARGB(88, 49, 17, 146)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'LVL $lvl',
                          style: const TextStyle(
                            color: Color(0xFF6EE7B7),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$count',
                          style: const TextStyle(
                            color: Color.fromARGB(255, 215, 15, 15),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}