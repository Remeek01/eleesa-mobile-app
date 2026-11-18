import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// Routes Android Emulator to host PC (10.0.2.2) and iOS/Web to localhost
String get apiBase => 'https://eleesa-backend.onrender.com/api/v1';

const Map<String, String?> roleTokens = {
  'visitor': null,
  'student': 'student-token',
  'executive': 'executive-token',
  'lecturer': 'lecturer-token',
  'hod_admin': 'hod-token',
};

const Map<String, String> roleLabels = {
  'visitor': 'Visitor',
  'student': 'Student',
  'executive': 'ELEESA Exec',
  'lecturer': 'Lecturer',
  'hod_admin': 'HOD / Admin',
};

void main() {
  runApp(const EleesaApp());
}

class EleesaApp extends StatelessWidget {
  const EleesaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ELEESA Mobile Portal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E3A8A),
          secondary: const Color(0xFFF59E0B),
        ),
        useMaterial3: true,
      ),
      home: const MainShell(),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  String _role = 'visitor';

  void _updateRole(String newRole) {
    setState(() => _role = newRole);
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      OverviewTab(role: _role, onRoleChanged: _updateRole),
      AcademicsTab(role: _role, onRoleChanged: _updateRole),
      NoticesTab(role: _role, onRoleChanged: _updateRole),
      const ToolsTab(),
    ];

    return Scaffold(
      body: tabs[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.bolt), label: 'ELEESA'),
          NavigationDestination(icon: Icon(Icons.menu_book), label: 'Academics'),
          NavigationDestination(icon: Icon(Icons.campaign), label: 'Notices'),
          NavigationDestination(icon: Icon(Icons.calculate), label: 'EEE Tools'),
        ],
      ),
    );
  }
}

PreferredSizeWidget buildEleesaAppBar({
  required String title,
  String? role,
  ValueChanged<String>? onRoleChanged,
  VoidCallback? onRefresh,
}) {
  return AppBar(
    backgroundColor: const Color(0xFF1E3A8A),
    foregroundColor: Colors.white,
    title: Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFF59E0B),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Text(
            'ELEESA',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(child: Text(title, overflow: TextOverflow.ellipsis)),
      ],
    ),
    actions: [
      if (role != null && onRoleChanged != null)
        DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: role,
            dropdownColor: const Color(0xFF1E3A8A),
            iconEnabledColor: Colors.white,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            items: roleLabels.entries
                .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                .toList(),
            onChanged: (val) {
              if (val != null) onRoleChanged(val);
            },
          ),
        ),
      if (onRefresh != null)
        IconButton(icon: const Icon(Icons.refresh), onPressed: onRefresh),
    ],
  );
}

// ==========================================
// TAB 1: ELEESA OVERVIEW, STAFF & LABS
// ==========================================
class OverviewTab extends StatefulWidget {
  final String role;
  final ValueChanged<String> onRoleChanged;

  const OverviewTab({
    super.key,
    required this.role,
    required this.onRoleChanged,
  });

  @override
  State<OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<OverviewTab> {
  String _status = 'Connecting to ELEESA API...';
  Map<String, dynamic>? _about;
  List<dynamic> _staff = [];
  List<dynamic> _labs = [];

  @override
  void initState() {
    super.initState();
    _loadOverview();
  }

  @override
  void didUpdateWidget(covariant OverviewTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.role != widget.role) _loadOverview();
  }

