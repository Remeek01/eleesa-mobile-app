import 'package:flutter/material.dart';
import '../../services/profile_service.dart';
import '../../widgets/electric_ui.dart';
import '../../widgets/profile_onboarding_dialog.dart';

class ProfileScreen extends StatefulWidget {
  final String email;
  final String fullName;
  final String roleKey;

  const ProfileScreen({
    super.key,
    required this.email,
    required this.fullName,
    required this.roleKey,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _profileService = ProfileService();
  Map<String, dynamic>? _profile;
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
      if (mounted) {
        setState(() {
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

  String _val(dynamic raw) {
    final s = (raw ?? '').toString().trim();
    return s.isEmpty ? 'Not set' : s;
  }

  String _sensitiveVal(dynamic raw) {
    final s = (raw ?? '').toString().trim();
    if (s.isEmpty) return 'Not set';
    return _revealSensitive ? s : '••••••••••';
  }

  @override
  Widget build(BuildContext context) {
    final p = _profile ?? {};
    final isStudent =
        widget.roleKey == 'student' || widget.roleKey == 'executive';
    final displayName = _val(p['full_name'] ?? widget.fullName);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Encrypted Profile Vault'),
        backgroundColor: EleesaColors.deepNavy,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: () =>
                setState(() => _revealSensitive = !_revealSensitive),
            child: Text(
              _revealSensitive ? 'Hide PII' : 'Reveal PII',
              style: const TextStyle(
                color: EleesaColors.electricCyan,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadProfile,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: EleesaColors.deepNavy,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: EleesaColors.electricCyan,
                          child: Text(
                            displayName.isNotEmpty
                                ? displayName[0].toUpperCase()
                                : 'E',
                            style: const TextStyle(
                              color: EleesaColors.deepNavy,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'AES-256-GCM Protected • ${widget.roleKey.toUpperCase()}',
                                style: const TextStyle(
                                  color: EleesaColors.electricCyan,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _tile('Full Name', displayName),
                  _tile('Email Address', widget.email),
                  if (isStudent) ...[
                    _tile('Student Index Number', _val(p['index_number'])),
                    _tile(
                      'Academic Level',
                      p['level'] != null && p['level'].toString().isNotEmpty
                          ? 'Level ${p['level']}'
                          : 'Level Not set',
                    ),
                    _tile('Specialization', _val(p['specialization'])),
                    _tile('Gender', _val(p['gender'])),
                    _tile('Date of Birth (Encrypted)', _sensitiveVal(p['dob'])),
                    _tile('Phone Number (Encrypted)', _sensitiveVal(p['phone'])),
                    _tile(
                      'Hostel / Residence (Encrypted)',
                      _sensitiveVal(p['hostel']),
                    ),
                    _tile(
                      'Guardian Emergency Contact (Encrypted)',
                      _sensitiveVal(p['emergency_contact']),
                    ),
                  ] else ...[
                    _tile('Staff ID', _val(p['staff_id'])),
                    _tile('Academic Title', _val(p['academic_title'])),
                    _tile('Specialization', _val(p['specialization'])),
                    _tile('Office Hours', _val(p['office_hours'])),
                    _tile('Gender', _val(p['gender'])),
                    _tile('Date of Birth (Encrypted)', _sensitiveVal(p['dob'])),
                    _tile('Phone Number (Encrypted)', _sensitiveVal(p['phone'])),
                    _tile(
                      'Office Line (Encrypted)',
                      _sensitiveVal(p['office_line']),
                    ),
                  ],
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _editProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: EleesaColors.deepNavy,
                      foregroundColor: EleesaColors.electricCyan,
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
            ),
    );
  }

  Widget _tile(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade700,
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
              style: const TextStyle(
                color: EleesaColors.deepNavy,
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