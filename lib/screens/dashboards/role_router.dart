import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/profile_service.dart';
import '../../widgets/electric_ui.dart';
import '../../widgets/profile_onboarding_dialog.dart';
import '../auth/login_screen.dart';
import '../profile/profile_screen.dart';

class RoleBasedDashboard extends StatefulWidget {
  final EleesaUser user;
  const RoleBasedDashboard({super.key, required this.user});

  @override
  State<RoleBasedDashboard> createState() => _RoleBasedDashboardState();
}

class _RoleBasedDashboardState extends State<RoleBasedDashboard> {
  final _profileService = ProfileService();
  Map<String, dynamic>? _profile;
  Map<String, dynamic> _studentsByLevel = {
    '100': [],
    '200': [],
    '300': [],
    '400': [],
  };
  Map<String, int> _levelCounts = {
    '100': 0,
    '200': 0,
    '300': 0,
    '400': 0,
    'total': 0,
  };
  List<Map<String, dynamic>> _staffDirectory = [];
  String _selectedLevelTab = '100';
  String _searchQuery = '';
  bool _loading = true;

  String get _roleKey {
    final r = widget.user.role.name;
    if (r == 'hodAdmin' || r == 'hod_admin') return 'hod_admin';
    return r;
  }

  bool get _isStudent => _roleKey == 'student' || _roleKey == 'executive';
  bool get _isHod => _roleKey == 'hod_admin';

  @override
  void initState() {
    super.initState();
    _initHub();
  }

