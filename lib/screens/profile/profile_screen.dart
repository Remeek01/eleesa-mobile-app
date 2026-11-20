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
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _profileService.fetchProfile(widget.email);
      if (mounted) {
        setState(() {
          _profile = data['profile'] as Map<String, dynamic>?;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _mask(dynamic val) {
    final s = (val ?? '').toString();
    if (s.isEmpty) return 'Not set';
    return _revealSensitive ? s : '••••••••••••';
  }

  @override
  Widget build(BuildContext context) {
    final p = _profile ?? {};
    final isStudent =
        widget.roleKey == 'student' || widget.roleKey == 'executive';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Encrypted Profile Vault'),
        backgroundColor: EleesaColors.deepNavy,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: _revealSensitive ? 'Mask PII' : 'Reveal PII',
            icon: Icon(
              _revealSensitive ? Icons.visibility_off : Icons.visibility,
              color: EleesaColors.electricCyan,
            ),
            onPressed: () =>
                setState(() => _revealSensitive = !_revealSensitive),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                CircuitGridHeader(
                  title: (p['full_name'] ?? widget.fullName).toString(),
                  subtitle:
                      'Database Node: ${p['table_name'] ?? 'Pending Setup'}  •  AES-256-GCM',
                  isStepTwo: true,
                ),
                const SizedBox(height: 18),
                _tile('Email Address', widget.email),
                _tile(
                  isStudent ? 'Student Index Number' : 'Staff ID',
                  (p['index_number'] ?? p['staff_id'] ?? 'Not set').toString(),
                ),
                if (isStudent)
                  _tile('Academic Level', 'Level ${p['level'] ?? 'Not set'}'),
                if (!isStudent)
                  _tile('Academic Title', (p['academic_title'] ?? 'Not set').toString()),
                _tile('Specialization', (p['specialization'] ?? 'Not set').toString()),
                _tile('Gender', (p['gender'] ?? 'Not set').toString()),
                _tile('Date of Birth (Encrypted)', _mask(p['dob'])),
                _tile('Phone Number (Encrypted)', _mask(p['phone'])),
                _tile(
                  isStudent
                      ? 'Hostel / Residence (Encrypted)'
                      : 'Office & Hours',
                  isStudent
                      ? _mask(p['hostel'])
                      : (p['office_hours'] ?? 'Not set').toString(),
                ),
                _tile(
                  isStudent
                      ? 'Guardian Emergency Contact (Encrypted)'
                      : 'Office Direct Line (Encrypted)',
                  _mask(isStudent ? p['emergency_contact'] : p['office_line']),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () async {
                    final saved = await showProfileOnboardingPopup(
                      context: context,
                      email: widget.email,
                      initialFullName:
                          (p['full_name'] ?? widget.fullName).toString(),
                      roleKey: widget.roleKey,
                      existingProfile: _profile,
                      isMandatory: false,
                    );
                    if (saved == true) _load();
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: EleesaColors.deepNavy,
                    foregroundColor: EleesaColors.electricCyan,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text(
                    'Edit Personal Details',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          Flexible(
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