  Future<void> _loadOverview() async {
    setState(() => _status = 'Syncing with PostgreSQL (${roleLabels[widget.role]})...');
    try {
      final results = await Future.wait([
        http.get(Uri.parse('$apiBase/public/about')),
        http.get(Uri.parse('$apiBase/public/staff')),
        http.get(Uri.parse('$apiBase/public/labs')),
      ]);

      if (!mounted) return;
      setState(() {
        if (results[0].statusCode == 200) _about = jsonDecode(results[0].body);
        if (results[1].statusCode == 200) _staff = jsonDecode(results[1].body);
        if (results[2].statusCode == 200) _labs = jsonDecode(results[2].body);
        _status = 'Connected • Role: ${roleLabels[widget.role]}';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _status = 'Offline: Start Node.js server on port 3000');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildEleesaAppBar(
        title: 'Portal',
        role: widget.role,
        onRoleChanged: widget.onRoleChanged,
        onRefresh: _loadOverview,
      ),
      body: RefreshIndicator(
        onRefresh: _loadOverview,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              color: Colors.indigo.shade50,
              child: ListTile(
                leading: const Icon(Icons.cloud_done, color: Color(0xFF1E3A8A)),
                title: Text(_status, style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
            if (_about != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _about!['association_name'] ?? 'ELEESA',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${_about!['location_description'] ?? ''} • ${_about!['office_hours'] ?? ''}',
                        style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                      ),
                      const Divider(height: 20),
                      Text('Vision: ${_about!['vision'] ?? ''}'),
                      const SizedBox(height: 6),
                      Text('Mission: ${_about!['mission'] ?? ''}'),
                      const SizedBox(height: 8),
                      Text(
                        'President: "${_about!['president_message'] ?? ''}"',
                        style: const TextStyle(fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
              ),
            const Padding(
              padding: EdgeInsets.only(top: 14, bottom: 6),
              child: Text(
                'Academic Staff Directory',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            ..._staff.map((s) => Card(
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text('${s['full_name']} (${s['rank']})'),
                    subtitle: Text(
                      '${s['office_location']} • ${s['consultation_hours']}\nResearch: ${s['research_interests']}',
                    ),
                    isThreeLine: true,
                  ),
                )),
            const Padding(
              padding: EdgeInsets.only(top: 14, bottom: 6),
              child: Text(
                'Department Laboratories & Safety',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            ..._labs.map((l) => Card(
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.science)),
                    title: Text('${l['lab_name']} (${l['location']})'),
                    subtitle: Text('Safety: ${l['safety_rules']}'),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// TAB 2: COURSES, TIMETABLE & RESOURCES
// ==========================================
class AcademicsTab extends StatefulWidget {
  final String role;
  final ValueChanged<String> onRoleChanged;

  const AcademicsTab({
    super.key,
    required this.role,
    required this.onRoleChanged,
  });

  @override
  State<AcademicsTab> createState() => _AcademicsTabState();
}

class _AcademicsTabState extends State<AcademicsTab> {
  List<dynamic> _courses = [];
  List<dynamic> _timetables = [];
  List<dynamic> _resources = [];
  String _resourceOwner = '';

  @override
  void initState() {
    super.initState();
    _loadAcademics();
  }

  @override
  void didUpdateWidget(covariant AcademicsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.role != widget.role) _loadAcademics();
  }

  Future<void> _loadAcademics() async {
    try {
      final cRes = await http.get(Uri.parse('$apiBase/public/courses'));
      final tRes = await http.get(Uri.parse('$apiBase/public/timetables'));

      List<dynamic> unlocked = [];
      String owner = '';
      final token = roleTokens[widget.role];

      if (token != null) {
        final rRes = await http.get(
          Uri.parse('$apiBase/resources'),
          headers: {'Authorization': 'Bearer $token'},
        );
        if (rRes.statusCode == 200) {
          final parsed = jsonDecode(rRes.body);
          unlocked = parsed['resources'] ?? [];
          owner = parsed['user']?['full_name'] ?? '';
        }
      }

      if (!mounted) return;
      setState(() {
        if (cRes.statusCode == 200) _courses = jsonDecode(cRes.body);
        if (tRes.statusCode == 200) _timetables = jsonDecode(tRes.body);
        _resources = unlocked;
        _resourceOwner = owner;
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildEleesaAppBar(
        title: 'Academics',
        role: widget.role,
        onRoleChanged: widget.onRoleChanged,
        onRefresh: _loadAcademics,
      ),
      body: RefreshIndicator(
        onRefresh: _loadAcademics,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Lecture & Exam Timetable',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            ..._timetables.map((t) => Card(
                  child: ListTile(
                    leading: Icon(
                      t['schedule_type'] == 'exam' ? Icons.edit_document : Icons.schedule,
                      color: const Color(0xFF1E3A8A),
                    ),
                    title: Text(
                      '${t['course_code']} • ${t['day_or_date']} (${t['start_time']} - ${t['end_time']})',
                    ),
                    subtitle: Text(
                      'Level ${t['level']} • ${(t['schedule_type'] ?? '').toString().toUpperCase()} • ${t['venue']}',
                    ),
                  ),
                )),
            const SizedBox(height: 14),
            const Text(
              'Department Curriculum',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            ..._courses.map((c) => Card(
                  child: ListTile(
                    leading: CircleAvatar(child: Text('${c['level']}')),
                    title: Text('${c['course_code']}: ${c['title']}'),
                    subtitle: Text(
                      '${c['credit_hours']} Credits • Prereq: ${c['prerequisites']} • ${c['lecturer']}',
                    ),
                  ),
                )),
            const SizedBox(height: 14),
            Text(
              widget.role == 'visitor'
                  ? 'Study Resources (Switch to Student/Exec/Staff to unlock)'
                  : 'Unlocked Resources ($_resourceOwner)',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            if (widget.role == 'visitor')
              const Card(
                child: ListTile(
                  leading: Icon(Icons.lock_outline),
                  title: Text('Restricted Academic Materials'),
                  subtitle: Text('Use the role dropdown in the top bar to test Student or Executive access.'),
                ),
              )
            else
              ..._resources.map((r) => Card(
                    color: Colors.green.shade50,
                    child: ListTile(
                      leading: const Icon(Icons.folder_special, color: Colors.green),
                      title: Text('${r['course_code']}: ${r['title']}'),
                      subtitle: Text('Category: ${r['category']}'),
                    ),
                  )),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// TAB 3: NOTICES & LIVE EVENT PUBLISHING
// ==========================================
class NoticesTab extends StatefulWidget {
  final String role;
  final ValueChanged<String> onRoleChanged;

  const NoticesTab({
    super.key,
    required this.role,
    required this.onRoleChanged,
  });

  @override
  State<NoticesTab> createState() => _NoticesTabState();
}

class _NoticesTabState extends State<NoticesTab> {
  List<dynamic> _notices = [];

  @override
  void initState() {
    super.initState();
    _loadNotices();
  }

  Future<void> _loadNotices() async {
    try {
      final res = await http.get(Uri.parse('$apiBase/public/notices'));
      if (res.statusCode == 200 && mounted) {
        setState(() => _notices = jsonDecode(res.body));
      }
    } catch (_) {}
  }

  Future<void> _openCreateNoticeSheet() async {
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();
    String category = 'eleesa_event';

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: StatefulBuilder(
          builder: (ctx, setModalState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Publish Notice / ELEESA Event',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: category,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'eleesa_event', child: Text('ELEESA Event')),
                  DropdownMenuItem(value: 'notice', child: Text('General Notice')),
                  DropdownMenuItem(value: 'seminar', child: Text('Seminar')),
                  DropdownMenuItem(value: 'workshop', child: Text('Workshop')),
                  DropdownMenuItem(value: 'career_alumni', child: Text('Career & Alumni')),
                ],
                onChanged: (v) => setModalState(() => category = v ?? 'eleesa_event'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: bodyCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Details',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                icon: const Icon(Icons.send),
                label: const Text('Publish to PostgreSQL'),
                onPressed: () async {
                  if (titleCtrl.text.trim().isEmpty || bodyCtrl.text.trim().isEmpty) return;
                  final token = roleTokens[widget.role];
                  final res = await http.post(
                    Uri.parse('$apiBase/notices'),
                    headers: {
                      'Content-Type': 'application/json',
                      if (token != null) 'Authorization': 'Bearer $token',
                    },
                    body: jsonEncode({
                      'title': titleCtrl.text.trim(),
                      'body': bodyCtrl.text.trim(),
                      'category': category,
                    }),
                  );
                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);
                  if (res.statusCode == 201) {
                    _loadNotices();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Published to ELEESA database!')),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canPost = ['executive', 'lecturer', 'hod_admin'].contains(widget.role);

    return Scaffold(
      appBar: buildEleesaAppBar(
        title: 'Notices & Events',
        role: widget.role,
        onRoleChanged: widget.onRoleChanged,
        onRefresh: _loadNotices,
      ),
      floatingActionButton: canPost
          ? FloatingActionButton.extended(
              onPressed: _openCreateNoticeSheet,
              icon: const Icon(Icons.add),
              label: const Text('Post Notice'),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: _loadNotices,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: _notices
              .map((n) => Card(
                    child: ListTile(
                      leading: const Icon(Icons.campaign, color: Color(0xFF1E3A8A)),
                      title: Text(n['title'] ?? ''),
                      subtitle: Text(
                        '${n['body']}\n[${n['category']}] • ${n['event_date'] ?? ''}',
                      ),
                      isThreeLine: true,
                    ),
                  ))
              .toList(),
        ),
      ),
    );
  }
}

// ==========================================
// TAB 4: OFFLINE ENGINEERING & CGPA TOOLS
// ==========================================
class ToolsTab extends StatefulWidget {
  const ToolsTab({super.key});

  @override
  State<ToolsTab> createState() => _ToolsTabState();
}

class _ToolsTabState extends State<ToolsTab> {
  final _vCtrl = TextEditingController();
  final _iCtrl = TextEditingController();
  String _ohmsOut = 'Enter Voltage (V) and Current (A)';

  final List<String> _colors = [
    'Black', 'Brown', 'Red', 'Orange', 'Yellow',
    'Green', 'Blue', 'Violet', 'Grey', 'White'
  ];
  int _b1 = 1;
  int _b2 = 0;
  int _mult = 2;

  final _prevCgpaCtrl = TextEditingController(text: '3.50');
  final _prevCredCtrl = TextEditingController(text: '60');
  final _semGpaCtrl = TextEditingController(text: '3.80');
  final _semCredCtrl = TextEditingController(text: '18');
  String _cgpaOut = 'Projected CGPA: 3.57 (78 total credits)';

  void _calcOhms() {
    final v = double.tryParse(_vCtrl.text.trim());
    final i = double.tryParse(_iCtrl.text.trim());
    if (v == null || i == null || i == 0) {
      setState(() => _ohmsOut = 'Enter valid numbers (Current cannot be 0).');
      return;
    }
    setState(() {
      _ohmsOut = 'R = ${(v / i).toStringAsFixed(2)} Ω   |   P = ${(v * i).toStringAsFixed(2)} W';
    });
  }

  String _resistorValue() {
    final ohms = ((_b1 * 10) + _b2) * pow(10, _mult).toDouble();
    if (ohms >= 1e6) return '${(ohms / 1e6).toStringAsFixed(2)} MΩ ±5%';
    if (ohms >= 1e3) return '${(ohms / 1e3).toStringAsFixed(2)} kΩ ±5%';
    return '${ohms.toStringAsFixed(0)} Ω ±5%';
  }

  void _calcCgpa() {
    final prevCgpa = double.tryParse(_prevCgpaCtrl.text.trim()) ?? 0;
    final prevCred = double.tryParse(_prevCredCtrl.text.trim()) ?? 0;
    final semGpa = double.tryParse(_semGpaCtrl.text.trim()) ?? 0;
    final semCred = double.tryParse(_semCredCtrl.text.trim()) ?? 0;
    final total = prevCred + semCred;
    if (total <= 0) return;

    final projected = ((prevCgpa * prevCred) + (semGpa * semCred)) / total;
    setState(() => _cgpaOut = 'Projected CGPA: ${projected.toStringAsFixed(2)} ($total total credits)');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildEleesaAppBar(title: 'Offline Tools'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Ohm's Law & Power", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  TextField(controller: _vCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Voltage (V)', border: OutlineInputBorder())),
                  const SizedBox(height: 10),
                  TextField(controller: _iCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Current (A)', border: OutlineInputBorder())),
                  const SizedBox(height: 10),
                  ElevatedButton(onPressed: _calcOhms, child: const Text('Calculate')),
                  const SizedBox(height: 8),
                  Text(_ohmsOut, style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Resistor Color Code Decoder', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  DropdownButtonFormField<int>(
                    value: _b1,
                    decoration: const InputDecoration(labelText: 'Band 1'),
                    items: List.generate(_colors.length, (i) => DropdownMenuItem(value: i, child: Text('${_colors[i]} ($i)'))),
                    onChanged: (v) => setState(() => _b1 = v ?? 1),
                  ),
                  DropdownButtonFormField<int>(
                    value: _b2,
                    decoration: const InputDecoration(labelText: 'Band 2'),
                    items: List.generate(_colors.length, (i) => DropdownMenuItem(value: i, child: Text('${_colors[i]} ($i)'))),
                    onChanged: (v) => setState(() => _b2 = v ?? 0),
                  ),
                  DropdownButtonFormField<int>(
                    value: _mult,
                    decoration: const InputDecoration(labelText: 'Multiplier'),
                    items: List.generate(7, (i) => DropdownMenuItem(value: i, child: Text('${_colors[i]} (×10^$i)'))),
                    onChanged: (v) => setState(() => _mult = v ?? 2),
                  ),
                  const SizedBox(height: 10),
                  Text('Resistance: ${_resistorValue()}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('CGPA Projection Calculator', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  TextField(controller: _prevCgpaCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Current CGPA', border: OutlineInputBorder())),
                  const SizedBox(height: 10),
                  TextField(controller: _prevCredCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Credits Completed So Far', border: OutlineInputBorder())),
                  const SizedBox(height: 10),
                  TextField(controller: _semGpaCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Expected Semester GPA', border: OutlineInputBorder())),
                  const SizedBox(height: 10),
                  TextField(controller: _semCredCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Current Semester Credits', border: OutlineInputBorder())),
                  const SizedBox(height: 10),
                  ElevatedButton(onPressed: _calcCgpa, child: const Text('Calculate CGPA')),
                  const SizedBox(height: 8),
                  Text(_cgpaOut, style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}