import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class Wave3HubScreen extends StatefulWidget {
  final int initialTabIndex;
  final String userRole;
  final String userName;
  final String userEmail;
  final String userLevel;
  final Color accentColor;

  const Wave3HubScreen({
    super.key,
    this.initialTabIndex = 0,
    this.userRole = 'student',
    this.userName = 'Maxwell Amoah',
    this.userEmail = '',
    this.userLevel = '300',
    this.accentColor = const Color(0xFF00E5FF),
  });

  @override
  State<Wave3HubScreen> createState() => _Wave3HubScreenState();
}

class _Wave3HubScreenState extends State<Wave3HubScreen>
    with SingleTickerProviderStateMixin {
  static const String _baseUrl = 'https://eleesa-backend.onrender.com';
  static const Color _bgObsidian = Color(0xFF0E1116);
  static const Color _cardSurface = Color(0xFF161A22);
  static const Color _borderStroke = Color(0xFF262C3A);

  late TabController _tabController;
  bool _loading = true;
  String? _error;

  String _selectedLevel = 'ALL';
  String _selectedLab = 'ALL';

  List> _resources = [];
  List> _equipment = [];
  List> _bookings = [];
  List> _projects = [];
  List> _attachments = [];

  bool get _isStaffOrAdmin {
    final r = widget.userRole.toLowerCase();
    return r == 'lecturer' || r == 'hod' || r == 'admin' || r == 'executive';
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 3),
    );
    _loadAllWave3();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllWave3() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final resQuery = _isStaffOrAdmin
          ? '$_baseUrl/api/wave3/resources?includePending=true'
          : '$_baseUrl/api/wave3/resources';
      final responses = await Future.wait([
        http.get(Uri.parse(resQuery)),
        http.get(Uri.parse('$_baseUrl/api/wave3/labs')),
        http.get(Uri.parse('$_baseUrl/api/wave3/projects')),
        http.get(Uri.parse('$_baseUrl/api/wave3/attachments')),
      ]);

      final resJson = jsonDecode(responses[0].body) as Map<String, dynamic>;
      final labJson = jsonDecode(responses[1].body) as Map<String, dynamic>;
      final prjJson = jsonDecode(responses[2].body) as Map<String, dynamic>;
      final attJson = jsonDecode(responses[3].body) as Map<String, dynamic>;

      if (!mounted) return;
      setState(() {
        _resources = List>.from(resJson['resources'] ?? []);
        _equipment = List>.from(labJson['equipment'] ?? []);
        _bookings = List>.from(labJson['bookings'] ?? []);
        _projects = List>.from(prjJson['projects'] ?? []);
        _attachments = List>.from(attJson['attachments'] ?? []);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Grid sync delayed: $e';
        _loading = false;
      });
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isError ? Colors.redAccent : const Color(0xFF1F2937),
        content: Text(msg, style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.accentColor;
    return Scaffold(
      backgroundColor: _bgObsidian,
      appBar: AppBar(
        backgroundColor: _bgObsidian,
        elevation: 0,
        title: const Text(
          'Engineering Lab & Research Grid',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: accent),
            tooltip: 'Sync Wave 3 Grid',
            onPressed: _loadAllWave3,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: accent,
          labelColor: accent,
          unselectedLabelColor: Colors.white60,
          isScrollable: false,
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          tabs: const [
            Tab(icon: Icon(Icons.folder_copy_outlined, size: 18), text: 'Library'),
            Tab(icon: Icon(Icons.biotech_outlined, size: 18), text: '5 Labs'),
            Tab(icon: Icon(Icons.memory_outlined, size: 18), text: 'Projects'),
            Tab(icon: Icon(Icons.work_outline, size: 18), text: 'Intern'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: accent,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text('Submit Entry', style: TextStyle(fontWeight: FontWeight.w700)),
        onPressed: () {
          switch (_tabController.index) {
            case 0:
              _openResourceDialog();
              break;
            case 1:
              _openLabBookingDialog();
              break;
            case 2:
              _openProjectDialog();
              break;
            case 3:
              _openAttachmentDialog();
              break;
          }
        },
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: accent))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, style: const TextStyle(color: Colors.redAccent)),
                        const SizedBox(height: 12),
                        ElevatedButton(onPressed: _loadAllWave3, child: const Text('Retry')),
                      ],
                    ),
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildResourcesTab(accent),
                    _buildLabsTab(accent),
                    _buildProjectsTab(accent),
                    _buildAttachmentsTab(accent),
                  ],
                ),
    );
  }

  Widget _buildResourcesTab(Color accent) {
    final filtered = _selectedLevel == 'ALL'
        ? _resources
        : _resources.where((r) => '${r['level']}' == _selectedLevel).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ['ALL', '100', '200', '300', '400'].map((lvl) {
              final selected = _selectedLevel == lvl;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(lvl == 'ALL' ? 'All Levels' : 'Level $lvl'),
                  selected: selected,
                  selectedColor: accent.withValues(alpha: 0.22),
                  backgroundColor: _cardSurface,
                  labelStyle: TextStyle(
                    color: selected ? accent : Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                  side: BorderSide(color: selected ? accent : _borderStroke),
                  onSelected: (_) => setState(() => _selectedLevel = lvl),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),
        if (filtered.isEmpty)
          _emptyCard('No study resources matched Level $_selectedLevel.')
        else
          ...filtered.map((item) {
            final isPending = '${item['status']}'.toLowerCase() == 'pending';
            return _darkCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _badge('${item['course_code']}', accent),
                      const SizedBox(width: 8),
                      _badge('${item['category']}', Colors.amberAccent),
                      const Spacer(),
                      if (isPending)
                        _badge('PENDING REVIEW', Colors.orangeAccent)
                      else
                        _badge('LVL ${item['level']}', Colors.tealAccent),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${item['title']}',
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  if ('${item['description']}'.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text('${item['description']}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Uploaded by ${item['uploaded_by']} (${item['uploader_role']})',
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ),
                      if (isPending && _isStaffOrAdmin)
                        TextButton.icon(
                          onPressed: () => _approveResource(item['resource_id']),
                          icon: const Icon(Icons.check_circle, size: 16, color: Colors.greenAccent),
                          label: const Text('Approve', style: TextStyle(color: Colors.greenAccent)),
                        ),
                    ],
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Future<void> _approveResource(dynamic id) async {
    try {
      await http.patch(
        Uri.parse('$_baseUrl/api/wave3/resources/$id/status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'status': 'approved'}),
      );
      _showSnack('Resource approved and published.');
      _loadAllWave3();
    } catch (e) {
      _showSnack('Failed to approve resource: $e', isError: true);
    }
  }

  Widget _buildLabsTab(Color accent) {
    final labs = <String>{'ALL', ..._equipment.map((e) => '${e['lab_name']}')}.toList();
    final visibleEquipment = _selectedLab == 'ALL'
        ? _equipment
        : _equipment.where((e) => '${e['lab_name']}' == _selectedLab).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: labs.map((lab) {
              final selected = _selectedLab == lab;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(lab == 'ALL' ? 'All 5 Labs' : lab.replaceAll(' Lab', '')),
                  selected: selected,
                  selectedColor: accent.withValues(alpha: 0.22),
                  backgroundColor: _cardSurface,
                  labelStyle: TextStyle(
                    color: selected ? accent : Colors.white70,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  side: BorderSide(color: selected ? accent : _borderStroke),
                  onSelected: (_) => setState(() => _selectedLab = lab),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'LABORATORY EQUIPMENT INVENTORY (${visibleEquipment.length})',
          style: TextStyle(color: accent, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.1),
        ),
        const SizedBox(height: 8),
        ...visibleEquipment.map((eq) {
          final status = '${eq['status']}';
          final statusColor = status == 'Available'
              ? Colors.greenAccent
              : (status == 'In Use' ? Colors.amberAccent : Colors.orangeAccent);
          return _darkCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text('${eq['lab_name']}', style: TextStyle(color: accent, fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                    _badge('$status • Qty ${eq['quantity']}', statusColor),
                  ],
                ),
                const SizedBox(height: 6),
                Text('${eq['equipment_name']} (${eq['model_code']})', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('${eq['specs']}', style: const TextStyle(color: Colors.white70, fontSize: 12.5)),
              ],
            ),
          );
        }),
        const SizedBox(height: 16),
        Text(
          'RECENT BENCH & EQUIPMENT BOOKINGS (${_bookings.length})',
          style: TextStyle(color: accent, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.1),
        ),
        const SizedBox(height: 8),
        if (_bookings.isEmpty)
          _emptyCard('No lab bookings queued yet. Tap Submit Entry to reserve a bench.')
        else
          ..._bookings.map((bk) {
            final st = '${bk['status']}';
            final stColor = st == 'Approved'
                ? Colors.greenAccent
                : (st == 'Rejected' ? Colors.redAccent : Colors.amberAccent);
            return _darkCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text('${bk['lab_name']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700))),
                      _badge(st.toUpperCase(), stColor),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Equipment: ${bk['equipment_name']} • ${bk['booking_date']} (${bk['time_slot']})',
                    style: const TextStyle(color: Colors.white70, fontSize: 12.5),
                  ),
                  const SizedBox(height: 4),
                  Text('By ${bk['student_name']} • ${bk['purpose']}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  if (st == 'Pending' && _isStaffOrAdmin) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => _updateBooking(bk['booking_id'], 'Rejected'),
                          child: const Text('Decline', style: TextStyle(color: Colors.redAccent)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent, foregroundColor: Colors.black),
                          onPressed: () => _updateBooking(bk['booking_id'], 'Approved'),
                          child: const Text('Approve Slot'),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          }),
      ],
    );
  }

  Future<void> _updateBooking(dynamic id, String status) async {
    try {
      await http.patch(
        Uri.parse('$_baseUrl/api/wave3/labs/bookings/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'status': status, 'reviewed_by': widget.userName}),
      );
      _showSnack('Lab booking marked $status.');
      _loadAllWave3();
    } catch (e) {
      _showSnack('Booking update failed: $e', isError: true);
    }
  }

  Widget _buildProjectsTab(Color accent) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
      children: _projects.isEmpty
          ? [_emptyCard('No research or capstone projects published yet.')]
          : _projects.map((pr) {
              return _darkCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _badge('${pr['category']}', accent),
                        const SizedBox(width: 8),
                        _badge('${pr['academic_year']}', Colors.white70),
                        const Spacer(),
                        _badge('${pr['status']}', Colors.greenAccent),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text('${pr['title']}', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Text('${pr['abstract']}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 10),
                    Text(
                      'Team: ${pr['student_names']}  •  Supervisor: ${pr['supervisor_name']}',
                      style: TextStyle(color: accent, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              );
            }).toList(),
    );
  }

  Widget _buildAttachmentsTab(Color accent) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
      children: _attachments.isEmpty
          ? [_emptyCard('No industrial attachment placements listed yet.')]
          : _attachments.map((at) {
              final hasStudent = '${at['student_name'] ?? ''}'.trim().isNotEmpty;
              return _darkCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text('${at['company_name']}', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                        ),
                        _badge('${at['status']}', hasStudent ? Colors.greenAccent : accent),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${at['role_title']} • ${at['sector']} • ${at['location']} (${at['duration']})',
                      style: TextStyle(color: accent, fontSize: 12.5, fontWeight: FontWeight.w600),
                    ),
                    if ('${at['logbook_summary']}'.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text('${at['logbook_summary']}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      hasStudent
                          ? 'Assigned Student: ${at['student_name']} (Level ${at['level']})'
                          : 'Supervisor Contact: ${at['supervisor_contact']}',
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              );
            }).toList(),
    );
  }

  void _openResourceDialog() {
    final titleCtrl = TextEditingController();
    final codeCtrl = TextEditingController(text: 'EL 351');
    final urlCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String level = widget.userLevel.isNotEmpty ? widget.userLevel : '300';
    String category = 'Lecture Notes';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardSurface,
        title: const Text('Upload Study Resource', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _inputField(titleCtrl, 'Document Title'),
              _inputField(codeCtrl, 'Course Code (e.g. EL 353)'),
              DropdownButtonFormField<String>(
                value: level,
                dropdownColor: _cardSurface,
                style: const TextStyle(color: Colors.white),
                items: ['100', '200', '300', '400']
                    .map((l) => DropdownMenuItem(value: l, child: Text('Level $l')))
                    .toList(),
                onChanged: (v) => level = v ?? '300',
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: category,
                dropdownColor: _cardSurface,
                style: const TextStyle(color: Colors.white),
                items: ['Lecture Notes', 'Past Questions', 'Lab Manual', 'Tutorial Sheet']
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => category = v ?? 'Lecture Notes',
              ),
              _inputField(urlCtrl, 'Drive / PDF Link'),
              _inputField(descCtrl, 'Summary / Topics Covered'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (titleCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              await http.post(
                Uri.parse('$_baseUrl/api/wave3/resources'),
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode({
                  'title': titleCtrl.text.trim(),
                  'course_code': codeCtrl.text.trim(),
                  'level': level,
                  'category': category,
                  'file_url': urlCtrl.text.trim(),
                  'description': descCtrl.text.trim(),
                  'uploaded_by': widget.userName,
                  'uploader_role': widget.userRole,
                }),
              );
              _showSnack(_isStaffOrAdmin ? 'Resource published to library.' : 'Resource submitted for lecturer approval.');
              _loadAllWave3();
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _openLabBookingDialog() {
    String selectedLab = 'Power Systems & High Voltage Lab';
    final eqCtrl = TextEditingController();
    final dateCtrl = TextEditingController(text: '2026-11-25');
    final slotCtrl = TextEditingController(text: '02:00 PM – 04:00 PM');
    final purposeCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardSurface,
        title: const Text('Reserve Laboratory Bench', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedLab,
                isExpanded: true,
                dropdownColor: _cardSurface,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                items: const [
                  'Power Systems & High Voltage Lab',
                  'Electrical Machines & Drives Lab',
                  'Analog & Digital Electronics Lab',
                  'Control Systems & Instrumentation Lab',
                  'Telecommunications & Microwave Lab',
                ].map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
                onChanged: (v) => selectedLab = v ?? selectedLab,
              ),
              _inputField(eqCtrl, 'Equipment / Bench (optional)'),
              _inputField(dateCtrl, 'Date (YYYY-MM-DD)'),
              _inputField(slotCtrl, 'Time Window'),
              _inputField(purposeCtrl, 'Experiment / Project Purpose'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (purposeCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              await http.post(
                Uri.parse('$_baseUrl/api/wave3/labs/book'),
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode({
                  'lab_name': selectedLab,
                  'equipment_name': eqCtrl.text.trim(),
                  'student_name': widget.userName,
                  'student_email': widget.userEmail,
                  'booking_date': dateCtrl.text.trim(),
                  'time_slot': slotCtrl.text.trim(),
                  'purpose': purposeCtrl.text.trim(),
                }),
              );
              _showSnack('Lab booking request sent to coordinator.');
              _loadAllWave3();
            },
            child: const Text('Request Slot'),
          ),
        ],
      ),
    );
  }

  void _openProjectDialog() {
    final titleCtrl = TextEditingController();
    final teamCtrl = TextEditingController(text: widget.userName);
    final supCtrl = TextEditingController(text: 'Prof. J. K. Gyimah');
    final absCtrl = TextEditingController();
    String category = 'Power & Smart Grid';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardSurface,
        title: const Text('Propose Final-Year Project', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _inputField(titleCtrl, 'Project Title'),
              DropdownButtonFormField<String>(
                value: category,
                dropdownColor: _cardSurface,
                style: const TextStyle(color: Colors.white),
                items: [
                  'Power & Smart Grid',
                  'Renewable Energy',
                  'Industrial Automation',
                  'Embedded & IoT',
                  'Electrical Machines',
                ].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => category = v ?? category,
              ),
              _inputField(teamCtrl, 'Student Team Members'),
              _inputField(supCtrl, 'Proposed Supervisor'),
              _inputField(absCtrl, 'Problem Statement & Abstract'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (titleCtrl.text.trim().isEmpty || absCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              await http.post(
                Uri.parse('$_baseUrl/api/wave3/projects'),
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode({
                  'title': titleCtrl.text.trim(),
                  'category': category,
                  'student_names': teamCtrl.text.trim(),
                  'supervisor_name': supCtrl.text.trim(),
                  'abstract': absCtrl.text.trim(),
                }),
              );
              _showSnack('Project topic submitted.');
              _loadAllWave3();
            },
            child: const Text('Submit Topic'),
          ),
        ],
      ),
    );
  }

  void _openAttachmentDialog() {
    final companyCtrl = TextEditingController();
    final locationCtrl = TextEditingController(text: 'Takoradi, Western Region');
    final roleCtrl = TextEditingController(text: 'Electrical Engineering Intern');
    final summaryCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardSurface,
        title: const Text('Log Industrial Attachment', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _inputField(companyCtrl, 'Host Company / Substation'),
              _inputField(locationCtrl, 'City / Region'),
              _inputField(roleCtrl, 'Unit / Internship Role'),
              _inputField(summaryCtrl, 'Weekly Scope / Logbook Notes'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (companyCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              await http.post(
                Uri.parse('$_baseUrl/api/wave3/attachments'),
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode({
                  'company_name': companyCtrl.text.trim(),
                  'location': locationCtrl.text.trim(),
                  'student_name': widget.userName,
                  'student_email': widget.userEmail,
                  'level': widget.userLevel,
                  'role_title': roleCtrl.text.trim(),
                  'logbook_summary': summaryCtrl.text.trim(),
                }),
              );
              _showSnack('Industrial attachment placement recorded.');
              _loadAllWave3();
            },
            child: const Text('Save Placement'),
          ),
        ],
      ),
    );
  }

  Widget _inputField(TextEditingController ctrl, String hint) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: TextField(
        controller: ctrl,
        style: const TextStyle(color: Colors.white, fontSize: 13.5),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white38),
          filled: true,
          fillColor: _bgObsidian,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _borderStroke),
          ),
        ),
      ),
    );
  }

  Widget _darkCard({required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _borderStroke),
      ),
      child: child,
    );
  }

  Widget _emptyCard(String message) {
    return _darkCard(
      child: Text(message, style: const TextStyle(color: Colors.white60, fontSize: 13)),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10.5, fontWeight: FontWeight.w700),
      ),
    );
  }
}