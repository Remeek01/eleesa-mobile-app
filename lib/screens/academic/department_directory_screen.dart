import 'package:flutter/material.dart';
import '../../services/academic_service.dart';
import '../../services/profile_service.dart';
import '../../theme/theme_controller.dart';

class DepartmentDirectoryScreen extends StatefulWidget {
  final String email;
  final String roleKey;
  final int initialTab; // 0 = About Dept, 1 = Staff Directory

  const DepartmentDirectoryScreen({
    super.key,
    required this.email,
    required this.roleKey,
    this.initialTab = 0,
  });

  @override
  State<DepartmentDirectoryScreen> createState() => _DepartmentDirectoryScreenState();
}

class _DepartmentDirectoryScreenState extends State<DepartmentDirectoryScreen> {
  final _academicService = AcademicService();
  final _profileService = ProfileService();
  late int _tab;
  bool _loading = true;
  Map<String, dynamic> _dept = {};
  List<Map<String, dynamic>> _programs = [];
  List<Map<String, dynamic>> _staff = [];

  bool get _isHod => widget.roleKey == 'hod_admin';
  bool get _isStaff => widget.roleKey == 'lecturer' || _isHod;

  @override
  void initState() {
    super.initState();
    _tab = widget.initialTab;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _academicService.fetchOverview(email: widget.email, level: '100'),
        _profileService.fetchVisitorHub(),
      ]);
      if (!mounted) return;
      final ov = results[0];
      final pub = results[1];
      final aboutFallback = Map<String, dynamic>.from(pub['about'] ?? {});
      setState(() {
        _dept = Map<String, dynamic>.from(ov['department'] ?? aboutFallback);
        _programs = List<Map<String, dynamic>>.from(aboutFallback['programs'] ?? []);
        _staff = List<Map<String, dynamic>>.from(pub['staff'] ?? []);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: eleesaTheme,
      builder: (context, _) {
        final p = eleesaTheme.paletteForRole(widget.roleKey);
        return Scaffold(
          backgroundColor: p.canvas,
          appBar: AppBar(
            backgroundColor: p.surface,
            foregroundColor: p.textPrimary,
            title: Text(_tab == 0 ? 'About the Department' : 'Faculty & Staff Directory'),
            actions: [
              if (_tab == 0 && _isHod)
                IconButton(
                  tooltip: 'Edit Department Info',
                  icon: Icon(Icons.edit_note, color: p.accent),
                  onPressed: () => _openDeptEditor(p),
                ),
            ],
          ),
          body: Column(
            children: [
              Container(
                color: p.surface,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Row(
                  children: [
                    _segBtn(p, 0, 'About Department'),
                    const SizedBox(width: 8),
                    _segBtn(p, 1, 'Staff Directory (${_staff.length})'),
                  ],
                ),
              ),
              Divider(height: 1, color: p.border),
              Expanded(
                child: _loading
                    ? Center(child: CircularProgressIndicator(color: p.accent))
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        child: _tab == 0 ? _buildAbout(p) : _buildStaff(p),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _segBtn(EleesaPalette p, int idx, String label) {
    final active = _tab == idx;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tab = idx),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? p.accent.withValues(alpha: 0.18) : p.canvas,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: active ? p.accent : p.border),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: active ? p.accent : p.textSecondary,
              fontWeight: FontWeight.bold,
              fontSize: 12.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAbout(EleesaPalette p) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _card(
          p,
          'DEPARTMENT OVERVIEW',
          (_dept['department_name'] ?? 'Department of Electrical & Electronic Engineering').toString(),
          '${_dept['institution'] ?? ''}\n\n${_dept['history'] ?? ''}',
        ),
        const SizedBox(height: 12),
        _card(
          p,
          'HEAD OF DEPARTMENT MESSAGE',
          'From the Office of the HoD',
          (_dept['hod_message'] ?? '').toString(),
        ),
        const SizedBox(height: 12),
        _card(
          p,
          'VISION & MISSION',
          'Academic & Research Mandate',
          'VISION:\n${_dept['vision'] ?? ''}\n\nMISSION:\n${_dept['mission'] ?? ''}',
        ),
        const SizedBox(height: 12),
        _card(
          p,
          'PROGRAMS OFFERED',
          'Undergraduate & Postgraduate Tracks',
          _programs
              .map((pr) => '\u2022 ${pr['title']} (${(pr['tracks'] as List? ?? []).join(', ')})')
              .join('\n\n'),
        ),
        const SizedBox(height: 12),
        _card(
          p,
          'CONTACT, LOCATION & OFFICE HOURS',
          (_dept['location'] ?? '').toString(),
          'Hours: ${_dept['office_hours'] ?? ''}\nEmail: ${_dept['contact_email'] ?? 'eee.dept@umat.edu.gh'}\nPhone: ${_dept['contact_phone'] ?? '+233 (0) 312 320 324'}',
        ),
      ],
    );
  }

  Widget _buildStaff(EleesaPalette p) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_isStaff)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: OutlinedButton.icon(
              onPressed: () => _openMyStaffEditor(p),
              icon: Icon(Icons.edit_outlined, color: p.accent),
              label: Text(
                'Update My Courses Taught, Research & Consultation Hours',
                style: TextStyle(color: p.accent, fontWeight: FontWeight.bold, fontSize: 12.5),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: p.accent),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
              ),
            ),
          ),
        if (_staff.isEmpty)
          _card(p, 'FACULTY REGISTRY', 'No Staff Profiles Yet', 'Lecturers and HoD appear here once their faculty profile is completed.')
        else
          ..._staff.map((s) {
            final isHod = s['role'] == 'hod_admin';
            final color = isHod ? const Color(0xFF10B981) : const Color(0xFFF59E0B);
            final name = (s['full_name'] ?? 'Faculty').toString();
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: p.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: p.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: color.withValues(alpha: 0.2),
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : 'F',
                          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (s['academic_title'] ?? 'LECTURER').toString().toUpperCase(),
                              style: TextStyle(color: color, fontSize: 10.5, fontWeight: FontWeight.w800),
                            ),
                            Text(
                              name,
                              style: TextStyle(color: p.textPrimary, fontSize: 15.5, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              (s['email'] ?? '').toString(),
                              style: TextStyle(color: p.accent, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Divider(height: 18, color: p.border),
                  _staffRow(p, 'Office Location', (s['office_location'] ?? 'Engineering Block').toString()),
                  _staffRow(p, 'Courses Taught', (s['courses_taught'] ?? s['specialization'] ?? '').toString()),
                  _staffRow(p, 'Research Interests', (s['research_interests'] ?? s['specialization'] ?? '').toString()),
                  _staffRow(p, 'Consultation Hours', (s['office_hours'] ?? 'By Appointment').toString()),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _staffRow(EleesaPalette p, String label, String val) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: TextStyle(color: p.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Text(val, style: TextStyle(color: p.textPrimary, fontSize: 12.5)),
          ),
        ],
      ),
    );
  }

  Widget _card(EleesaPalette p, String kicker, String title, String body) {
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
          Text(kicker, style: TextStyle(color: p.accent, fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 1.1)),
          const SizedBox(height: 6),
          Text(title, style: TextStyle(color: p.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(body, style: TextStyle(color: p.textSecondary, fontSize: 13, height: 1.45)),
        ],
      ),
    );
  }

  Future<void> _openDeptEditor(EleesaPalette p) async {
    final locCtrl = TextEditingController(text: (_dept['location'] ?? '').toString());
    final hrsCtrl = TextEditingController(text: (_dept['office_hours'] ?? '').toString());
    final hodCtrl = TextEditingController(text: (_dept['hod_message'] ?? '').toString());
    final visCtrl = TextEditingController(text: (_dept['vision'] ?? '').toString());
    final misCtrl = TextEditingController(text: (_dept['mission'] ?? '').toString());

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: p.surface,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(18, 18, 18, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('HOD: EDIT DEPARTMENT PROFILE', style: TextStyle(color: p.accent, fontWeight: FontWeight.w800, fontSize: 11)),
              const SizedBox(height: 10),
              TextField(controller: locCtrl, style: TextStyle(color: p.textPrimary), decoration: const InputDecoration(labelText: 'Campus Location')),
              const SizedBox(height: 8),
              TextField(controller: hrsCtrl, style: TextStyle(color: p.textPrimary), decoration: const InputDecoration(labelText: 'Office Hours')),
              const SizedBox(height: 8),
              TextField(controller: hodCtrl, maxLines: 3, style: TextStyle(color: p.textPrimary), decoration: const InputDecoration(labelText: 'HoD Welcome Message')),
              const SizedBox(height: 8),
              TextField(controller: visCtrl, maxLines: 2, style: TextStyle(color: p.textPrimary), decoration: const InputDecoration(labelText: 'Vision Statement')),
              const SizedBox(height: 8),
              TextField(controller: misCtrl, maxLines: 2, style: TextStyle(color: p.textPrimary), decoration: const InputDecoration(labelText: 'Mission Statement')),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: () async {
                  await _academicService.updateDepartmentInfo({
                    'requester_email': widget.email,
                    'location': locCtrl.text,
                    'office_hours': hrsCtrl.text,
                    'hod_message': hodCtrl.text,
                    'vision': visCtrl.text,
                    'mission': misCtrl.text,
                  });
                  if (ctx.mounted) Navigator.pop(ctx);
                  await _loadData();
                },
                style: FilledButton.styleFrom(backgroundColor: p.accent, foregroundColor: const Color(0xFF061018)),
                child: const Text('Publish Changes', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openMyStaffEditor(EleesaPalette p) async {
    final me = _staff.firstWhere(
      (s) => (s['email'] ?? '').toString().toLowerCase() == widget.email.toLowerCase(),
      orElse: () => {},
    );
    final locCtrl = TextEditingController(text: (me['office_location'] ?? 'Engineering Block').toString());
    final hrsCtrl = TextEditingController(text: (me['office_hours'] ?? 'Wed 2:00 PM - 4:00 PM').toString());
    final coursesCtrl = TextEditingController(text: (me['courses_taught'] ?? '').toString());
    final resCtrl = TextEditingController(text: (me['research_interests'] ?? '').toString());

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: p.surface,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(18, 18, 18, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('UPDATE FACULTY DIRECTORY CARD', style: TextStyle(color: p.accent, fontWeight: FontWeight.w800, fontSize: 11)),
              const SizedBox(height: 10),
              TextField(controller: locCtrl, style: TextStyle(color: p.textPrimary), decoration: const InputDecoration(labelText: 'Office Location')),
              const SizedBox(height: 8),
              TextField(controller: hrsCtrl, style: TextStyle(color: p.textPrimary), decoration: const InputDecoration(labelText: 'Consultation Hours')),
              const SizedBox(height: 8),
              TextField(controller: coursesCtrl, style: TextStyle(color: p.textPrimary), decoration: const InputDecoration(labelText: 'Courses Taught (e.g., EL 351, EL 454)')),
              const SizedBox(height: 8),
              TextField(controller: resCtrl, maxLines: 2, style: TextStyle(color: p.textPrimary), decoration: const InputDecoration(labelText: 'Research Interests')),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: () async {
                  await _academicService.updateStaffProfile({
                    'requester_email': widget.email,
                    'office_location': locCtrl.text,
                    'office_hours': hrsCtrl.text,
                    'courses_taught': coursesCtrl.text,
                    'research_interests': resCtrl.text,
                  });
                  if (ctx.mounted) Navigator.pop(ctx);
                  await _loadData();
                },
                style: FilledButton.styleFrom(backgroundColor: p.accent, foregroundColor: const Color(0xFF061018)),
                child: const Text('Save Faculty Card', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}