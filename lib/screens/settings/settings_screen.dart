import 'package:flutter/material.dart';
import '../../theme/theme_controller.dart';
import '../profile/profile_screen.dart';

class SettingsScreen extends StatelessWidget {
  final String email;
  final String fullName;
  final String roleKey;
  final VoidCallback onLogout;

  const SettingsScreen({
    super.key,
    required this.email,
    required this.fullName,
    required this.roleKey,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: eleesaTheme,
      builder: (context, _) {
        final p = eleesaTheme.paletteForRole(roleKey);
        return Scaffold(
          backgroundColor: p.canvas,
          appBar: AppBar(
            backgroundColor: p.surface,
            foregroundColor: p.textPrimary,
            title: const Text('Settings & Appearance'),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _headerLabel(p, 'APPEARANCE & DISPLAY'),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: p.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: p.border),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      value: eleesaTheme.isDark,
                      activeThumbColor: p.accent,
                      onChanged: eleesaTheme.setDarkMode,
                      title: Text(
                        'Obsidian Dark Theme',
                        style: TextStyle(
                          color: p.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        eleesaTheme.isDark
                            ? 'High-contrast obsidian slate mode active'
                            : 'Daylight studio mode active',
                        style: TextStyle(color: p.textSecondary, fontSize: 12.5),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _headerLabel(p, 'COMMUNITY & NOTIFICATIONS'),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: p.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: p.border),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      value: eleesaTheme.publicInDirectory,
                      activeThumbColor: p.accent,
                      onChanged: eleesaTheme.setPublicInDirectory,
                      title: Text(
                        'Appear in "Know Your People"',
                        style: TextStyle(
                          color: p.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        'Allow verified ELEESA members to see your name, level & avatar',
                        style: TextStyle(color: p.textSecondary, fontSize: 12.5),
                      ),
                    ),
                    Divider(height: 1, color: p.border),
                    SwitchListTile(
                      value: eleesaTheme.notifyNotices,
                      activeThumbColor: p.accent,
                      onChanged: eleesaTheme.setNotifyNotices,
                      title: Text(
                        'Department & IEEE/GhIE Notices',
                        style: TextStyle(
                          color: p.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        'Receive alerts for seminars, deadlines & HoD notices',
                        style: TextStyle(color: p.textSecondary, fontSize: 12.5),
                      ),
                    ),
                    Divider(height: 1, color: p.border),
                    SwitchListTile(
                      value: eleesaTheme.notifyTimetable,
                      activeThumbColor: p.accent,
                      onChanged: eleesaTheme.setNotifyTimetable,
                      title: Text(
                        'Lecture & Exam Timetable Alerts',
                        style: TextStyle(
                          color: p.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        'Daily schedule reminders for your academic level',
                        style: TextStyle(color: p.textSecondary, fontSize: 12.5),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _headerLabel(p, 'ACCOUNT & SECURITY VAULT'),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: p.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: p.border),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.account_circle_outlined, color: p.accent),
                      title: Text(
                        'Profile Photo & Encrypted Vault',
                        style: TextStyle(
                          color: p.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        '$email \u2022 AES-256-GCM Protected',
                        style: TextStyle(color: p.textSecondary, fontSize: 12.5),
                      ),
                      trailing: Icon(Icons.chevron_right, color: p.textSecondary),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProfileScreen(
                              email: email,
                              fullName: fullName,
                              roleKey: roleKey,
                            ),
                          ),
                        );
                      },
                    ),
                    Divider(height: 1, color: p.border),
                    ListTile(
                      leading: const Icon(Icons.logout, color: Color(0xFFEF4444)),
                      title: const Text(
                        'Sign Out of ELEESA Grid',
                        style: TextStyle(
                          color: Color(0xFFEF4444),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onTap: onLogout,
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

  Widget _headerLabel(EleesaPalette p, String text) {
    return Text(
      text,
      style: TextStyle(
        color: p.accent,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
      ),
    );
  }
}