import 'package:flutter/material.dart';
import '../../services/academic_service.dart';
import '../../theme/theme_controller.dart';

class AcademicHubScreen extends StatefulWidget {
  final String email;
  final String fullName;
  final String roleKey;
  final String userLevel;
  final int initialTab;
  final bool embedded;

  const AcademicHubScreen({
    super.key,
    required this.email,
    required this.fullName,
    required this.roleKey,
    this.userLevel = '100',
    this.initialTab = 0,
    this.embedded = false,
  });

  @override
  State<AcademicHubScreen> createState() => _AcademicHubScreenState();
}

class _AcademicHubScreenState extends State<AcademicHubScreen> {
  final _service = AcademicService();
  late int _sectionTab; // 0 = Courses, 1 = Timetable, 2 = Calendar
  late String _selectedLevel;
  String _selectedSemester = 'ALL';
  String _timetableType = 'lecture'; // 'lecture' or 'exam'
  bool _loading = true;

  List<Map<String, dynamic>> _courses = [];
  List<Map<String, dynamic>> _timetables = [];
  List<Map<String, dynamic>> _calendar = [];

  bool get _isHod => widget.roleKey == 'hod_admin';
  bool get _isStaff => widget.roleKey == 'lecturer' || _isHod;

  @override
  void initState() {
    super.initState();
    _sectionTab = widget.initialTab;
    _selectedLevel = ['100', '200', '300', '400'].contains(widget.userLevel)
        ? widget.userLevel
        : '100';
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _service.fetchCourses(),
        _service.fetchTimetableAndCalendar(),
      ]);
      if (!mounted) return;
      final courses = results[0] as List<Map<String, dynamic>>;
      final ttData = results[1] as Map<String, dynamic>;
      setState(() {
        _courses = courses;
        _timetables = List<Map<String, dynamic>>.from(ttData['timetables'] ?? []);
        _calendar = List<Map<String, dynamic>>.from(ttData['calendar'] ?? []);
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
        final body = Column(
          children: [
            Container(
              color: p.surface,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      _topSegButton(p, 0, 'Courses & Syllabi'),
                      const SizedBox(width: 8),
                      _topSegButton(p, 1, 'Timetables'),
                      const SizedBox(width: 8),
                      _topSegButton(p, 2, 'Calendar'),
                    ],
                  ),
                  if (_sectionTab != 2) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: ['100', '200', '300', '400'].map((lvl) {
                        final active = _selectedLevel == lvl;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedLevel = lvl),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 7),
                                decoration: BoxDecoration(
                                  color: active
                                      ? p.accent.withValues(alpha: 0.18)
                                      : p.canvas,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: active ? p.accent : p.border,
                                  ),
                                ),
                                child: Text(
                                  'Lvl $lvl',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: active ? p.accent : p.textSecondary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
            Divider(height: 1, color: p.border),
            Expanded(
              child: _loading
                  ? Center(child: CircularProgressIndicator(color: p.accent))
                  : RefreshIndicator(
                      onRefresh: _loadAll,
                      child: _sectionTab == 0
                          ? _buildCoursesView(p)
                          : (_sectionTab == 1
                              ? _buildTimetableView(p)
                              : _buildCalendarView(p)),
                    ),
            ),
          ],
        );

        if (widget.embedded) {
          return Container(color: p.canvas, child: body);
        }

        return Scaffold(
          backgroundColor: p.canvas,
          appBar: AppBar(
            backgroundColor: p.surface,
            foregroundColor: p.textPrimary,
            title: const Text('Courses, Timetables & Calendar'),
          ),
          body: body,
        );
      },
    );
  }

  Widget _topSegButton(EleesaPalette p, int idx, String label) {
    final active = _sectionTab == idx;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _sectionTab = idx),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: active ? p.accent : p.canvas,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: active ? p.accent : p.border),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: active ? const Color(0xFF061018) : p.textSecondary,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  // --- TAB 0: COURSES & CURRICULUM (Item #4) ---
  Widget _buildCoursesView(EleesaPalette p) {
    final filtered = _courses.where((c) {
      if ((c['level'] ?? '').toString() != _selectedLevel) return false;
      if (_selectedSemester != 'ALL' &&
          (c['semester'] ?? '').toString() != _selectedSemester) {
        return false;
      }
      return true;
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: ['ALL', '1', '2'].map((sem) {
                final active = _selectedSemester == sem;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(sem == 'ALL' ? 'All Semesters' : 'Sem $sem'),
                    selected: active,
                    selectedColor: p.accent.withValues(alpha: 0.2),
                    backgroundColor: p.surface,
                    side: BorderSide(color: active ? p.accent : p.border),
                    labelStyle: TextStyle(
                      color: active ? p.accent : p.textSecondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 11.5,
                    ),
                    onSelected: (_) => setState(() => _selectedSemester = sem),
                  ),
                );
              }).toList(),
            ),
            if (_isStaff)
              FilledButton.icon(
                onPressed: () => _openCourseEditor(p),
                style: FilledButton.styleFrom(
                  backgroundColor: p.accent,
                  foregroundColor: const Color(0xFF061018),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Course', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (filtered.isEmpty)
          _emptyCard(p, 'No courses published for Level $_selectedLevel yet.')
        else
          ...filtered.map((c) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: p.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: p.border),
              ),
              child: ExpansionTile(
                iconColor: p.accent,
                collapsedIconColor: p.textSecondary,
                title: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: p.accent.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        (c['course_code'] ?? '').toString(),
                        style: TextStyle(
                          color: p.accent,
                          fontWeight: FontWeight.bold,
                          fontSize: 11.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        (c['course_title'] ?? '').toString(),
                        style: TextStyle(
                          color: p.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Sem ${c['semester']} \u2022 ${c['credit_hours']} Credits \u2022 ${c['lecturer_name']}',
                    style: TextStyle(color: p.textSecondary, fontSize: 12),
                  ),
                ),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                children: [
                  Divider(color: p.border),
                  _infoLine(p, 'Prerequisites', (c['prerequisites'] ?? 'None').toString()),
                  _infoLine(p, 'Assigned Lecturer', '${c['lecturer_name']} (${c['lecturer_email'] ?? ''})'),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'COURSE OUTLINE & SYLLABUS',
                      style: TextStyle(
                        color: p.accent,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    (c['syllabus'] ?? '').toString(),
                    style: TextStyle(color: p.textPrimary, fontSize: 13, height: 1.4),
                  ),
                  if (_isStaff) ...[
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => _openCourseEditor(p, existing: c),
                        icon: Icon(Icons.edit_outlined, size: 16, color: p.accent),
                        label: Text(
                          'Edit Syllabus / Lecturer',
                          style: TextStyle(color: p.accent, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
      ],
    );
  }

  // --- TAB 1: LECTURE & EXAM TIMETABLES (Item #5) ---
  Widget _buildTimetableView(EleesaPalette p) {
    final slots = _timetables.where((t) {
      return (t['level'] ?? '').toString() == _selectedLevel &&
          (t['entry_type'] ?? 'lecture').toString() == _timetableType;
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                _subPill(p, 'lecture', 'Lecture Timetable'),
                const SizedBox(width: 8),
                _subPill(p, 'exam', 'Exam Timetable'),
              ],
            ),
            if (_isStaff)
              FilledButton.icon(
                onPressed: () => _openTimetableEditor(p),
                style: FilledButton.styleFrom(
                  backgroundColor: p.accent,
                  foregroundColor: const Color(0xFF061018),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Slot', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (slots.isEmpty)
          _emptyCard(
            p,
            'No ${_timetableType == 'exam' ? 'exam' : 'lecture'} entries published for Level $_selectedLevel yet.',
          )
        else
          ...slots.map((s) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: p.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: p.border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: p.accent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        Text(
                          (s['day_or_date'] ?? '').toString(),
                          style: TextStyle(
                            color: p.accent,
                            fontWeight: FontWeight.bold,
                            fontSize: 11.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          (s['course_code'] ?? '').toString(),
                          style: TextStyle(
                            color: p.textPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (s['course_title'] ?? '').toString(),
                          style: TextStyle(
                            color: p.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${s['time_slot']} \u2022 ${s['venue']}',
                          style: TextStyle(color: p.accent, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_timetableType == 'exam' ? 'Invigilator' : 'Lecturer'}: ${s['lecturer_or_invigilator']}',
                          style: TextStyle(color: p.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _subPill(EleesaPalette p, String key, String label) {
    final active = _timetableType == key;
    return GestureDetector(
      onTap: () => setState(() => _timetableType = key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active ? p.accent.withValues(alpha: 0.2) : p.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: active ? p.accent : p.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? p.accent : p.textSecondary,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  // --- TAB 2: ACADEMIC CALENDAR (Item #5) ---
  Widget _buildCalendarView(EleesaPalette p) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'SEMESTER DATES & DEADLINES',
              style: TextStyle(
                color: p.accent,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
            if (_isHod)
              FilledButton.icon(
                onPressed: () => _openCalendarEditor(p),
                style: FilledButton.styleFrom(
                  backgroundColor: p.accent,
                  foregroundColor: const Color(0xFF061018),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Milestone', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (_calendar.isEmpty)
          _emptyCard(p, 'No academic calendar milestones posted yet.')
        else
          ..._calendar.map((ev) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: p.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: p.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: p.accent.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          (ev['category'] ?? 'ACADEMIC').toString().toUpperCase(),
                          style: TextStyle(
                            color: p.accent,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Text(
                        (ev['event_date'] ?? '').toString(),
                        style: TextStyle(
                          color: p.accent,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    (ev['title'] ?? '').toString(),
                    style: TextStyle(
                      color: p.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    (ev['description'] ?? '').toString(),
                    style: TextStyle(color: p.textSecondary, fontSize: 12.5, height: 1.4),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Future<void> _openCourseEditor(EleesaPalette p, {Map<String, dynamic>? existing}) async {
    final codeCtrl = TextEditingController(text: (existing?['course_code'] ?? '').toString());
    final titleCtrl = TextEditingController(text: (existing?['course_title'] ?? '').toString());
    final creditsCtrl = TextEditingController(text: (existing?['credit_hours'] ?? '3').toString());
    final prereqCtrl = TextEditingController(text: (existing?['prerequisites'] ?? 'None').toString());
    final syllabusCtrl = TextEditingController(text: (existing?['syllabus'] ?? '').toString());
    final lecNameCtrl = TextEditingController(text: (existing?['lecturer_name'] ?? widget.fullName).toString());
    String lvl = (existing?['level'] ?? _selectedLevel).toString();
    String sem = (existing?['semester'] ?? '1').toString();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: p.surface,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.fromLTRB(18, 18, 18, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('PUBLISH COURSE & SYLLABUS', style: TextStyle(color: p.accent, fontWeight: FontWeight.w800, fontSize: 11)),
                const SizedBox(height: 10),
                TextField(controller: codeCtrl, style: TextStyle(color: p.textPrimary), decoration: const InputDecoration(labelText: 'Course Code (e.g., EL 351)')),
                const SizedBox(height: 8),
                TextField(controller: titleCtrl, style: TextStyle(color: p.textPrimary), decoration: const InputDecoration(labelText: 'Course Title')),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: lvl,
                        dropdownColor: p.surface,
                        items: ['100', '200', '300', '400'].map((e) => DropdownMenuItem(value: e, child: Text('Level $e'))).toList(),
                        onChanged: (v) => setModal(() => lvl = v ?? '100'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: sem,
                        dropdownColor: p.surface,
                        items: ['1', '2'].map((e) => DropdownMenuItem(value: e, child: Text('Semester $e'))).toList(),
                        onChanged: (v) => setModal(() => sem = v ?? '1'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(controller: creditsCtrl, keyboardType: TextInputType.number, style: TextStyle(color: p.textPrimary), decoration: const InputDecoration(labelText: 'Credit Hours')),
                const SizedBox(height: 8),
                TextField(controller: prereqCtrl, style: TextStyle(color: p.textPrimary), decoration: const InputDecoration(labelText: 'Prerequisites')),
                const SizedBox(height: 8),
                TextField(controller: lecNameCtrl, style: TextStyle(color: p.textPrimary), decoration: const InputDecoration(labelText: 'Assigned Lecturer')),
                const SizedBox(height: 8),
                TextField(controller: syllabusCtrl, maxLines: 3, style: TextStyle(color: p.textPrimary), decoration: const InputDecoration(labelText: 'Course Outline / Syllabus')),
                const SizedBox(height: 14),
                FilledButton(
                  onPressed: () async {
                    try {
                      await _service.saveCourse({
                        'requester_email': widget.email,
                        'course_code': codeCtrl.text,
                        'course_title': titleCtrl.text,
                        'level': lvl,
                        'semester': sem,
                        'credit_hours': creditsCtrl.text,
                        'prerequisites': prereqCtrl.text,
                        'lecturer_name': lecNameCtrl.text,
                        'syllabus': syllabusCtrl.text,
                      });
                      if (ctx.mounted) Navigator.pop(ctx);
                      await _loadAll();
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                      }
                    }
                  },
                  style: FilledButton.styleFrom(backgroundColor: p.accent, foregroundColor: const Color(0xFF061018)),
                  child: const Text('Save to Curriculum', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openTimetableEditor(EleesaPalette p) async {
    final dayCtrl = TextEditingController(text: _timetableType == 'exam' ? 'Dec 12, 2026' : 'Thursday');
    final timeCtrl = TextEditingController(text: '10:00 AM \u2013 12:00 PM');
    final codeCtrl = TextEditingController();
    final titleCtrl = TextEditingController();
    final venueCtrl = TextEditingController(text: 'EEE Lecture Hall');

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
              Text('ADD ${_timetableType.toUpperCase()} SLOT (LEVEL $_selectedLevel)', style: TextStyle(color: p.accent, fontWeight: FontWeight.w800, fontSize: 11)),
              const SizedBox(height: 10),
              TextField(controller: dayCtrl, style: TextStyle(color: p.textPrimary), decoration: InputDecoration(labelText: _timetableType == 'exam' ? 'Exam Date' : 'Day of Week')),
              const SizedBox(height: 8),
              TextField(controller: timeCtrl, style: TextStyle(color: p.textPrimary), decoration: const InputDecoration(labelText: 'Time Slot')),
              const SizedBox(height: 8),
              TextField(controller: codeCtrl, style: TextStyle(color: p.textPrimary), decoration: const InputDecoration(labelText: 'Course Code')),
              const SizedBox(height: 8),
              TextField(controller: titleCtrl, style: TextStyle(color: p.textPrimary), decoration: const InputDecoration(labelText: 'Course Title')),
              const SizedBox(height: 8),
              TextField(controller: venueCtrl, style: TextStyle(color: p.textPrimary), decoration: const InputDecoration(labelText: 'Venue / Lab')),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: () async {
                  try {
                    await _service.addTimetableSlot({
                      'requester_email': widget.email,
                      'entry_type': _timetableType,
                      'level': _selectedLevel,
                      'day_or_date': dayCtrl.text,
                      'time_slot': timeCtrl.text,
                      'course_code': codeCtrl.text,
                      'course_title': titleCtrl.text,
                      'venue': venueCtrl.text,
                      'lecturer_or_invigilator': widget.fullName,
                    });
                    if (ctx.mounted) Navigator.pop(ctx);
                    await _loadAll();
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                    }
                  }
                },
                style: FilledButton.styleFrom(backgroundColor: p.accent, foregroundColor: const Color(0xFF061018)),
                child: const Text('Publish Timetable Slot', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openCalendarEditor(EleesaPalette p) async {
    final titleCtrl = TextEditingController();
    final dateCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String cat = 'Academic';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: p.surface,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.fromLTRB(18, 18, 18, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('PUBLISH CALENDAR MILESTONE', style: TextStyle(color: p.accent, fontWeight: FontWeight.w800, fontSize: 11)),
                const SizedBox(height: 10),
                TextField(controller: titleCtrl, style: TextStyle(color: p.textPrimary), decoration: const InputDecoration(labelText: 'Milestone Title')),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: cat,
                  dropdownColor: p.surface,
                  items: ['Academic', 'Deadline', 'Exams', 'Holiday'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (v) => setModal(() => cat = v ?? 'Academic'),
                ),
                const SizedBox(height: 8),
                TextField(controller: dateCtrl, style: TextStyle(color: p.textPrimary), decoration: const InputDecoration(labelText: 'Date / Window (e.g., Jan 15, 2027)')),
                const SizedBox(height: 8),
                TextField(controller: descCtrl, maxLines: 2, style: TextStyle(color: p.textPrimary), decoration: const InputDecoration(labelText: 'Details')),
                const SizedBox(height: 14),
                FilledButton(
                  onPressed: () async {
                    try {
                      await _service.addCalendarEvent({
                        'requester_email': widget.email,
                        'title': titleCtrl.text,
                        'category': cat,
                        'event_date': dateCtrl.text,
                        'target_level': 'ALL',
                        'description': descCtrl.text,
                      });
                      if (ctx.mounted) Navigator.pop(ctx);
                      await _loadAll();
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                      }
                    }
                  },
                  style: FilledButton.styleFrom(backgroundColor: p.accent, foregroundColor: const Color(0xFF061018)),
                  child: const Text('Publish Milestone', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoLine(EleesaPalette p, String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$k: ', style: TextStyle(color: p.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
          Expanded(child: Text(v, style: TextStyle(color: p.textPrimary, fontSize: 12))),
        ],
      ),
    );
  }

  Widget _emptyCard(EleesaPalette p, String msg) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.border),
      ),
      child: Text(msg, textAlign: TextAlign.center, style: TextStyle(color: p.textSecondary)),
    );
  }
}