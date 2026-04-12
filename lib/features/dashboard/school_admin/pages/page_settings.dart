// ==========================================
// File: lib/features/dashboard/school_admin/pages/page_settings.dart
// ==========================================
import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smartedu/core/providers/school_admin_provider.dart';
import 'package:smartedu/utils/grading_utils.dart';

class PageSettings extends StatefulWidget {
  final String schoolName;
  final String schoolAddress;
  final String schoolPhone;
  final String schoolEmail;
  final void Function(String, String, String, String) onUpdate;

  const PageSettings({
    super.key,
    required this.schoolName,
    required this.schoolAddress,
    required this.schoolPhone,
    required this.schoolEmail,
    required this.onUpdate,
  });

  @override
  State<PageSettings> createState() => _PageSettingsState();
}

class _PageSettingsState extends State<PageSettings>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isSaving = false;

  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _mottoController;
  late TextEditingController _principalController;

  String _gradingTier = 'SSS';
  String _assessmentTier = 'SSS';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _nameController = TextEditingController(text: widget.schoolName);
    _addressController = TextEditingController(text: widget.schoolAddress);
    _phoneController = TextEditingController(text: widget.schoolPhone);
    _emailController = TextEditingController(text: widget.schoolEmail);
    _mottoController = TextEditingController();
    _principalController = TextEditingController();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _mottoController.dispose();
    _principalController.dispose();
    super.dispose();
  }

  void _initBrandingControllers(SchoolAdminProvider provider) {
    if (_mottoController.text.isEmpty) {
      _mottoController.text = provider.schoolMotto;
    }
    if (_principalController.text.isEmpty) {
      _principalController.text = provider.principalName;
    }
  }

  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();
    final address = _addressController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();

    if (name.isEmpty || address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('School name and address are required'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    final provider = context.read<SchoolAdminProvider>();
    final success =
        await provider.updateSchoolSettings(name, address, phone, email);
    setState(() => _isSaving = false);

    if (mounted) {
      widget.onUpdate(name, address, phone, email);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Profile updated!' : 'Failed to update'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _saveBranding() async {
    final provider = context.read<SchoolAdminProvider>();
    setState(() => _isSaving = true);
    final success = await provider.updateSchoolBranding(
      motto: _mottoController.text.trim(),
      principalName: _principalController.text.trim(),
    );
    setState(() => _isSaving = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Branding updated!' : 'Failed to update'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SchoolAdminProvider>();
    _initBrandingControllers(provider);

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: const Color(0xFF1A237E),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFF1A237E),
            indicatorSize: TabBarIndicatorSize.label,
            indicatorWeight: 3,
            isScrollable: true,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            tabs: const [
              Tab(text: 'Profile'),
              Tab(text: 'Branding'),
              Tab(text: 'Grading'),
              Tab(text: 'Assessment'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildProfileTab(provider),
              _buildBrandingTab(provider),
              _buildGradingTab(provider),
              _buildAssessmentTab(provider),
            ],
          ),
        ),
      ],
    );
  }

  // =========================================================
  // PROFILE TAB
  // =========================================================

  Widget _buildProfileTab(SchoolAdminProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "School Profile",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A237E),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "Basic information about your school",
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          Center(
            child: Column(
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: provider.schoolLogoUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            provider.schoolLogoUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _buildLogoPlaceholder(),
                          ),
                        )
                      : _buildLogoPlaceholder(),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => _pickAndUploadLogo(provider),
                  icon: const Icon(Icons.upload, size: 16),
                  label: const Text('Upload Logo'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1A237E),
                    side: const BorderSide(color: Color(0xFF1A237E)),
                  ),
                ),
                if (provider.schoolLogoUrl.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => _removeLogo(provider),
                    icon: const Icon(Icons.delete_outline,
                        size: 14, color: Colors.red),
                    label: const Text('Remove Logo',
                        style:
                            TextStyle(fontSize: 12, color: Colors.red)),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 32),
          _buildSectionTitle('School Information'),
          const SizedBox(height: 12),
          _buildTextField(_nameController, 'School Name', Icons.school),
          const SizedBox(height: 16),
          _buildTextField(
            _addressController,
            'Address / Location',
            Icons.location_on,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            _phoneController,
            'Phone / WhatsApp',
            Icons.phone,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            _emailController,
            'Email Address',
            Icons.email,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveProfile,
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.save_rounded),
              label: Text(
                _isSaving ? 'Saving...' : 'Save Profile',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A237E),
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.blue.shade300,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // BRANDING TAB
  // =========================================================

  Widget _buildBrandingTab(SchoolAdminProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "School Branding",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A237E),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "These appear on printed result sheets and documents",
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Examination Template'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: GradingUtils.availableTemplates.map((template) {
              final isSelected = provider.examTemplate == template;
              return _ExamTemplateCard(
                title: template,
                subtitle: GradingUtils.getTemplateLabel(template),
                icon: _getTemplateIcon(template),
                isSelected: isSelected,
                onTap: () async {
                  setState(() => _isSaving = true);
                  await provider.updateSchoolBranding(examTemplate: template);
                  setState(() => _isSaving = false);
                },
                compact: true,
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
          _buildSectionTitle('School Motto'),
          const SizedBox(height: 12),
          _buildTextField(
            _mottoController,
            'Enter school motto',
            Icons.format_quote,
            maxLength: 100,
          ),
          const SizedBox(height: 8),
          Text(
            'Prints below school name on result sheets',
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Principal Name'),
          const SizedBox(height: 12),
          _buildTextField(
            _principalController,
            'Enter principal\'s full name',
            Icons.person,
          ),
          const SizedBox(height: 8),
          Text(
            'Prints on the signature block of result sheets',
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
          const SizedBox(height: 32),
          _buildSectionTitle('Display Options'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Show Student Position'),
                  subtitle: const Text(
                      'Display position in class on result sheets'),
                  value: provider.schoolSettings?['show_position'] ?? true,
                  activeColor: const Color(0xFF1A237E),
                  contentPadding: EdgeInsets.zero,
                  onChanged: (val) =>
                      provider.updateSchoolBranding(showPosition: val),
                ),
                const Divider(),
                SwitchListTile(
                  title: const Text('Show Grade Only'),
                  subtitle: const Text(
                      'Hide individual scores, show only grade'),
                  value: provider.schoolSettings?['show_grade_only'] ?? false,
                  activeColor: const Color(0xFF1A237E),
                  contentPadding: EdgeInsets.zero,
                  onChanged: (val) async {
                    await provider.updateSchoolBranding(showGradeOnly: val);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveBranding,
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.save_rounded),
              label: Text(
                _isSaving ? 'Saving...' : 'Save Branding',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A237E),
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.blue.shade300,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // GRADING TAB — TIER AWARE
  // =========================================================

  static const _tiers = ['SSS', 'JSS', 'PRIMARY'];

  static const _tierLabels = {
    'SSS': 'Senior Secondary (WAEC)',
    'JSS': 'Junior Secondary (BECE)',
    'PRIMARY': 'Primary School (5-point)',
  };

  static const _tierColors = {
    'SSS': Color(0xFF1A237E),
    'JSS': Color(0xFFE65100),
    'PRIMARY': Color(0xFF2E7D32),
  };

  Widget _buildTierSelector(String selectedTier, void Function(String) onChanged) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: _tiers.map((tier) {
          final selected = selectedTier == tier;
          final color = _tierColors[tier]!;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(tier),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? color : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: selected
                      ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 2))]
                      : null,
                ),
                child: Text(
                  tier,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    color: selected ? Colors.white : const Color(0xFF555555),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGradingTab(SchoolAdminProvider provider) {
    final tier = _gradingTier;
    final gradingSystem = provider.getEffectiveGradingForTier(tier);
    final hasOverride = provider.hasTierGradingOverride(tier);
    final gradingErrors = gradingSystem.isNotEmpty
        ? GradingUtils.validateGradingSystem(gradingSystem)
        : <String>[];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Grading System",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A237E),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _tierLabels[tier] ?? '',
            style: TextStyle(fontSize: 13, color: _tierColors[tier]),
          ),
          const SizedBox(height: 16),

          _buildTierSelector(tier, (t) => setState(() => _gradingTier = t)),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: hasOverride ? Colors.blue.shade50 : Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: hasOverride ? Colors.blue.shade200 : Colors.green.shade200,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  hasOverride ? Icons.edit_note : Icons.check_circle_outline,
                  size: 18,
                  color: hasOverride ? Colors.blue : Colors.green,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    hasOverride
                        ? 'Using custom override for $tier'
                        : 'Using default grading for $tier',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: hasOverride ? Colors.blue.shade700 : Colors.green.shade700,
                    ),
                  ),
                ),
                if (hasOverride)
                  TextButton(
                    onPressed: () async {
                      final ok = await provider.resetTierToDefault(tier);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(ok ? 'Reset to default for $tier' : 'Failed to reset'),
                          backgroundColor: ok ? Colors.green : Colors.red,
                        ));
                      }
                    },
                    child: const Text('Reset', style: TextStyle(fontSize: 12, color: Colors.red)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () => _addGradingRow(provider, tier),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Grade'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A237E),
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              if (!hasOverride)
                OutlinedButton.icon(
                  onPressed: () async {
                    final defaults = GradingUtils.getDefaultGradingSystem(
                      tier == 'SSS' ? provider.examTemplate : (tier == 'JSS' ? 'BECE' : 'PRIMARY'),
                    );
                    final ok = await provider.updateTierGrading(tier, defaults);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(ok ? 'Default copied as custom override' : 'Failed'),
                        backgroundColor: ok ? Colors.green : Colors.red,
                      ));
                    }
                  },
                  icon: const Icon(Icons.content_copy, size: 16),
                  label: const Text('Copy Default as Override'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1A237E),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          if (gradingErrors.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.red, size: 18),
                      SizedBox(width: 8),
                      Text('Issues found', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.red)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...gradingErrors.take(3).map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(color: Colors.red)),
                        Expanded(child: Text(e, style: TextStyle(fontSize: 12, color: Colors.red.shade700))),
                      ],
                    ),
                  )),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          if (gradingSystem.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(60),
                child: Column(
                  children: [
                    Icon(Icons.grade_outlined, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text('No grading system for $tier', style: TextStyle(color: Colors.grey[700], fontSize: 15, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    Text('Click "Add Grade" or "Copy Default as Override"', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  ],
                ),
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Table(
                border: TableBorder(
                  horizontalInside: BorderSide(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(12),
                ),
                columnWidths: const {
                  0: FlexColumnWidth(1),
                  1: FlexColumnWidth(1),
                  2: FlexColumnWidth(1.2),
                  3: FlexColumnWidth(1.5),
                  4: FixedColumnWidth(60),
                },
                children: [
                  TableRow(
                    decoration: BoxDecoration(
                      color: _tierColors[tier]!.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    children: const [
                      _TableHeader('Min Score'),
                      _TableHeader('Max Score'),
                      _TableHeader('Grade'),
                      _TableHeader('Remark'),
                      _TableHeader(''),
                    ],
                  ),
                  ...gradingSystem.asMap().entries.map((entry) {
                    final i = entry.key;
                    final g = entry.value;
                    final min = (g['min'] as num?)?.toInt() ?? 0;
                    final max = (g['max'] as num?)?.toInt() ?? 0;
                    final isFail = !GradingUtils.isPassingGrade(
                        (g['grade'] ?? '').toString(), gradingSystem);
                    return TableRow(
                      decoration: isFail ? BoxDecoration(color: Colors.red.shade50) : null,
                      children: [
                        _TableCell('$min', alignment: TextAlign.center),
                        _TableCell('$max', alignment: TextAlign.center),
                        _TableCell(
                          (g['grade'] ?? '').toString(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isFail ? Colors.red : _tierColors[tier],
                          ),
                          alignment: TextAlign.center,
                        ),
                        _TableCell((g['remark'] ?? '').toString()),
                        _ActionCell(
                          onEdit: () => _editGradingRow(provider, tier, i, g),
                          onDelete: gradingSystem.length > 1
                              ? () => _deleteGradingRow(provider, tier, i)
                              : null,
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : () => _saveTierGrading(provider, tier),
              icon: _isSaving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.save_rounded),
              label: Text(
                _isSaving ? 'Saving...' : 'Save Grading for $tier',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _tierColors[tier]!,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // ASSESSMENT TAB — TIER AWARE
  // =========================================================

  Widget _buildAssessmentTab(SchoolAdminProvider provider) {
    final tier = _assessmentTier;
    final assessmentTypes = provider.getEffectiveAssessmentForTier(tier);
    final hasOverride = provider.hasTierAssessmentOverride(tier);
    final totalMax = assessmentTypes.fold<int>(0, (sum, at) => sum + ((at['max'] as num?)?.toInt() ?? 0));
    final assessmentValidation = GradingUtils.validateAssessmentTypes(assessmentTypes);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Assessment Types",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A237E),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Define how scores are broken down — ${_tierLabels[tier]}',
            style: TextStyle(fontSize: 13, color: _tierColors[tier]),
          ),
          const SizedBox(height: 16),

          _buildTierSelector(tier, (t) => setState(() => _assessmentTier = t)),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: hasOverride ? Colors.blue.shade50 : Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: hasOverride ? Colors.blue.shade200 : Colors.green.shade200,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  hasOverride ? Icons.edit_note : Icons.check_circle_outline,
                  size: 18,
                  color: hasOverride ? Colors.blue : Colors.green,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    hasOverride ? 'Using custom override for $tier' : 'Using default assessment for $tier',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: hasOverride ? Colors.blue.shade700 : Colors.green.shade700,
                    ),
                  ),
                ),
                if (hasOverride)
                  TextButton(
                    onPressed: () async {
                      final ok = await provider.resetTierToDefault(tier);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(ok ? 'Reset to default for $tier' : 'Failed to reset'),
                          backgroundColor: ok ? Colors.green : Colors.red,
                        ));
                      }
                    },
                    child: const Text('Reset', style: TextStyle(fontSize: 12, color: Colors.red)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () => _addAssessmentType(provider, tier),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Assessment'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A237E),
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              if (!hasOverride)
                OutlinedButton.icon(
                  onPressed: () async {
                    final defaults = GradingUtils.getDefaultAssessmentTypes(
                      tier == 'SSS' ? provider.examTemplate : (tier == 'JSS' ? 'BECE' : 'PRIMARY'),
                    );
                    final ok = await provider.updateTierAssessment(tier, defaults);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(ok ? 'Default copied as custom override' : 'Failed'),
                        backgroundColor: ok ? Colors.green : Colors.red,
                      ));
                    }
                  },
                  icon: const Icon(Icons.content_copy, size: 16),
                  label: const Text('Copy Default as Override'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1A237E),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          if (assessmentTypes.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: assessmentValidation['valid'] == true
                    ? Colors.green.shade50
                    : Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: assessmentValidation['valid'] == true
                      ? Colors.green.shade200
                      : Colors.red.shade200,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    assessmentValidation['valid'] == true ? Icons.check_circle : Icons.warning_amber_rounded,
                    color: assessmentValidation['valid'] == true ? Colors.green : Colors.red,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      assessmentValidation['valid'] == true
                          ? 'Total: $totalMax/100 — Valid'
                          : 'Total: $totalMax/100 — ${((assessmentValidation['errors'] as List).first).toString()}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: assessmentValidation['valid'] == true
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          if (assessmentTypes.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(60),
                child: Column(
                  children: [
                    Icon(Icons.tune_outlined, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text('No assessment types for $tier', style: TextStyle(color: Colors.grey[700], fontSize: 15, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    Text('Click "Add Assessment" or "Copy Default as Override"', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  ],
                ),
              ),
            )
          else
            ...assessmentTypes.asMap().entries.map((entry) {
              final i = entry.key;
              final at = entry.value;
              final name = (at['name'] ?? at['id'] ?? '').toString();
              final max = (at['max'] as num?)?.toInt() ?? 0;
              final percentage = totalMax > 0 ? ((max / totalMax) * 100).toStringAsFixed(0) : '0';
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _tierColors[tier]!.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          '$percentage%',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _tierColors[tier]),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _tierColors[tier])),
                          Text('Max: $max marks', style: const TextStyle(fontSize: 12, color: Color(0xFF555555))),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 100,
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: max / 100,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: AlwaysStoppedAnimation<Color>(_tierColors[tier]!),
                              minHeight: 6,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text('$max/100', style: const TextStyle(fontSize: 11, color: Color(0xFF555555))),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF1A237E)),
                      onPressed: () => _editAssessmentType(provider, tier, i, at),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: assessmentTypes.length > 1 ? Colors.red : Colors.grey.shade300,
                      ),
                      onPressed: assessmentTypes.length > 1
                          ? () => _deleteAssessmentType(provider, tier, i)
                          : null,
                    ),
                  ],
                ),
              );
            }),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : () => _saveTierAssessment(provider, tier),
              icon: _isSaving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.save_rounded),
              label: Text(
                _isSaving ? 'Saving...' : 'Save Assessment for $tier',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _tierColors[tier]!,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // LOGO UPLOAD
  // =========================================================

  Future<void> _pickAndUploadLogo(SchoolAdminProvider provider) async {
    try {
      final input = html.FileUploadInputElement()..accept = 'image/*';
      final changeFuture = input.onChange.first;
      input.click();

      final event = await changeFuture;
      debugPrint('File picker event fired');

      if (input.files == null || input.files!.isEmpty) {
        debugPrint('No file selected or picker cancelled');
        return;
      }

      final file = input.files!.first;
      debugPrint('File selected: ${file.name}, size: ${file.size} bytes');

      if (file.size > 2 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image too large. Max 2MB allowed.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                SizedBox(width: 12),
                Text('Uploading logo...'),
              ],
            ),
            duration: Duration(minutes: 5),
          ),
        );
      }

      final bytes = await _readFileBytes(file);
      if (bytes == null) {
        debugPrint('Failed to read file bytes');
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to read file'), backgroundColor: Colors.red),
          );
        }
        return;
      }

      debugPrint('File bytes read: ${bytes.length} bytes');
      await _uploadBytesToSupabase(provider, bytes, file.name);
    } catch (e) {
      debugPrint('Error in _pickAndUploadLogo: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<Uint8List?> _readFileBytes(html.File file) async {
    final completer = Completer<Uint8List?>();
    final reader = html.FileReader();
    reader.onLoadEnd.listen((_) {
      if (reader.result != null) {
        completer.complete((reader.result as ByteBuffer).asUint8List());
      } else {
        completer.complete(null);
      }
    });
    reader.onError.listen((_) {
      completer.completeError(Exception('FileReader error'));
    });
    reader.readAsArrayBuffer(file);
    return completer.future;
  }

  Future<void> _uploadBytesToSupabase(SchoolAdminProvider provider, Uint8List bytes, String fileName) async {
    try {
      final schoolId = provider.schoolId;
      debugPrint('School ID: $schoolId');
      if (schoolId.isEmpty) throw Exception('School ID not found. Cannot upload logo.');

      final ext = fileName.contains('.') ? fileName.split('.').last.toLowerCase() : 'png';
      final allowedExts = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
      if (!allowedExts.contains(ext)) throw Exception('Invalid file type. Use JPG, PNG, GIF, or WebP.');

      final storagePath = '$schoolId/logo.$ext';
      debugPrint('Uploading to: school-logos/$storagePath');

      await Supabase.instance.client.storage.from('school-logos').upload(
            storagePath,
            bytes,
            fileOptions: FileOptions(upsert: true, contentType: 'image/$ext'),
          );

      debugPrint('Upload succeeded');
      await provider.updateSchoolLogo(storagePath);
      debugPrint('Provider updated, logoUrl now: ${provider.schoolLogoUrl}');

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logo uploaded successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      debugPrint('Upload error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _removeLogo(SchoolAdminProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Logo?'),
        content: const Text('This will remove your school logo.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final schoolId = provider.schoolId;
      if (schoolId.isNotEmpty) {
        try {
          await Supabase.instance.client.storage.from('school-logos').remove(['$schoolId/logo']);
        } catch (_) {}
      }
      await provider.updateSchoolLogo('');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logo removed'), backgroundColor: Colors.orange),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error removing logo: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // =========================================================
  // TIER-AWARE GRADING ACTIONS
  // =========================================================

  Future<void> _addGradingRow(SchoolAdminProvider provider, String tier) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => const _GradingRowDialog(title: 'Add Grade'),
    );
    if (result == null) return;
    final updated = List<Map<String, dynamic>>.from(provider.getEffectiveGradingForTier(tier))..add(result);
    await provider.updateTierGrading(tier, updated);
  }

  Future<void> _editGradingRow(SchoolAdminProvider provider, String tier, int index, Map<String, dynamic> current) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => _GradingRowDialog(title: 'Edit Grade', initial: current),
    );
    if (result == null) return;
    final updated = List<Map<String, dynamic>>.from(provider.getEffectiveGradingForTier(tier))..[index] = result;
    await provider.updateTierGrading(tier, updated);
  }

  Future<void> _deleteGradingRow(SchoolAdminProvider provider, String tier, int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Grade?'),
        content: const Text('This will remove this grade.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final updated = List<Map<String, dynamic>>.from(provider.getEffectiveGradingForTier(tier))..removeAt(index);
    await provider.updateTierGrading(tier, updated);
  }

  Future<void> _saveTierGrading(SchoolAdminProvider provider, String tier) async {
    final current = provider.getEffectiveGradingForTier(tier);
    final errors = current.isNotEmpty ? GradingUtils.validateGradingSystem(current) : <String>[];
    if (errors.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Fix ${errors.length} error(s) before saving'),
        backgroundColor: Colors.red,
      ));
      return;
    }
    setState(() => _isSaving = true);
    final ok = await provider.updateTierGrading(tier, current);
    setState(() => _isSaving = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? 'Grading saved for $tier!' : 'Failed to save'),
        backgroundColor: ok ? Colors.green : Colors.red,
      ));
    }
  }

  // =========================================================
  // TIER-AWARE ASSESSMENT ACTIONS
  // =========================================================

  Future<void> _addAssessmentType(SchoolAdminProvider provider, String tier) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => const _AssessmentTypeDialog(title: 'Add Assessment'),
    );
    if (result == null) return;
    final updated = List<Map<String, dynamic>>.from(provider.getEffectiveAssessmentForTier(tier))..add(result);
    await provider.updateTierAssessment(tier, updated);
  }

  Future<void> _editAssessmentType(SchoolAdminProvider provider, String tier, int index, Map<String, dynamic> current) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => _AssessmentTypeDialog(title: 'Edit Assessment', initial: current),
    );
    if (result == null) return;
    final updated = List<Map<String, dynamic>>.from(provider.getEffectiveAssessmentForTier(tier))..[index] = result;
    await provider.updateTierAssessment(tier, updated);
  }

  Future<void> _deleteAssessmentType(SchoolAdminProvider provider, String tier, int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Assessment?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final updated = List<Map<String, dynamic>>.from(provider.getEffectiveAssessmentForTier(tier))..removeAt(index);
    await provider.updateTierAssessment(tier, updated);
  }

  Future<void> _saveTierAssessment(SchoolAdminProvider provider, String tier) async {
    final current = provider.getEffectiveAssessmentForTier(tier);
    final validation = GradingUtils.validateAssessmentTypes(current);
    if (validation['valid'] != true) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Fix errors before saving'),
        backgroundColor: Colors.red,
      ));
      return;
    }
    setState(() => _isSaving = true);
    final ok = await provider.updateTierAssessment(tier, current);
    setState(() => _isSaving = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? 'Assessment saved for $tier!' : 'Failed to save'),
        backgroundColor: ok ? Colors.green : Colors.red,
      ));
    }
  }

  // =========================================================
  // SHARED WIDGETS
  // =========================================================

  Widget _buildSectionTitle(String title) => Text(title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A237E)));

  Widget _buildTextField(TextEditingController controller, String label, IconData icon,
      {TextInputType? keyboardType, int? maxLength}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLength: maxLength,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF1A237E)),
        border: const OutlineInputBorder(),
        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF1A237E), width: 2)),
        counterText: '',
      ),
    );
  }

  Widget _buildLogoPlaceholder() => const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_photo_alternate_outlined, size: 40, color: Colors.grey),
          SizedBox(height: 4),
          Text('No Logo', style: TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      );

  IconData _getTemplateIcon(String template) {
    switch (template.toUpperCase()) {
      case 'WAEC': return Icons.school;
      case 'BECE': return Icons.menu_book;
      case 'NECO': return Icons.description;
      case 'IGCSE': return Icons.public;
      case 'PRIMARY': return Icons.child_care;
      case 'AMERICAN': return Icons.flag;
      default: return Icons.grade;
    }
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// SUB-WIDGETS
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _ExamTemplateCard extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final bool isSelected, compact;
  final VoidCallback onTap;

  const _ExamTemplateCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final width = compact ? 130.0 : (MediaQuery.of(context).size.width / 2 - 28);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: width,
        padding: EdgeInsets.all(compact ? 14 : 20),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1A237E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF1A237E) : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: const Color(0xFF1A237E).withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 4))]
              : null,
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(compact ? 10 : 12),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withOpacity(0.2) : const Color(0xFF1A237E).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: compact ? 24 : 32, color: isSelected ? Colors.white : const Color(0xFF1A237E)),
            ),
            SizedBox(height: compact ? 10 : 16),
            Text(title,
                style: TextStyle(fontSize: compact ? 14 : 18, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : const Color(0xFF1A237E))),
            const SizedBox(height: 2),
            Text(subtitle,
                style: TextStyle(fontSize: compact ? 10 : 12, color: isSelected ? Colors.white70 : Colors.grey),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

class _GradingRowDialog extends StatefulWidget {
  final String title;
  final Map<String, dynamic>? initial;

  const _GradingRowDialog({required this.title, this.initial});

  @override
  State<_GradingRowDialog> createState() => _GradingRowDialogState();
}

class _GradingRowDialogState extends State<_GradingRowDialog> {
  late TextEditingController _minC, _maxC, _gradeC, _remarkC;

  @override
  void initState() {
    super.initState();
    _minC = TextEditingController(text: (widget.initial?['min'] ?? '').toString());
    _maxC = TextEditingController(text: (widget.initial?['max'] ?? '').toString());
    _gradeC = TextEditingController(text: (widget.initial?['grade'] ?? '').toString());
    _remarkC = TextEditingController(text: (widget.initial?['remark'] ?? '').toString());
  }

  @override
  void dispose() {
    _minC.dispose();
    _maxC.dispose();
    _gradeC.dispose();
    _remarkC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _minC,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Min Score', border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _maxC,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Max Score', border: OutlineInputBorder()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _gradeC,
            decoration: const InputDecoration(labelText: 'Grade (e.g. A1)', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _remarkC,
            decoration: const InputDecoration(labelText: 'Remark (e.g. Excellent)', border: OutlineInputBorder()),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            final min = int.tryParse(_minC.text);
            final max = int.tryParse(_maxC.text);
            final grade = _gradeC.text.trim();
            final remark = _remarkC.text.trim();
            if (min == null || max == null || grade.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fill all required fields'), backgroundColor: Colors.red));
              return;
            }
            Navigator.pop(context, {'min': min, 'max': max, 'grade': grade, 'remark': remark});
          },
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E)),
          child: const Text('Save', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

class _AssessmentTypeDialog extends StatefulWidget {
  final String title;
  final Map<String, dynamic>? initial;

  const _AssessmentTypeDialog({required this.title, this.initial});

  @override
  State<_AssessmentTypeDialog> createState() => _AssessmentTypeDialogState();
}

class _AssessmentTypeDialogState extends State<_AssessmentTypeDialog> {
  late TextEditingController _nameC, _idC, _maxC;

  @override
  void initState() {
    super.initState();
    _nameC = TextEditingController(text: (widget.initial?['name'] ?? '').toString());
    _idC = TextEditingController(text: (widget.initial?['id'] ?? '').toString());
    _maxC = TextEditingController(text: (widget.initial?['max'] ?? '').toString());
  }

  @override
  void dispose() {
    _nameC.dispose();
    _idC.dispose();
    _maxC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameC,
            decoration: const InputDecoration(labelText: 'Name (e.g. CA1)', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _idC,
            decoration: const InputDecoration(labelText: 'ID (e.g. ca1)', border: OutlineInputBorder(), helperText: 'Lowercase, no spaces'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _maxC,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Maximum Score', border: OutlineInputBorder(), helperText: 'All should sum to 100'),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            final name = _nameC.text.trim();
            final id = _idC.text.trim().toLowerCase().replaceAll(' ', '_');
            final max = int.tryParse(_maxC.text);
            if (name.isEmpty || id.isEmpty || max == null) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fill all fields'), backgroundColor: Colors.red));
              return;
            }
            Navigator.pop(context, {'id': id, 'name': name, 'max': max});
          },
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E)),
          child: const Text('Save', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

class _TableHeader extends StatelessWidget {
  final String text;
  const _TableHeader(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(12),
        child: Text(text, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A237E), fontSize: 13)),
      );
}

class _TableCell extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign alignment;

  const _TableCell(this.text, {this.style, this.alignment = TextAlign.left});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(12),
        child: Text(text, style: style ?? const TextStyle(fontSize: 13, color: Color(0xFF1B2A4A)), textAlign: alignment),
      );
}

class _ActionCell extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback? onDelete;

  const _ActionCell({required this.onEdit, this.onDelete});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 16, color: Color(0xFF1A237E)),
              onPressed: onEdit,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              padding: EdgeInsets.zero,
            ),
            if (onDelete != null)
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                onPressed: onDelete,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                padding: EdgeInsets.zero,
              ),
          ],
        ),
      );
}
