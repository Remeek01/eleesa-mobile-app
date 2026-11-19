import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../auth/login_screen.dart';

class RoleBasedDashboard extends StatelessWidget {
  final EleesaUser user;

  const RoleBasedDashboard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return switch (user.role) {
      UserRole.student => StudentDashboard(user: user),
      UserRole.lecturer => LecturerDashboard(user: user),
      UserRole.hod => HodDashboard(user: user),
    };
  }
}

void _logout(BuildContext context) {
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (_) => const LoginScreen()),
    (route) => false,
  );
}

// 1. STUDENT INTERFACE
class StudentDashboard extends StatelessWidget {
  final EleesaUser user;
  const StudentDashboard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ELEESA Student Hub'),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: () => _logout(context)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _WelcomeHeader(name: user.fullName, roleLabel: 'Student Portal', color: Colors.blue.shade800),
          const SizedBox(height: 16),
          _ActionTile(icon: Icons.menu_book, title: 'My Courses & Lecture Notes', subtitle: 'Access slides, lab manuals & past questions'),
          _ActionTile(icon: Icons.assignment_turned_in, title: 'Assignments & Submissions', subtitle: 'View deadlines and upload coursework'),
          _ActionTile(icon: Icons.campaign, title: 'Departmental Announcements', subtitle: 'Updates from ELEESA executives & HOD'),
          _ActionTile(icon: Icons.schedule, title: 'Lecture & Lab Timetable', subtitle: 'Weekly schedule and venue updates'),
        ],
      ),
    );
  }
}

// 2. LECTURER INTERFACE
class LecturerDashboard extends StatelessWidget {
  final EleesaUser user;
  const LecturerDashboard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ELEESA Lecturer Workspace'),
        backgroundColor: Colors.teal.shade800,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: () => _logout(context)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _WelcomeHeader(name: user.fullName, roleLabel: 'Faculty / Lecturer', color: Colors.teal.shade800),
          const SizedBox(height: 16),
          _ActionTile(icon: Icons.upload_file, title: 'Upload Course Materials', subtitle: 'Publish lecture notes & lab sheets to students'),
          _ActionTile(icon: Icons.grading, title: 'Grade Submissions & CA Scores', subtitle: 'Review student uploads and enter continuous assessment'),
          _ActionTile(icon: Icons.people_alt, title: 'Class Rosters & Attendance', subtitle: 'Manage assigned courses and student lists'),
          _ActionTile(icon: Icons.notifications_active, title: 'Post Course Notice', subtitle: 'Notify students of rescheduled classes or quizzes'),
        ],
      ),
    );
  }
}

// 3. HOD INTERFACE
class HodDashboard extends StatelessWidget {
  final EleesaUser user;
  const HodDashboard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ELEESA HOD Executive Console'),
        backgroundColor: Colors.deepPurple.shade800,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: () => _logout(context)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _WelcomeHeader(name: user.fullName, roleLabel: 'Head of Department (HOD)', color: Colors.deepPurple.shade800),
          const SizedBox(height: 16),
          _ActionTile(icon: Icons.verified_user, title: 'Approve Staff & Lecturer Accounts', subtitle: 'Verify faculty registrations and role permissions'),
          _ActionTile(icon: Icons.account_tree, title: 'Course Allocation & Curriculum', subtitle: 'Assign lecturers to semester courses'),
          _ActionTile(icon: Icons.analytics, title: 'Departmental Analytics & Results', subtitle: 'Overview of student performance across levels 100–400'),
          _ActionTile(icon: Icons.broadcast_on_personal, title: 'Official Departmental Broadcast', subtitle: 'Send priority notices to all students & faculty'),
        ],
      ),
    );
  }
}

class _WelcomeHeader extends StatelessWidget {
  final String name;
  final String roleLabel;
  final Color color;

  const _WelcomeHeader({required this.name, required this.roleLabel, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color.withOpacity(0.1),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(roleLabel.toUpperCase(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text('Welcome, $name', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _ActionTile({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, size: 30),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$title — ready to wire to backend endpoint')),
          );
        },
      ),
    );
  }
}