  Future<void> _initHub() async {
    setState(() => _loading = true);
    try {
      final res = await _profileService.fetchProfile(widget.user.email);
      final userData = res['user'];
      final prof = res['profile'];
      final completed = (userData is Map && userData['profile_completed'] == true) ||
          prof is Map;

      if (mounted) {
        setState(() {
          _profile = prof is Map<String, dynamic>
              ? prof
              : (prof is Map ? Map<String, dynamic>.from(prof) : null);
        });
      }

      if (!completed && mounted) {
        await showProfileOnboardingPopup(
          context: context,
          email: widget.user.email,
          initialFullName: widget.user.fullName,
          roleKey: _roleKey,
          isMandatory: true,
        );
        final refreshed = await _profileService.fetchProfile(widget.user.email);
        final refreshedProf = refreshed['profile'];
        if (mounted) {
          setState(() {
            _profile = refreshedProf is Map<String, dynamic>
                ? refreshedProf
                : (refreshedProf is Map
                    ? Map<String, dynamic>.from(refreshedProf)
                    : null);
          });
        }
      }

      if (!_isStudent) {
        final levelData =
            await _profileService.fetchStudentsByLevel(widget.user.email);
        final rawCounts = levelData['counts'];
        final countsMap = rawCounts is Map ? rawCounts : {};
        final rawLevels = levelData['levels'];
        if (mounted) {
          setState(() {
            if (rawLevels is Map<String, dynamic>) {
              _studentsByLevel = rawLevels;
            } else if (rawLevels is Map) {
              _studentsByLevel = Map<String, dynamic>.from(rawLevels);
            }
            _levelCounts = {
              '100': int.tryParse('${countsMap['100'] ?? 0}') ?? 0,
              '200': int.tryParse('${countsMap['200'] ?? 0}') ?? 0,
              '300': int.tryParse('${countsMap['300'] ?? 0}') ?? 0,
              '400': int.tryParse('${countsMap['400'] ?? 0}') ?? 0,
              'total': int.tryParse('${countsMap['total'] ?? 0}') ?? 0,
            };
          });
        }
        if (_isHod) {
          final staff =
              await _profileService.fetchStaffDirectory(widget.user.email);
          if (mounted) setState(() => _staffDirectory = staff);
        }
      }
    } catch (_) {
      // Keep UI responsive on offline retry
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileScreen(
          email: widget.user.email,
          fullName: (_profile?['full_name'] ?? widget.user.fullName).toString(),
          roleKey: _roleKey,
        ),
      ),
    );
    _initHub();
  }

  void _logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final appBarColor = _isStudent
        ? EleesaColors.deepNavy
        : (_isHod ? const Color(0xFF050B14) : const Color(0xFF111827));
    final hubTitle = _isStudent
        ? 'ELEESA Student Hub'
        : (_isHod ? 'ELEESA HoD Control Room' : 'ELEESA Lecturer Hub');

    return Scaffold(
      appBar: AppBar(
        title: Text(hubTitle),
        backgroundColor: appBarColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Refresh Grid',
            icon: const Icon(Icons.refresh),
            onPressed: _initHub,
          ),
          IconButton(
            tooltip: 'Sign Out',
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _initHub,
              child: ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  if (_isStudent) _buildStudentHub(),
                  if (!_isStudent && !_isHod) _buildLecturerHub(),
                  if (_isHod) _buildHodHub(),
                ],
              ),
            ),
    );
  }

  // --- HUB 1: STUDENT OSCILLOSCOPE TELEMETRY DECK ---
  Widget _buildStudentHub() {
    final p = _profile ?? {};
    final level = (p['level'] ?? '---').toString();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StudentOscilloscopeHeader(
          studentName: (p['full_name'] ?? widget.user.fullName).toString(),
          level: level,
          indexNumber: (p['index_number'] ?? '').toString(),
          onProfileTap: _openProfile,
        ),
        const SizedBox(height: 18),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: EleesaColors.deepNavy,
              child: Icon(Icons.security, color: EleesaColors.electricCyan),
            ),
            title: Text(
              'Assigned Database Table: level_${level}_students',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
            ),
            subtitle: Text(
              'Track: ${p['specialization'] ?? 'Electrical & Electronic Engineering'}',
            ),
            trailing: TextButton(
              onPressed: _openProfile,
              child: const Text('Edit'),
            ),
          ),
        ),
      ],
    );
  }

  // --- HUB 2: LECTURER 3-PHASE BUSBAR & 4-LEVEL STUDENT REGISTRY ---
  Widget _buildLecturerHub() {
    final p = _profile ?? {};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LecturerBusbarHeader(
          lecturerName: (p['full_name'] ?? widget.user.fullName).toString(),
          titleAndSpec:
              '${p['academic_title'] ?? 'Lecturer'}  •  ${p['specialization'] ?? 'EEE Faculty'}',
          totalStudents: _levelCounts['total'] ?? 0,
          onProfileTap: _openProfile,
        ),
        const SizedBox(height: 18),
        _buildFourLevelStudentInspector(accentColor: EleesaColors.highVoltageAmber),
      ],
    );
  }

  // --- HUB 3: HoD MAIN GRID CONTROL ROOM & STAFF DIRECTORY ---
  Widget _buildHodHub() {
    final p = _profile ?? {};
    const emerald = Color(0xFF10B981);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HodMainGridHeader(
          hodName: (p['full_name'] ?? widget.user.fullName).toString(),
          levelCounts: _levelCounts,
          onProfileTap: _openProfile,
        ),
        const SizedBox(height: 18),
        _buildFourLevelStudentInspector(accentColor: emerald),
        const SizedBox(height: 22),
        const Text(
          'Department Faculty & Staff Registry',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (_staffDirectory.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('No faculty profiles registered yet.'),
            ),
          )
        else
          ..._staffDirectory.map(
            (s) => Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFF063729),
                  child: Icon(Icons.engineering, color: emerald),
                ),
                title: Text(
                  '${s['academic_title']} ${s['full_name']}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'ID: ${s['staff_id']} • ${s['specialization']}\nPhone: ${s['phone']} • ${s['office_hours']}',
                ),
                isThreeLine: true,
              ),
            ),
          ),
      ],
    );
  }

  // --- SHARED 4-LEVEL STUDENT INSPECTOR FOR LECTURER & HoD HUBS ---
  Widget _buildFourLevelStudentInspector({required Color accentColor}) {
    final rawList = _studentsByLevel[_selectedLevelTab];
    final items = rawList is Iterable ? rawList.toList() : [];
    final list = items
        .map((item) => item is Map<String, dynamic>
            ? item
            : (item is Map ? Map<String, dynamic>.from(item) : <String, dynamic>{}))
        .where((s) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return s['full_name'].toString().toLowerCase().contains(q) ||
          s['index_number'].toString().toLowerCase().contains(q);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '4-Level Student Database (Decrypted View)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Row(
          children: ['100', '200', '300', '400'].map((lvl) {
            final selected = _selectedLevelTab == lvl;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: ChoiceChip(
                  label: Text('Lvl $lvl (${_levelCounts[lvl] ?? 0})'),
                  selected: selected,
                  selectedColor: EleesaColors.deepNavy,
                  labelStyle: TextStyle(
                    color: selected ? accentColor : Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 11.5,
                  ),
                  onSelected: (_) => setState(() => _selectedLevelTab = lvl),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 10),
        TextField(
          decoration: InputDecoration(
            hintText: 'Search Level $_selectedLevelTab by name or index number...',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            isDense: true,
          ),
          onChanged: (v) => setState(() => _searchQuery = v.trim()),
        ),
        const SizedBox(height: 12),
        if (list.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Text(
                'No students currently stored in level_${_selectedLevelTab}_students.',
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          ...list.map(
            (st) => Card(
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: ExpansionTile(
                leading: CircleAvatar(
                  backgroundColor: EleesaColors.deepNavy,
                  child: Text(
                    st['level'].toString(),
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  st['full_name'].toString(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Index: ${st['index_number']}  •  ${st['specialization']}',
                ),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '• Email: ${st['email']}\n'
                      '• Gender: ${st['gender']}   |   DoB (Decrypted): ${st['dob']}\n'
                      '• Phone: ${st['phone']}   |   Emergency: ${st['emergency_contact']}\n'
                      '• Residence: ${st['hostel']}   |   Table: ${st['table_name']}',
                      style: const TextStyle(fontSize: 12.5, height: 1.55),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}