import 'package:flutter/material.dart';
import '../services/profile_service.dart';
import 'electric_ui.dart';

Future<bool?> showProfileOnboardingPopup({
  required BuildContext context,
  required String email,
  required String initialFullName,
  required String roleKey, // 'student', 'lecturer', 'hod_admin', 'executive'
  Map<String, dynamic>? existingProfile,
  bool isMandatory = false,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: !isMandatory,
    builder: (_) => _ProfileOnboardingDialog(
      email: email,
      initialFullName: initialFullName,
      roleKey: roleKey,
      existingProfile: existingProfile,
      isMandatory: isMandatory,
    ),
  );
}

class _ProfileOnboardingDialog extends StatefulWidget {
  final String email;
  final String initialFullName;
  final String roleKey;
  final Map<String, dynamic>? existingProfile;
  final bool isMandatory;

  const _ProfileOnboardingDialog({
    required this.email,
    required this.initialFullName,
    required this.roleKey,
    this.existingProfile,
    required this.isMandatory,
  });

  @override
  State<_ProfileOnboardingDialog> createState() =>
      _ProfileOnboardingDialogState();
}

class _ProfileOnboardingDialogState extends State<_ProfileOnboardingDialog> {
  final _formKey = GlobalKey<FormState>();
  final _profileService = ProfileService();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _dobCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _idCtrl;
  late final TextEditingController _specCtrl;
  late final TextEditingController _emergencyOrOfficeLineCtrl;
  late final TextEditingController _hostelOrOfficeHoursCtrl;

  String _selectedLevel = '100';
  String _selectedGender = 'Male';
  String _selectedAcademicTitle = 'Lecturer';
  bool _isSaving = false;
  String? _serverStatus;

  bool get _isStudent =>
      widget.roleKey == 'student' || widget.roleKey == 'executive';
  bool get _isHod =>
      widget.roleKey == 'hod_admin' || widget.roleKey == 'hodAdmin';

  @override
  void initState() {
    super.initState();
    final p = widget.existingProfile ?? {};
    _nameCtrl = TextEditingController(
      text: (p['full_name'] ?? widget.initialFullName).toString(),
    );
    _dobCtrl = TextEditingController(text: (p['dob'] ?? '').toString());
    _phoneCtrl = TextEditingController(text: (p['phone'] ?? '').toString());
    _idCtrl = TextEditingController(
      text: (p['index_number'] ?? p['staff_id'] ?? '').toString(),
    );
    _specCtrl = TextEditingController(
      text: (p['specialization'] ??
              (_isStudent
                  ? 'Power Systems & Electrical Machines'
                  : 'Electrical & Electronic Engineering'))
          .toString(),
    );
    _emergencyOrOfficeLineCtrl = TextEditingController(
      text: (p['emergency_contact'] ?? p['office_line'] ?? '').toString(),
    );
    _hostelOrOfficeHoursCtrl = TextEditingController(
      text: (p['hostel'] ?? p['office_hours'] ?? '').toString(),
    );

    if (p['level'] != null && ['100', '200', '300', '400'].contains(p['level'])) {
      _selectedLevel = p['level'].toString();
    }
    if (p['gender'] != null && p['gender'].toString().isNotEmpty) {
      _selectedGender = p['gender'].toString();
    }
    if (p['academic_title'] != null && p['academic_title'].toString().isNotEmpty) {
      _selectedAcademicTitle = p['academic_title'].toString();
    } else if (_isHod) {
      _selectedAcademicTitle = 'Head of Department (EEE)';
    }
  }

