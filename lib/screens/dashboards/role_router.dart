import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/academic_service.dart';
import '../../services/profile_service.dart';
import '../../theme/theme_controller.dart';
import '../../widgets/electric_ui.dart';
import '../../widgets/profile_onboarding_dialog.dart';
import '../academic/academic_hub_screen.dart';
import '../academic/department_directory_screen.dart';
import '../auth/login_screen.dart';
import '../profile/profile_screen.dart';
import '../settings/settings_screen.dart';
import '../wave3/wave3_hub_screen.dart';
import '../wave4/wave4_community_hub.dart';
import '../wave5/wave5_tools_hub.dart';

class RoleBasedDashboard extends StatefulWidget {
  final EleesaUser user;
  const RoleBasedDashboard({super.key, required this.user});

  @override
  State<RoleBasedDashboard> createState() => _RoleBasedDashboardState();
}

class _RoleBasedDashboardState extends State<RoleBasedDashboard> {
  final _profileService = ProfileService();
  final _academicService = AcademicService();
  int _bottomTab = 0;
  int _academicInitialTab = 0;

  Map<String, dynamic>? _profile;
  List<Map<String, dynamic>> _todaySchedule = [];
  List<Map<String, dynamic>> _calendarHighlights = [];
  int _totalCourses = 0;

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
  bool get _isStaff => !_isStudent;

  @override
  void initState() {
    super.initState();
    _initHub();
  }

