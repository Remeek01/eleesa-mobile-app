import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

typedef W5Map = Map<String, dynamic>;

class Wave5ToolsHub extends StatefulWidget {
  final int initialTabIndex;
  final String userRole;
  final String userName;
  final String userLevel;
  final Color accentColor;

  const Wave5ToolsHub({
    super.key,
    this.initialTabIndex = 0,
    this.userRole = 'student',
    this.userName = 'Maxwell Amoah',
    this.userLevel = '300',
    this.accentColor = const Color(0xFF00E5FF),
  });

  @override
  State<Wave5ToolsHub> createState() => _Wave5ToolsHubState();
}

class _Wave5CourseRow {
  final TextEditingController codeCtrl;
  final TextEditingController creditsCtrl;
  String grade;

  _Wave5CourseRow({
    required String code,
    required String credits,
    this.grade = 'A',
  })  : codeCtrl = TextEditingController(text: code),
        creditsCtrl = TextEditingController(text: credits);

  void dispose() {
    codeCtrl.dispose();
    creditsCtrl.dispose();
  }
}

class _Wave5ToolsHubState extends State<Wave5ToolsHub>
    with SingleTickerProviderStateMixin {
  static const String _baseUrl = 'https://eleesa-backend.onrender.com';
  static const Color _bgObsidian = Color(0xFF0E1116);
  static const Color _cardSurface = Color(0xFF161A22);
  static const Color _borderStroke = Color(0xFF262C3A);

  static const Map<String, double> _gradePoints = {
    'A+': 4.0,
    'A': 4.0,
    'B+': 3.5,
    'B': 3.0,
    'C+': 2.5,
    'C': 2.0,
    'D': 1.0,
    'F': 0.0,
  };

  late TabController _tabController;
  final List<_Wave5CourseRow> _courses = [
    _Wave5CourseRow(code: 'EL 351', credits: '3', grade: 'A'),
    _Wave5CourseRow(code: 'EL 353', credits: '3', grade: 'B+'),
    _Wave5CourseRow(code: 'EL 356', credits: '2', grade: 'A'),
  ];

  final _voltageCtrl = TextEditingController(text: '415');
  final _currentCtrl = TextEditingController(text: '18.5');
  final _pfCtrl = TextEditingController(text: '0.85');

  List<W5Map> _tickets = [];
  bool _loadingTickets = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 2),
    );
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _loadTickets();
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (final c in _courses) {
      c.dispose();
    }
    _voltageCtrl.dispose();
    _currentCtrl.dispose();
    _pfCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadTickets() async {
    setState(() => _loadingTickets = true);
    try {
      final res = await http.get(Uri.parse('$_baseUrl/api/wave5/feedback'));
      final data = jsonDecode(res.body) as W5Map;
      if (!mounted) return;
      setState(() {
        _tickets = List<W5Map>.from(data['tickets'] ?? []);
        _loadingTickets = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingTickets = false);
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF1F2937),
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
        title: const Text(
          'EEE Tools, Forms & Help Desk',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(icon: Icon(Icons.refresh, color: accent), onPressed: _loadTickets),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: accent,
          labelColor: accent,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          tabs: const [
            Tab(icon: Icon(Icons.calculate_outlined, size: 18), text: 'CGPA & Power'),
            Tab(icon: Icon(Icons.description_outlined, size: 18), text: 'Forms'),
            Tab(icon: Icon(Icons.support_agent_outlined, size: 18), text: 'Help Desk'),
          ],
        ),
      ),
      floatingActionButton: _tabController.index == 2
          ? FloatingActionButton.extended(
              backgroundColor: accent,
              foregroundColor: Colors.black,
              icon: const Icon(Icons.add_comment_outlined),
              label: const Text('New Ticket', style: TextStyle(fontWeight: FontWeight.w700)),
              onPressed: _openTicketDialog,
            )
          : null,
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildToolsAndCgpaTab(accent),
          _buildFormsTab(accent),
          _buildHelpDeskTab(accent),
        ],
      ),
    );
  }

  Widget _buildToolsAndCgpaTab(Color accent) {
    double totalCredits = 0;
    double weightedPoints = 0;
    for (final row in _courses) {
      final cr = double.tryParse(row.creditsCtrl.text.trim()) ?? 0;
      final gp = _gradePoints[row.grade] ?? 0;
      if (cr > 0) {
        totalCredits += cr;
        weightedPoints += cr * gp;
      }
    }
    final gpa = totalCredits > 0 ? (weightedPoints / totalCredits) : 0.0;

    final vLine = double.tryParse(_voltageCtrl.text.trim()) ?? 0;
    final iLine = double.tryParse(_currentCtrl.text.trim()) ?? 0;
    final pfClamped = (double.tryParse(_pfCtrl.text.trim()) ?? 0.85).clamp(0.0, 1.0);
    final apparentS = math.sqrt(3) * vLine * iLine;
    final activeP = apparentS * pfClamped;
    final reactiveQ = apparentS * math.sqrt((1.0 - pfClamped * pfClamped).clamp(0.0, 1.0));

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
      children: [
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'SEMESTER GPA CALCULATOR',
                    style: TextStyle(color: accent, fontSize: 11.5, fontWeight: FontWeight.w800, letterSpacing: 1.1),
                  ),
                  const Spacer(),
                  _badge('GPA ${gpa.toStringAsFixed(2)} / 4.00', Colors.greenAccent),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Total Credit Hours: ${totalCredits.toStringAsFixed(0)} • Quality Points: ${weightedPoints.toStringAsFixed(1)}',
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
              const SizedBox(height: 10),
              ..._courses.map((row) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: row.codeCtrl,
                          onChanged: (_) => setState(() {}),
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: _deco('Course'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: row.creditsCtrl,
                          keyboardType: TextInputType.number,
                          onChanged: (_) => setState(() {}),
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: _deco('Cr'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<String>(
                          initialValue: row.grade,
                          dropdownColor: _cardSurface,
                          style: TextStyle(color: accent, fontWeight: FontWeight.w700),
                          items: _gradePoints.keys
                              .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                              .toList(),
                          onChanged: (v) => setState(() => row.grade = v ?? 'A'),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 4),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(side: BorderSide(color: accent), foregroundColor: accent),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Course Row'),
                onPressed: () {
                  setState(() {
                    _courses.add(_Wave5CourseRow(code: 'EL 355', credits: '3', grade: 'B+'));
                  });
                },
              ),
            ],
          ),
        ),
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'THREE-PHASE AC POWER CALCULATOR',
                style: TextStyle(color: accent, fontSize: 11.5, fontWeight: FontWeight.w800, letterSpacing: 1.1),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _voltageCtrl,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: _deco('V_Line (V)'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _currentCtrl,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: _deco('I_Line (A)'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _pfCtrl,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: _deco('PF (0-1)'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _metricTile('Active (P)', '${(activeP / 1000).toStringAsFixed(2)} kW', Colors.greenAccent),
                  _metricTile('Reactive (Q)', '${(reactiveQ / 1000).toStringAsFixed(2)} kVAR', Colors.amberAccent),
                  _metricTile('Apparent (S)', '${(apparentS / 1000).toStringAsFixed(2)} kVA', accent),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _metricTile(String label, String val, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: _bgObsidian,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _borderStroke),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
          const SizedBox(height: 2),
          Text(val, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 13.5)),
        ],
      ),
    );
  }

  Widget _buildFormsTab(Color accent) {
    final forms = [
      ['Industrial Attachment Introductory Letter Request', 'UMaT EEE / Attachment Office • Required for ECG, GRIDCo, VRA & Mine placements', 'https://umat.edu.gh/eee/forms/attachment-letter'],
      ['Laboratory Safety & Equipment Sign-Off Form', 'Power, Machines, Electronics, Control & Telecom Labs • Mandatory PPE checklist', 'https://umat.edu.gh/eee/forms/lab-clearance'],
      ['Final-Year Capstone Project Proposal Template', 'Level 400 • Problem statement, block diagram, methodology & supervisor sign-off', 'https://umat.edu.gh/eee/forms/project-proposal'],
      ['Course Registration & Add/Drop Slip', 'Academic Registry / Departmental Advisor • Semester 1 & 2 verification', 'https://umat.edu.gh/eee/forms/course-registration'],
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 36),
      children: forms.map((f) {
        return _card(
          child: Row(
            children: [
              Icon(Icons.picture_as_pdf_outlined, color: accent, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(f[0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(f[1], style: const TextStyle(color: Colors.white60, fontSize: 12)),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.copy, color: accent, size: 20),
                tooltip: 'Copy Form Link',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: f[2]));
                  _snack('Copied link for ${f[0]}.');
                },
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHelpDeskTab(Color accent) {
    if (_loadingTickets) {
      return Center(child: CircularProgressIndicator(color: accent));
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
      children: _tickets.map((t) {
        final st = '${t['status']}';
        final stColor = st == 'Resolved' ? Colors.greenAccent : (st == 'In Review' ? Colors.amberAccent : accent);
        return _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _badge('${t['category']}', accent),
                  const Spacer(),
                  _badge(st.toUpperCase(), stColor),
                ],
              ),
              const SizedBox(height: 8),
              Text('${t['subject']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14.5)),
              const SizedBox(height: 4),
              Text('${t['message']}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 8),
              Text(
                'By ${t['submitted_by']} (${t['sender_role']} • Lvl ${t['sender_level']})',
                style: const TextStyle(color: Colors.white54, fontSize: 11.5),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  void _openTicketDialog() {
    final subjCtrl = TextEditingController();
    final msgCtrl = TextEditingController();
    String category = 'Help Desk';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardSurface,
        title: const Text('Submit Help Desk Ticket', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: category,
                dropdownColor: _cardSurface,
                style: const TextStyle(color: Colors.white),
                items: ['Help Desk', 'Lab & Facility', 'Suggestion', 'Academic Query']
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => category = v ?? category,
              ),
              const SizedBox(height: 10),
              TextField(controller: subjCtrl, style: const TextStyle(color: Colors.white), decoration: _deco('Subject')),
              const SizedBox(height: 10),
              TextField(controller: msgCtrl, maxLines: 3, style: const TextStyle(color: Colors.white), decoration: _deco('Describe your request or feedback')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (subjCtrl.text.trim().isEmpty || msgCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              await http.post(
                Uri.parse('$_baseUrl/api/wave5/feedback'),
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode({
                  'category': category,
                  'subject': subjCtrl.text.trim(),
                  'message': msgCtrl.text.trim(),
                  'submitted_by': widget.userName,
                  'sender_role': widget.userRole,
                  'sender_level': widget.userLevel,
                }),
              );
              _snack('Ticket logged to ELEESA Help Desk!');
              _loadTickets();
            },
            child: const Text('Submit Ticket'),
          ),
        ],
      ),
    );
  }

  InputDecoration _deco(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white54, fontSize: 12.5),
      filled: true,
      fillColor: _bgObsidian,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _borderStroke),
      ),
    );
  }

  Widget _card({required Widget child}) {
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

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 10.5, fontWeight: FontWeight.w700)),
    );
  }
}