  Future<void> _pickDateOfBirth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2004, 1, 1),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      final formatted =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      setState(() => _dobCtrl.text = formatted);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSaving = true;
      _serverStatus = null;
    });

    try {
      final payload = <String, dynamic>{
        'email': widget.email,
        'full_name': _nameCtrl.text.trim(),
        'gender': _selectedGender,
        'dob': _dobCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'index_or_staff_id': _idCtrl.text.trim(),
        'specialization': _specCtrl.text.trim(),
        if (_isStudent) ...{
          'level': _selectedLevel,
          'emergency_contact': _emergencyOrOfficeLineCtrl.text.trim(),
          'hostel': _hostelOrOfficeHoursCtrl.text.trim(),
        } else ...{
          'academic_title': _selectedAcademicTitle,
          'office_line': _emergencyOrOfficeLineCtrl.text.trim(),
          'office_hours': _hostelOrOfficeHoursCtrl.text.trim(),
        },
      };

      final msg = await _profileService.saveProfile(
        payload: payload,
        onStatusChange: (s) {
          if (mounted) setState(() => _serverStatus = s);
        },
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.green.shade700),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _serverStatus = null;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _dobCtrl.dispose();
    _phoneCtrl.dispose();
    _idCtrl.dispose();
    _specCtrl.dispose();
    _emergencyOrOfficeLineCtrl.dispose();
    _hostelOrOfficeHoursCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final headerTitle = _isStudent
        ? 'Student Grid Registration'
        : (_isHod ? 'HoD Command Profile' : 'Faculty Busbar Registration');

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460, maxHeight: 680),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                color: EleesaColors.deepNavy,
                borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
              ),
              child: Row(
                children: [
                  const ElectricPulseBadge(size: 46, isActive: true),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          headerTitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'AES-256-GCM Encrypted Personal Vault',
                          style: TextStyle(
                            color: EleesaColors.electricCyan,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!widget.isMandatory)
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.pop(context, false),
                    ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_isStudent) ...[
                        const Text(
                          'Select Academic Level (Routes to Level Table)',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: EleesaColors.deepNavy,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: ['100', '200', '300', '400'].map((lvl) {
                            final selected = _selectedLevel == lvl;
                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 3),
                                child: ChoiceChip(
                                  label: Text('Lvl $lvl'),
                                  selected: selected,
                                  selectedColor: EleesaColors.deepNavy,
                                  labelStyle: TextStyle(
                                    color: selected
                                        ? EleesaColors.electricCyan
                                        : Colors.black87,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                  onSelected: _isSaving
                                      ? null
                                      : (_) => setState(() => _selectedLevel = lvl),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 14),
                      ],
                      TextFormField(
                        controller: _nameCtrl,
                        decoration: InputDecoration(
                          labelText: 'Full Name',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _idCtrl,
                        decoration: InputDecoration(
                          labelText: _isStudent ? 'Student Index Number' : 'Staff ID',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _selectedGender,
                              decoration: InputDecoration(
                                labelText: 'Gender',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              items: ['Male', 'Female']
                                  .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                                  .toList(),
                              onChanged: (v) {
                                if (v != null) setState(() => _selectedGender = v);
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: _dobCtrl,
                              readOnly: true,
                              onTap: _pickDateOfBirth,
                              decoration: InputDecoration(
                                labelText: 'Date of Birth 🔒',
                                hintText: 'YYYY-MM-DD',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (v) =>
                                  (v == null || v.trim().isEmpty) ? 'Select DoB' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'Personal Phone Number 🔒',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().length < 7) ? 'Enter phone' : null,
                      ),
                      const SizedBox(height: 12),
                      if (!_isStudent) ...[
                        DropdownButtonFormField<String>(
                          initialValue: _selectedAcademicTitle,
                          decoration: InputDecoration(
                            labelText: 'Academic / Administrative Rank',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          items: [
                            'Head of Department (EEE)',
                            'Professor',
                            'Associate Professor',
                            'Senior Lecturer',
                            'Lecturer',
                            'Assistant Lecturer',
                          ]
                              .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                              .toList(),
                          onChanged: (v) {
                            if (v != null) {
                              setState(() => _selectedAcademicTitle = v);
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                      ],
                      TextFormField(
                        controller: _specCtrl,
                        decoration: InputDecoration(
                          labelText: _isStudent
                              ? 'EEE Specialization Track'
                              : 'Research Lab / Specialization',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _hostelOrOfficeHoursCtrl,
                        decoration: InputDecoration(
                          labelText: _isStudent
                              ? 'Hostel / Hall of Residence 🔒'
                              : 'Office Room & Consultation Hours',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _emergencyOrOfficeLineCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: _isStudent
                              ? 'Guardian Emergency Contact 🔒'
                              : 'Office / Emergency Line 🔒',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      ColdStartStatusBanner(statusMessage: _serverStatus),
                      const SizedBox(height: 18),
                      FilledButton(
                        onPressed: _isSaving ? null : _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: EleesaColors.deepNavy,
                          foregroundColor: EleesaColors.electricCyan,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: EleesaColors.electricCyan,
                                ),
                              )
                            : Text(
                                _isStudent
                                    ? 'Encrypt & Save to Level $_selectedLevel Table'
                                    : 'Encrypt & Save Staff Profile',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}