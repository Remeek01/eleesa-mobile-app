import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/profile_service.dart';
import '../../theme/theme_controller.dart';
import '../../widgets/profile_onboarding_dialog.dart';

class ProfileScreen extends StatefulWidget {
  final String email;
  final String fullName;
  final String roleKey;
  final bool embedded;

  const ProfileScreen({
    super.key,
    required this.email,
    required this.fullName,
    required this.roleKey,
    this.embedded = false,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _profileService = ProfileService();
  Map<String, dynamic>? _profile;
  String _avatarData = '';
  bool _loading = true;
  bool _revealSensitive = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);
    try {
      final res = await _profileService.fetchProfile(widget.email);
      final rawProf = res['profile'];
      final rawUser = res['user'];
      if (mounted) {
        setState(() {
          if (rawUser is Map) {
            _avatarData = (rawUser['avatar_data'] ?? '').toString();
          }
          if (rawProf is Map<String, dynamic>) {
            _profile = rawProf;
          } else if (rawProf is Map) {
            _profile = Map<String, dynamic>.from(rawProf);
          } else {
            _profile = null;
          }
        });
      }
    } catch (_) {
      // Keep existing state on network retry
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _editProfile() async {
    final p = _profile ?? {};
    await showProfileOnboardingPopup(
      context: context,
      email: widget.email,
      initialFullName: (p['full_name'] ?? widget.fullName).toString(),
      roleKey: widget.roleKey,
      isMandatory: false,
    );
    await _loadProfile();
  }

  Future<void> _openAvatarStudio(EleesaPalette palette) async {
    final urlController = TextEditingController(
      text: _avatarData.startsWith('http') ? _avatarData : '',
    );
    String selectedPreset = _avatarData.startsWith('preset:')
        ? _avatarData
        : 'preset:cyan';
    bool saving = false;

    final presets = [
      {'id': 'preset:cyan', 'label': 'Cyan Pulse', 'color': const Color(0xFF00E5FF)},
      {'id': 'preset:amber', 'label': '3-Phase Amber', 'color': const Color(0xFFF59E0B)},
      {'id': 'preset:emerald', 'label': 'Grid Emerald', 'color': const Color(0xFF10B981)},
      {'id': 'preset:cobalt', 'label': 'Cobalt Core', 'color': const Color(0xFF3B82F6)},
      {'id': 'preset:violet', 'label': 'Plasma Violet', 'color': const Color(0xFF8B5CF6)},
      {'id': 'preset:crimson', 'label': 'High-Volt Red', 'color': const Color(0xFFEF4444)},
    ];

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: palette.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'PROFILE PICTURE & CREST STUDIO',
                    style: TextStyle(
                      color: palette.accent,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Choose an ELEESA Circuit Badge or Photo URL',
                    style: TextStyle(
                      color: palette.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final item in presets)
                        GestureDetector(
                          onTap: () {
                            setModalState(() {
                              selectedPreset = item['id'] as String;
                              urlController.clear();
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: selectedPreset == item['id'] &&
                                      urlController.text.isEmpty
                                  ? (item['color'] as Color).withValues(alpha: 0.2)
                                  : palette.canvas,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: selectedPreset == item['id'] &&
                                        urlController.text.isEmpty
                                    ? (item['color'] as Color)
                                    : palette.border,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircleAvatar(
                                  radius: 8,
                                  backgroundColor: item['color'] as Color,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  item['label'] as String,
                                  style: TextStyle(
                                    color: palette.textPrimary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: urlController,
                    style: TextStyle(color: palette.textPrimary, fontSize: 13),
                    decoration: InputDecoration(
                      labelText: 'Or paste direct Photo URL (https://...)',
                      labelStyle: TextStyle(color: palette.textSecondary),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: palette.border),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: palette.accent),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: saving
                        ? null
                        : () async {
                            setModalState(() => saving = true);
                            final chosen = urlController.text.trim().isNotEmpty
                                ? urlController.text.trim()
                                : selectedPreset;
                            try {
                              final saved = await _profileService.uploadAvatar(
                                email: widget.email,
                                avatarData: chosen,
                              );
                              if (mounted) {
                                setState(() => _avatarData = saved);
                              }
                              if (ctx.mounted) Navigator.pop(ctx);
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      e.toString().replaceFirst('Exception: ', ''),
                                    ),
                                  ),
                                );
                              }
                            } finally {
                              if (ctx.mounted) {
                                setModalState(() => saving = false);
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: palette.accent,
                      foregroundColor: const Color(0xFF061018),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      saving ? 'Syncing Avatar...' : 'Save Profile Picture',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAvatarWidget(String displayName, EleesaPalette p) {
    final initial =
        displayName.isNotEmpty ? displayName[0].toUpperCase() : 'E';

    if (_avatarData.startsWith('http://') ||
        _avatarData.startsWith('https://')) {
      return CircleAvatar(
        radius: 28,
        backgroundColor: p.accent,
        backgroundImage: NetworkImage(_avatarData),
      );
    }

    if (_avatarData.startsWith('data:image')) {
      try {
        final b64 = _avatarData.split(',').last;
        return CircleAvatar(
          radius: 28,
          backgroundColor: p.accent,
          backgroundImage: MemoryImage(base64Decode(b64)),
        );
      } catch (_) {}
    }

    Color ringColor = p.accent;
    if (_avatarData == 'preset:amber') ringColor = const Color(0xFFF59E0B);
    if (_avatarData == 'preset:emerald') ringColor = const Color(0xFF10B981);
    if (_avatarData == 'preset:cobalt') ringColor = const Color(0xFF3B82F6);
    if (_avatarData == 'preset:violet') ringColor = const Color(0xFF8B5CF6);
    if (_avatarData == 'preset:crimson') ringColor = const Color(0xFFEF4444);

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ringColor.withValues(alpha: 0.18),
        border: Border.all(color: ringColor, width: 2.2),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          color: ringColor,
          fontWeight: FontWeight.bold,
          fontSize: 22,
        ),
      ),
    );
  }

  String _val(dynamic raw) {
    final s = (raw ?? '').toString().trim();
    return s.isEmpty ? 'Not set' : s;
  }

  String _sensitiveVal(dynamic raw) {
    final s = (raw ?? '').toString().trim();
    if (s.isEmpty) return 'Not set';
    return _revealSensitive ? s : '\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: eleesaTheme,
      builder: (context, _) {
        final palette = eleesaTheme.paletteForRole(widget.roleKey);
        final p = _profile ?? {};
        final isStudent =
            widget.roleKey == 'student' || widget.roleKey == 'executive';
        final displayName = _val(p['full_name'] ?? widget.fullName);

        final bodyContent = _loading
            ? Center(child: CircularProgressIndicator(color: palette.accent))
            : RefreshIndicator(
                onRefresh: _loadProfile,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: palette.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: palette.border),
                      ),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => _openAvatarStudio(palette),
                            child: _buildAvatarWidget(displayName, palette),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayName,
                                  style: TextStyle(
                                    color: palette.textPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'AES-256-GCM VAULT \u2022 ${widget.roleKey.toUpperCase()}',
                                  style: TextStyle(
                                    color: palette.accent,
                                    fontSize: 11,
                                    letterSpacing: 0.9,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                GestureDetector(
                                  onTap: () => _openAvatarStudio(palette),
                                  child: Text(
                                    'Change Profile Photo / Badge',
                                    style: TextStyle(
                                      color: palette.accent,
                                      fontSize: 12,
                                      decoration: TextDecoration.underline,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () => setState(
                              () => _revealSensitive = !_revealSensitive,
                            ),
                            child: Text(
                              _revealSensitive ? 'Hide PII' : 'Reveal PII',
                              style: TextStyle(
                                color: palette.accent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _tile(palette, 'Full Name', displayName),
                    _tile(palette, 'Email Address', widget.email),
                    if (isStudent) ...[
                      _tile(
                        palette,
                        'Student Index Number',
                        _val(p['index_number']),
                      ),
                      _tile(
                        palette,
                        'Academic Level',
                        p['level'] != null && p['level'].toString().isNotEmpty
                            ? 'Level ${p['level']}'
                            : 'Level Not set',
                      ),
                      _tile(
                        palette,
                        'Specialization',
                        _val(p['specialization']),
                      ),
                      _tile(palette, 'Gender', _val(p['gender'])),
                      _tile(
                        palette,
                        'Date of Birth (Encrypted)',
                        _sensitiveVal(p['dob']),
                      ),
                      _tile(
                        palette,
                        'Phone Number (Encrypted)',
                        _sensitiveVal(p['phone']),
                      ),
                      _tile(
                        palette,
                        'Hostel / Residence (Encrypted)',
                        _sensitiveVal(p['hostel']),
                      ),
                      _tile(
                        palette,
                        'Guardian Emergency Contact (Encrypted)',
                        _sensitiveVal(p['emergency_contact']),
                      ),
                    ] else ...[
                      _tile(palette, 'Staff ID', _val(p['staff_id'])),
                      _tile(
                        palette,
                        'Academic Title',
                        _val(p['academic_title']),
                      ),
                      _tile(
                        palette,
                        'Specialization',
                        _val(p['specialization']),
                      ),
                      _tile(palette, 'Office Hours', _val(p['office_hours'])),
                      _tile(palette, 'Gender', _val(p['gender'])),
                      _tile(
                        palette,
                        'Date of Birth (Encrypted)',
                        _sensitiveVal(p['dob']),
                      ),
                      _tile(
                        palette,
                        'Phone Number (Encrypted)',
                        _sensitiveVal(p['phone']),
                      ),
                      _tile(
                        palette,
                        'Office Line (Encrypted)',
                        _sensitiveVal(p['office_line']),
                      ),
                    ],
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _editProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: palette.accent,
                        foregroundColor: const Color(0xFF061018),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Edit Encrypted Profile',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );

        if (widget.embedded) {
          return Container(color: palette.canvas, child: bodyContent);
        }

        return Scaffold(
          backgroundColor: palette.canvas,
          appBar: AppBar(
            title: const Text('Encrypted Profile Vault'),
            backgroundColor: palette.surface,
            foregroundColor: palette.textPrimary,
            actions: [
              TextButton(
                onPressed: () =>
                    setState(() => _revealSensitive = !_revealSensitive),
                child: Text(
                  _revealSensitive ? 'Hide PII' : 'Reveal PII',
                  style: TextStyle(
                    color: palette.accent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          body: bodyContent,
        );
      },
    );
  }

  Widget _tile(EleesaPalette palette, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: TextStyle(
                color: palette.textSecondary,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: palette.textPrimary,
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}