  Future<void> _initHub() async {
    setState(() => _loading = true);
    try {
      final res = await _profileService.fetchProfile(widget.user.email);
      final userMap = res['user'] as Map<String, dynamic>? ?? {};
      final profMap = res['profile'] as Map<String, dynamic>?;
      final completed = userMap['profile_completed'] == true;
      final userLevel = (profMap?['level'] ?? userMap['level'] ?? '300').toString();

      final ov = await _academicService.fetchOverview(
        email: widget.user.email,
        level: _isStudent ? userLevel : 'ALL',
      );

      if (!mounted) return;
      setState(() {
        _profile = profMap;
        _todaySchedule = List<Map<String, dynamic>>.from(ov['schedule'] ?? []);
        _calendarHighlights = List<Map<String, dynamic>>.from(ov['calendar'] ?? []);
        _totalCourses = (ov['course_count'] ?? 0) as int;
      });

      if (!completed) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;
          final saved = await showProfileOnboardingPopup(
            context: context,
            email: widget.user.email,
            initialFullName: widget.user.fullName,
            roleKey: _roleKey,
            isMandatory: true,
          );
          if (saved == true && mounted) {
            _initHub();
          }
        });
      }

      if (_isStaff) {
        final grid =
            await _profileService.fetchStudentsByLevel(widget.user.email);
        final rawLevels = Map<String, dynamic>.from(grid['levels'] ?? {});
        final rawCounts = Map<String, dynamic>.from(grid['counts'] ?? {});
        List<Map<String, dynamic>> staff = [];
        if (_isHod) {
          staff = await _profileService.fetchStaffDirectory(widget.user.email);
        }
        if (!mounted) return;
        setState(() {
          _studentsByLevel = rawLevels;
          _levelCounts = {
            '100': (rawCounts['100'] ?? 0) as int,
            '200': (rawCounts['200'] ?? 0) as int,
            '300': (rawCounts['300'] ?? 0) as int,
            '400': (rawCounts['400'] ?? 0) as int,
            'total': (rawCounts['total'] ?? 0) as int,
          };
          _staffDirectory = staff;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openAcademicSection(int subTab) {
    setState(() {
      _academicInitialTab = subTab;
      _bottomTab = 1;
    });
  }

  void _logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _showModuleWaveNotice(String moduleName, String waveTag) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$moduleName is queued for $waveTag rollout.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: eleesaTheme,
      builder: (context, _) {
        final p = eleesaTheme.paletteForRole(_roleKey);
        final displayName =
            (_profile?['full_name'] ?? widget.user.fullName).toString();
        final hubSubtitle = _isStudent
            ? 'STUDENT HUB \u2022 LEVEL ${_profile?['level'] ?? '---'}'
            : (_isHod ? 'HOD CONTROL ROOM' : 'LECTURER BUSBAR');

        return Scaffold(
          backgroundColor: p.canvas,
          appBar: AppBar(
            backgroundColor: p.surface,
            foregroundColor: p.textPrimary,
            titleSpacing: 4,
            title: Row(
              children: [
                EleesaCrestLogo(size: 32, accent: p.accent),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ELEESA Hub',
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.bold,
                          color: p.textPrimary,
                        ),
                      ),
                      Text(
                        hubSubtitle,
                        style: TextStyle(
                          fontSize: 9.5,
                          letterSpacing: 1.1,
                          fontWeight: FontWeight.w800,
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
                tooltip: 'Toggle Theme',
                icon: Icon(
                  p.isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                  color: p.accent,
                ),
                onPressed: eleesaTheme.toggleTheme,
              ),
              IconButton(
                tooltip: 'Refresh Grid',
                icon: Icon(Icons.refresh, color: p.textSecondary),
                onPressed: _initHub,
              ),
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: GestureDetector(
                  onTap: () => setState(() => _bottomTab = 4),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: p.accent.withValues(alpha: 0.2),
                    child: Text(
                      displayName.isNotEmpty
                          ? displayName[0].toUpperCase()
                          : 'E',
                      style: TextStyle(
                        color: p.accent,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          drawer: _buildCategorizedDrawer(p, displayName),
          body: _buildBodyForTab(p, displayName),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: p.border, width: 1)),
            ),
            child: NavigationBar(
              backgroundColor: p.surface,
              indicatorColor: p.accent.withValues(alpha: 0.18),
              selectedIndex: _bottomTab,
              onDestinationSelected: (idx) => setState(() => _bottomTab = idx),
              destinations: [
                NavigationDestination(
                  icon: Icon(Icons.bolt_outlined, color: p.textSecondary),
                  selectedIcon: Icon(Icons.bolt, color: p.accent),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.menu_book_outlined, color: p.textSecondary),
                  selectedIcon: Icon(Icons.menu_book, color: p.accent),
                  label: 'Study',
                ),
                NavigationDestination(
                  icon: Icon(Icons.groups_outlined, color: p.textSecondary),
                  selectedIcon: Icon(Icons.groups, color: p.accent),
                  label: 'People',
                ),
                NavigationDestination(
                  icon: Icon(Icons.storefront_outlined, color: p.textSecondary),
                  selectedIcon: Icon(Icons.storefront, color: p.accent),
                  label: 'Store',
                ),
                NavigationDestination(
                  icon: Icon(Icons.shield_outlined, color: p.textSecondary),
                  selectedIcon: Icon(Icons.shield, color: p.accent),
                  label: 'My Vault',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBodyForTab(EleesaPalette p, String displayName) {
    if (_bottomTab == 4) {
      return ProfileScreen(
        email: widget.user.email,
        fullName: displayName,
        roleKey: _roleKey,
        embedded: true,
      );
    }

    if (_bottomTab == 1) {
      return AcademicHubScreen(
        key: ValueKey('acad_$_academicInitialTab'),
        email: widget.user.email,
        fullName: displayName,
        roleKey: _roleKey,
        userLevel: (_profile?['level'] ?? '100').toString(),
        initialTab: _academicInitialTab,
        embedded: true,
      );
    }

    if (_bottomTab == 2) {
      return Wave4CommunityHub(
        key: const ValueKey('wave4_people'),
        initialTabIndex: 0,
        embeddedInBottomNav: true,
        userRole: _roleKey,
        userName: displayName,
        userLevel: (_profile?['level'] ?? '300').toString(),
        accentColor: p.accent,
      );
    }

    if (_bottomTab == 3) {
      return Wave4CommunityHub(
        key: const ValueKey('wave4_store'),
        initialTabIndex: 1,
        embeddedInBottomNav: true,
        userRole: _roleKey,
        userName: displayName,
        userLevel: (_profile?['level'] ?? '300').toString(),
        accentColor: p.accent,
      );
    }

    if (_loading) {
      return Center(child: CircularProgressIndicator(color: p.accent));
    }

    return RefreshIndicator(
      onRefresh: _initHub,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_isStudent) _buildStudentHub(p),
          if (!_isStudent && !_isHod) _buildLecturerHub(p),
          if (_isHod) _buildHodHub(p),
          const SizedBox(height: 16),
          _buildDashboardAcademicWidgets(p),
        ],
      ),
    );
  }

  // --- SHARED HOME DASHBOARD WIDGETS (Item #1: Quick Links, Schedule & Calendar) ---
  Widget _buildDashboardAcademicWidgets(EleesaPalette p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'QUICK ACCESS COMMANDS',
          style: TextStyle(
            color: p.accent,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _quickTile(
              p,
              icon: Icons.menu_book_outlined,
              title: 'Courses ($_totalCourses)',
              sub: 'Syllabi & Credits',
              onTap: () => _openAcademicSection(0),
            ),
            const SizedBox(width: 8),
            _quickTile(
              p,
              icon: Icons.schedule_outlined,
              title: 'Timetables',
              sub: 'Lectures & Exams',
              onTap: () => _openAcademicSection(1),
            ),
            const SizedBox(width: 8),
            _quickTile(
              p,
              icon: Icons.badge_outlined,
              title: 'Faculty',
              sub: 'Staff & Hours',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DepartmentDirectoryScreen(
                    email: widget.user.email,
                    roleKey: _roleKey,
                    initialTab: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'TIMETABLE SNAPSHOT',
              style: TextStyle(
                color: p.accent,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
            GestureDetector(
              onTap: () => _openAcademicSection(1),
              child: Text(
                'Full Timetable \u2192',
                style: TextStyle(color: p.accent, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_todaySchedule.isEmpty)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: p.border),
            ),
            child: Text(
              'No lecture slots scheduled for this level yet.',
              style: TextStyle(color: p.textSecondary, fontSize: 12.5),
            ),
          )
        else
          ..._todaySchedule.take(3).map(
            (slot) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: p.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: p.border),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: p.accent.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      (slot['course_code'] ?? '').toString(),
                      style: TextStyle(color: p.accent, fontWeight: FontWeight.bold, fontSize: 11.5),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (slot['course_title'] ?? '').toString(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: p.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        Text(
                          '${slot['day_or_date']} \u2022 ${slot['time_slot']} \u2022 ${slot['venue']}',
                          style: TextStyle(color: p.textSecondary, fontSize: 11.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'ACADEMIC CALENDAR HIGHLIGHTS',
              style: TextStyle(
                color: p.accent,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
            GestureDetector(
              onTap: () => _openAcademicSection(2),
              child: Text(
                'All Dates \u2192',
                style: TextStyle(color: p.accent, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ..._calendarHighlights.take(3).map(
          (ev) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: p.border),
            ),
            child: Row(
              children: [
                Icon(Icons.event_note_outlined, color: p.accent, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (ev['title'] ?? '').toString(),
                        style: TextStyle(color: p.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      Text(
                        '${ev['event_date']} \u2022 ${ev['category']}',
                        style: TextStyle(color: p.textSecondary, fontSize: 11.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _quickTile(
    EleesaPalette p, {
    required IconData icon,
    required String title,
    required String sub,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: p.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: p.accent, size: 20),
              const SizedBox(height: 8),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: p.textPrimary, fontWeight: FontWeight.bold, fontSize: 12.5),
              ),
              const SizedBox(height: 2),
              Text(
                sub,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: p.textSecondary, fontSize: 10.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWavePreviewPage(
    EleesaPalette p, {
    required String kicker,
    required String title,
    required String description,
    required List<String> items,
  }) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
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
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              AnimatedCircuitStrip(accent: p.accent, height: 22),
              const SizedBox(height: 10),
              Text(
                description,
                style: TextStyle(
                  color: p.textSecondary,
                  fontSize: 13.5,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 14),
              for (final item in items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(Icons.bolt, size: 16, color: p.accent),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item,
                          style: TextStyle(color: p.textPrimary, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // --- CATEGORIZED NAVIGATION DRAWER (Item #11 & #13) ---
  void _openWave3Section(EleesaPalette p, String displayName, int tabIndex) {
    Navigator.pop(context);
    final lvl = (_profile?['level']?.toString().trim().isNotEmpty == true)
        ? _profile!['level'].toString()
        : '300';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Wave3HubScreen(
          initialTabIndex: tabIndex,
          userRole: 'student',
          userName: displayName,
          userEmail: widget.user.email,
          userLevel: lvl,
          accentColor: p.accent,
        ),
      ),
    );
  }
  Widget _buildCategorizedDrawer(EleesaPalette p, String displayName) {
    return Drawer(
      backgroundColor: p.surface,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: p.canvas,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: p.border),
              ),
              child: Row(
                children: [
                  EleesaCrestLogo(size: 38, accent: p.accent),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: p.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _roleKey.toUpperCase(),
                          style: TextStyle(
                            color: p.accent,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _drawerCategory(p, 'COMMAND & SCHEDULE'),
            _drawerTile(p, Icons.dashboard_outlined, 'Home Dashboard', () {
              Navigator.pop(context);
              setState(() => _bottomTab = 0);
            }),
            _drawerTile(p, Icons.calendar_today_outlined, 'Timetable & Calendar', () {
              Navigator.pop(context);
              _openAcademicSection(1);
            }),
            _drawerTile(p, Icons.account_tree_outlined, 'Courses & Curriculum', () {
              Navigator.pop(context);
              _openAcademicSection(0);
            }),
            _drawerTile(p, Icons.memory_outlined, 'Labs & Equipment', () {
              _openWave3Section(p, displayName, 1);
            }),

            const SizedBox(height: 10),
            _drawerCategory(p, 'STUDY & ENGINEERING'),
            _drawerTile(p, Icons.folder_special_outlined, 'Resource Library & Uploads', () {
              _openWave3Section(p, displayName, 0);
            }),
            _drawerTile(p, Icons.science_outlined, 'Projects & Research', () {
              _openWave3Section(p, displayName, 2);
            }),
            _drawerTile(p, Icons.engineering_outlined, 'Industrial Attachment', () {
              _openWave3Section(p, displayName, 3);
            }),
            _drawerTile(p, Icons.calculate_outlined, 'EEE Tools & CGPA Calc', () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => Wave5ToolsHub(initialTabIndex: 0, userRole: _roleKey, userName: displayName, userLevel: (_profile?['level'] ?? '300').toString(), accentColor: p.accent)));
            }),
            _drawerTile(p, Icons.description_outlined, 'Forms & Downloads', () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => Wave5ToolsHub(initialTabIndex: 1, userRole: _roleKey, userName: displayName, userLevel: (_profile?['level'] ?? '300').toString(), accentColor: p.accent)));
            }),

            const SizedBox(height: 10),
            _drawerCategory(p, 'COMMUNITY & MARKET'),
            _drawerTile(p, Icons.campaign_outlined, 'Notices & IEEE/GhIE Events', () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => Wave4CommunityHub(initialTabIndex: 2, userRole: _roleKey, userName: displayName, userLevel: (_profile?['level'] ?? '300').toString(), accentColor: p.accent)));
            }),
            _drawerTile(p, Icons.people_alt_outlined, 'Know Your People', () {
              Navigator.pop(context);
              setState(() => _bottomTab = 2);
            }),
            _drawerTile(p, Icons.storefront_outlined, 'ELEESA Store (Jiji Market)', () {
              Navigator.pop(context);
              setState(() => _bottomTab = 3);
            }),
            _drawerTile(p, Icons.work_outline, 'Alumni & Careers', () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => Wave4CommunityHub(initialTabIndex: 0, userRole: _roleKey, userName: displayName, userLevel: (_profile?['level'] ?? '300').toString(), accentColor: p.accent)));
            }),
            _drawerTile(p, Icons.support_agent_outlined, 'Feedback & Help Desk', () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => Wave5ToolsHub(initialTabIndex: 2, userRole: _roleKey, userName: displayName, userLevel: (_profile?['level'] ?? '300').toString(), accentColor: p.accent)));
            }),

            const SizedBox(height: 10),
            _drawerCategory(p, 'DEPARTMENT & ACCOUNT'),
            _drawerTile(p, Icons.info_outline, 'About the Department', () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DepartmentDirectoryScreen(
                    email: widget.user.email,
                    roleKey: _roleKey,
                    initialTab: 0,
                  ),
                ),
              );
            }),
            _drawerTile(p, Icons.badge_outlined, 'Staff Directory', () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DepartmentDirectoryScreen(
                    email: widget.user.email,
                    roleKey: _roleKey,
                    initialTab: 1,
                  ),
                ),
              );
            }),
            if (_isStaff)
              _drawerTile(
                p,
                Icons.admin_panel_settings_outlined,
                'Staff-Only Grid Tools',
                () {
                  Navigator.pop(context);
                  setState(() => _bottomTab = 0);
                },
              ),
            _drawerTile(p, Icons.shield_outlined, 'My Encrypted Vault & Photo', () {
              Navigator.pop(context);
              setState(() => _bottomTab = 4);
            }),
            _drawerTile(p, Icons.settings_outlined, 'Settings & Theme', () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SettingsScreen(
                    email: widget.user.email,
                    fullName: displayName,
                    roleKey: _roleKey,
                    onLogout: _logout,
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _drawerCategory(EleesaPalette p, String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 4),
      child: Text(
        label,
        style: TextStyle(
          color: p.accent,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _drawerTile(
    EleesaPalette p,
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    return ListTile(
      dense: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      leading: Icon(icon, size: 20, color: p.textSecondary),
      title: Text(
        title,
        style: TextStyle(
          color: p.textPrimary,
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
        ),
      ),
      onTap: onTap,
    );
  }

  // --- HUB 1: STUDENT OSCILLOSCOPE TELEMETRY DECK ---
  Widget _buildStudentHub(EleesaPalette palette) {
    final p = _profile ?? {};
    final level = (p['level'] ?? '---').toString();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StudentOscilloscopeHeader(
          studentName: (p['full_name'] ?? widget.user.fullName).toString(),
          level: level,
          indexNumber: (p['index_number'] ?? '').toString(),
          onProfileTap: () => setState(() => _bottomTab = 4),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: palette.border),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: palette.accent.withValues(alpha: 0.16),
                child: Icon(Icons.security, color: palette.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Assigned Table: level_${level}_students',
                      style: TextStyle(
                        color: palette.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Track: ${p['specialization'] ?? 'Electrical & Electronic Engineering'}',
                      style: TextStyle(
                        color: palette.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => setState(() => _bottomTab = 4),
                child: Text(
                  'Vault',
                  style: TextStyle(
                    color: palette.accent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- HUB 2: LECTURER 3-PHASE BUSBAR & 4-LEVEL STUDENT REGISTRY ---
  Widget _buildLecturerHub(EleesaPalette palette) {
    final p = _profile ?? {};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LecturerBusbarHeader(
          lecturerName: (p['full_name'] ?? widget.user.fullName).toString(),
          titleAndSpec:
              '${p['academic_title'] ?? 'Lecturer'}  \u2022  ${p['specialization'] ?? 'EEE Faculty'}',
          totalStudents: _levelCounts['total'] ?? 0,
          onProfileTap: () => setState(() => _bottomTab = 4),
        ),
        const SizedBox(height: 16),
        _buildFourLevelStudentInspector(
          palette,
          accentColor: EleesaColors.highVoltageAmber,
        ),
      ],
    );
  }

  // --- HUB 3: HoD MAIN GRID CONTROL ROOM & STAFF DIRECTORY ---
  Widget _buildHodHub(EleesaPalette palette) {
    final p = _profile ?? {};
    const emerald = Color(0xFF10B981);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HodMainGridHeader(
          hodName: (p['full_name'] ?? widget.user.fullName).toString(),
          levelCounts: _levelCounts,
          onProfileTap: () => setState(() => _bottomTab = 4),
        ),
        const SizedBox(height: 16),
        _buildFourLevelStudentInspector(palette, accentColor: emerald),
        const SizedBox(height: 18),
        Text(
          'DEPARTMENT FACULTY & STAFF REGISTRY',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: palette.accent,
          ),
        ),
        const SizedBox(height: 8),
        if (_staffDirectory.isEmpty)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: palette.border),
            ),
            child: Text(
              'No staff profiles registered yet.',
              style: TextStyle(color: palette.textSecondary),
            ),
          )
        else
          ..._staffDirectory.map(
            (s) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: palette.border),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: emerald.withValues(alpha: 0.18),
                  child: const Icon(Icons.school, color: emerald),
                ),
                title: Text(
                  '${s['academic_title'] ?? 'Staff'} ${s['full_name'] ?? ''}',
                  style: TextStyle(
                    color: palette.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  'ID: ${s['staff_id']} \u2022 ${s['specialization']}\nPhone: ${s['phone']} \u2022 Hours: ${s['office_hours']}',
                  style: TextStyle(color: palette.textSecondary, fontSize: 12),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // --- SHARED 4-LEVEL STUDENT DATABASE VIEWER (STAFF-ONLY TOOL #13) ---
  Widget _buildFourLevelStudentInspector(
    EleesaPalette palette, {
    required Color accentColor,
  }) {
    final rawList = List<Map<String, dynamic>>.from(
      _studentsByLevel[_selectedLevelTab] ?? [],
    );
    final filtered = rawList.where((st) {
      if (_searchQuery.trim().isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return (st['full_name'] ?? '').toString().toLowerCase().contains(q) ||
          (st['index_number'] ?? '').toString().toLowerCase().contains(q) ||
          (st['specialization'] ?? '').toString().toLowerCase().contains(q);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '4-LEVEL STUDENT DATABASE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: accentColor,
              ),
            ),
            Text(
              'Table: level_${_selectedLevelTab}_students',
              style: TextStyle(
                fontSize: 11.5,
                color: palette.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: ['100', '200', '300', '400'].map((lvl) {
            final selected = _selectedLevelTab == lvl;
            final count = _levelCounts[lvl] ?? 0;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: ChoiceChip(
                  label: Text('Lvl $lvl ($count)'),
                  selected: selected,
                  selectedColor: accentColor.withValues(alpha: 0.22),
                  backgroundColor: palette.surface,
                  side: BorderSide(
                    color: selected ? accentColor : palette.border,
                  ),
                  labelStyle: TextStyle(
                    color: selected ? accentColor : palette.textSecondary,
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
          style: TextStyle(color: palette.textPrimary),
          decoration: InputDecoration(
            hintText: 'Search Level $_selectedLevelTab by name or index...',
            hintStyle: TextStyle(color: palette.textSecondary, fontSize: 13),
            prefixIcon: Icon(Icons.search, color: accentColor),
            filled: true,
            fillColor: palette.surface,
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: palette.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: accentColor),
            ),
          ),
          onChanged: (v) => setState(() => _searchQuery = v),
        ),
        const SizedBox(height: 10),
        if (filtered.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: palette.border),
            ),
            child: Text(
              'No students recorded in level_${_selectedLevelTab}_students yet.',
              textAlign: TextAlign.center,
              style: TextStyle(color: palette.textSecondary),
            ),
          )
        else
          ...filtered.map(
            (st) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: palette.border),
              ),
              child: ExpansionTile(
                iconColor: accentColor,
                collapsedIconColor: palette.textSecondary,
                leading: CircleAvatar(
                  backgroundColor: accentColor.withValues(alpha: 0.18),
                  child: Text(
                    (st['full_name'] ?? 'S')
                        .toString()
                        .substring(0, 1)
                        .toUpperCase(),
                    style: TextStyle(
                      color: accentColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  (st['full_name'] ?? '').toString(),
                  style: TextStyle(
                    color: palette.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  'Index: ${st['index_number']}  \u2022  ${st['specialization']}',
                  style: TextStyle(color: palette.textSecondary, fontSize: 12),
                ),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                children: [
                  Divider(color: palette.border),
                  _detailRow(palette, 'Email', (st['email'] ?? '').toString()),
                  _detailRow(palette, 'Gender', (st['gender'] ?? '').toString()),
                  _detailRow(
                    palette,
                    'Date of Birth (Decrypted)',
                    (st['dob'] ?? '').toString(),
                  ),
                  _detailRow(
                    palette,
                    'Phone (Decrypted)',
                    (st['phone'] ?? '').toString(),
                  ),
                  _detailRow(
                    palette,
                    'Hostel (Decrypted)',
                    (st['hostel'] ?? '').toString(),
                  ),
                  _detailRow(
                    palette,
                    'Emergency Contact',
                    (st['emergency_contact'] ?? '').toString(),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _detailRow(EleesaPalette palette, String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: palette.textSecondary, fontSize: 12.5),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              val,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: palette.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 12.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}