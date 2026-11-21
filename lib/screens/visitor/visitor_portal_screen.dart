import 'package:flutter/material.dart';
import '../../services/profile_service.dart';
import '../../theme/theme_controller.dart';

class VisitorPortalScreen extends StatefulWidget {
  final int initialTab;
  final bool isAuthenticatedViewer;

  const VisitorPortalScreen({
    super.key,
    this.initialTab = 0,
    this.isAuthenticatedViewer = false,
  });

  @override
  State<VisitorPortalScreen> createState() => _VisitorPortalScreenState();
}

class _VisitorPortalScreenState extends State<VisitorPortalScreen> {
  final _service = ProfileService();
  late int _selectedTab;
  bool _loading = true;
  String? _error;
  Map<String, dynamic> _about = {};
  List> _staff = [];

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _service.fetchVisitorHub();
      if (!mounted) return;
      setState(() {
        _about = Map<String, dynamic>.from(data['about'] ?? {});
        _staff = List>.from(data['staff'] ?? []);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: eleesaTheme,
      builder: (context, _) {
        final p = eleesaTheme.paletteForRole('student');
        return Scaffold(
          backgroundColor: p.canvas,
          appBar: AppBar(
            backgroundColor: p.surface,
            foregroundColor: p.textPrimary,
            titleSpacing: 12,
            title: Row(
              children: [
                EleesaCrestLogo(size: 32, accent: p.accent),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.isAuthenticatedViewer
                            ? 'Department & Faculty'
                            : 'ELEESA Visitor Portal',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: p.textPrimary,
                        ),
                      ),
                      Text(
                        'PUBLIC ACCESS \u2022 NO LOGIN REQUIRED',
                        style: TextStyle(
                          fontSize: 9.5,
                          letterSpacing: 1.1,
                          fontWeight: FontWeight.w700,
                          color: p.accent,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'Switch Theme',
                onPressed: eleesaTheme.toggleTheme,
                icon: Icon(
                  p.isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                  color: p.accent,
                ),
              ),
              if (!widget.isAuthenticatedViewer)
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Sign In',
                    style: TextStyle(
                      color: p.accent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          body: Column(
            children: [
              Container(
                color: p.surface,
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
                child: Column(
                  children: [
                    AnimatedCircuitStrip(accent: p.accent, height: 20),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _tabChip(p, 0, 'About Dept'),
                        const SizedBox(width: 8),
                        _tabChip(p, 1, 'Programs'),
                        const SizedBox(width: 8),
                        _tabChip(p, 2, 'Staff (${_staff.length})'),
                      ],
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: p.border),
              Expanded(
                child: _loading
                    ? Center(child: CircularProgressIndicator(color: p.accent))
                    : _error != null
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _error!,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: p.textSecondary),
                                  ),
                                  const SizedBox(height: 12),
                                  ElevatedButton(
                                    onPressed: _loadData,
                                    child: const Text('Retry Connection'),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadData,
                            child: _selectedTab == 0
                                ? _buildAboutTab(p)
                                : (_selectedTab == 1
                                    ? _buildProgramsTab(p)
                                    : _buildStaffTab(p)),
                          ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _tabChip(EleesaPalette p, int index, String label) {
    final active = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? p.accent.withValues(alpha: 0.16) : p.canvas,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: active ? p.accent : p.border,
              width: active ? 1.4 : 1,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: active ? p.accent : p.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAboutTab(EleesaPalette p) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionCard(
          p,
          kicker: 'DEPARTMENT PROFILE',
          title: (_about['department_name'] ??
                  'Department of Electrical & Electronic Engineering')
              .toString(),
          body:
              '${_about['institution'] ?? 'University of Mines and Technology (UMaT)'}\n${_about['history'] ?? ''}',
        ),
        const SizedBox(height: 12),
        _sectionCard(
          p,
          kicker: 'HEAD OF DEPARTMENT MESSAGE',
          title: 'Welcome to the ELEESA Digital Grid',
          body: (_about['hod_message'] ?? '').toString(),
        ),
        const SizedBox(height: 12),
        _sectionCard(
          p,
          kicker: 'VISION & MISSION',
          title: 'Engineering Excellence & Innovation',
          body:
              'VISION:\n${_about['vision'] ?? ''}\n\nMISSION:\n${_about['mission'] ?? ''}',
        ),
        const SizedBox(height: 12),
        _sectionCard(
          p,
          kicker: 'CAMPUS LOCATION & HOURS',
          title: (_about['location'] ?? 'Faculty of Engineering Block').toString(),
          body: 'Office Hours: ${_about['office_hours'] ?? 'Mon - Fri, 8:00 AM - 5:00 PM'}',
        ),
      ],
    );
  }

  Widget _buildProgramsTab(EleesaPalette p) {
    final programs = List>.from(_about['programs'] ?? []);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final prog in programs) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: p.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: p.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    (prog['code'] ?? 'PROGRAM').toString(),
                    style: TextStyle(
                      color: p.accent,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  (prog['title'] ?? '').toString(),
                  style: TextStyle(
                    color: p.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'SPECIALIZATION TRACKS',
                  style: TextStyle(
                    color: p.textSecondary,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                for (final track in List<String>.from(prog['tracks'] ?? []))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Row(
                      children: [
                        Icon(Icons.bolt, size: 15, color: p.accent),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            track,
                            style: TextStyle(
                              color: p.textPrimary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStaffTab(EleesaPalette p) {
    if (_staff.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: p.border),
            ),
            child: Column(
              children: [
                Icon(Icons.school_outlined, size: 42, color: p.accent),
                const SizedBox(height: 10),
                Text(
                  'Faculty Directory Syncing',
                  style: TextStyle(
                    color: p.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Lecturers and the Head of Department appear here automatically as soon as they complete their ELEESA faculty profile.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: p.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _staff.length,
      itemBuilder: (context, i) {
        final s = _staff[i];
        final isHod = s['role'] == 'hod_admin';
        final badgeColor =
            isHod ? const Color(0xFF10B981) : const Color(0xFFF59E0B);
        final name = (s['full_name'] ?? 'Faculty Member').toString();
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: p.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: badgeColor.withValues(alpha: 0.2),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'F',
                  style: TextStyle(
                    color: badgeColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (s['academic_title'] ?? 'LECTURER')
                          .toString()
                          .toUpperCase(),
                      style: TextStyle(
                        color: badgeColor,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      name,
                      style: TextStyle(
                        color: p.textPrimary,
                        fontSize: 15.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Research & Focus: ${s['specialization'] ?? 'Electrical & Electronic Engineering'}',
                      style: TextStyle(color: p.textSecondary, fontSize: 12.5),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Office Hours: ${s['office_hours'] ?? 'By Appointment'}',
                      style: TextStyle(color: p.textSecondary, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      (s['email'] ?? '').toString(),
                      style: TextStyle(
                        color: p.accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _sectionCard(
    EleesaPalette p, {
    required String kicker,
    required String title,
    required String body,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            kicker,
            style: TextStyle(
              color: p.accent,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(
              color: p.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: TextStyle(
              color: p.textSecondary,
              fontSize: 13.5,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}