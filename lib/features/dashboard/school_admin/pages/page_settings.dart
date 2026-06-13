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
import '../widgets/change_password_section.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
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

  void _snack(String message, {bool success = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            success ? const Color(0xFF2E7D32) : const Color(0xFFD32F2F),
        behavior: SnackBarBehavior.floating,
        shape: const StadiumBorder(),
        margin: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
      ),
    );
  }

  Future<bool?> _showConfirmDialog({
    required String title,
    required String message,
    required String confirmLabel,
    Color confirmColor = Colors.red,
    IconData icon = Icons.warning_amber_rounded,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: confirmColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: confirmColor, size: 24),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827)),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Cancel',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: confirmColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(confirmLabel,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();
    final address = _addressController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    if (name.isEmpty || address.isEmpty) {
      _snack('School name and address are required', success: false);
      return;
    }
    setState(() => _isSaving = true);
    final provider = context.read<SchoolAdminProvider>();
    final success =
        await provider.updateSchoolSettings(name, address, phone, email);
    setState(() => _isSaving = false);
    if (mounted) {
      widget.onUpdate(name, address, phone, email);
      _snack(success ? 'Profile updated successfully!' : 'Failed to update');
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
      _snack(success ? 'Branding updated successfully!' : 'Failed to update');
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SchoolAdminProvider>();
    _initBrandingControllers(provider);
    return Container(
      color: const Color(0xFFF7F8FA),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(24, 0, 24, 0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE8EAED)),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF1A237E),
              unselectedLabelColor: Colors.grey.shade500,
              indicatorColor: const Color(0xFF1A237E),
              indicatorSize: TabBarIndicatorSize.label,
              indicatorWeight: 2.5,
              isScrollable: true,
              labelStyle: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 14),
              unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w500, fontSize: 14),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              tabAlignment: TabAlignment.start,
              tabs: const [
                Tab(text: 'Profile'),
                Tab(text: 'Branding'),
                Tab(text: 'Grading'),
                Tab(text: 'Assessment'),
                Tab(text: 'Behavioral'),
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
                _buildBehavioralTab(provider),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pageHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 13, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _sectionHeader({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    String? count,
  }) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 17, color: iconColor),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),
        if (count != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              count,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: iconColor,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _textField(TextEditingController controller, String label,
      IconData icon,
      {TextInputType? keyboardType, int? maxLength}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLength: maxLength,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(
          icon,
          size: 20,
          color: const Color(0xFF1A237E).withOpacity(0.7),
        ),
        labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF1A237E), width: 2),
        ),
        filled: true,
        fillColor: const Color(0xFFFAFBFC),
        counterText: '',
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _saveBtn({
    required String label,
    required bool loading,
    required VoidCallback? onTap,
    Color? bg,
  }) {
    final c = bg ?? const Color(0xFF1A237E);
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2))
            : const Icon(Icons.check_rounded, size: 20),
        label: Text(
          loading ? 'Saving...' : label,
          style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: c,
          foregroundColor: Colors.white,
          disabledBackgroundColor: c.withOpacity(0.5),
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _actionPill({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.4)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _toggleRow({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color activeColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: activeColor,
            inactiveTrackColor: Colors.grey.shade300,
          ),
        ],
      ),
    );
  }

  Widget _infoCallout(String text, {Color? accent}) {
    final c = accent ?? const Color(0xFF1A237E);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: c.withOpacity(0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded,
              size: 15, color: c.withOpacity(0.6)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 12, color: c.withOpacity(0.7)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _logoPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFF7F8FA),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.add_photo_alternate_outlined,
              size: 22, color: Color(0xFFBDBDBD)),
        ),
        const SizedBox(height: 6),
        Text(
          'No Logo',
          style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _tierSelector(String selected, void Function(String) changed) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: _tiers.map((tier) {
          final on = selected == tier;
          final c = _tierColors[tier]!;
          return Expanded(
            child: GestureDetector(
              onTap: () => changed(tier),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: on ? c : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: on
                      ? [
                          BoxShadow(
                              color: c.withOpacity(0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2))
                        ]
                      : null,
                ),
                child: Text(
                  tier,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: on ? FontWeight.w700 : FontWeight.w600,
                    color: on ? Colors.white : const Color(0xFF555555),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _standardCard({
    required String title,
    required String sub,
    required IconData icon,
    required bool on,
    required VoidCallback tap,
  }) {
    return GestureDetector(
      onTap: tap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: on ? const Color(0xFFF0F4FF) : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: on ? const Color(0xFF1A237E) : const Color(0xFFE8EAED),
            width: on ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: on
                      ? const Color(0xFF1A237E)
                      : Colors.grey.shade400,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: on
                        ? const Color(0xFF1A237E)
                        : const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              sub,
              style: TextStyle(
                fontSize: 11,
                color: on ? Colors.blue.shade400 : Colors.grey.shade400,
              ),
            ),
            if (on)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_rounded,
                        size: 14, color: Color(0xFF2E7D32)),
                    SizedBox(width: 4),
                    Text(
                      'Active',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(IconData icon, String title, String sub) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(60),
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFF7F8FA),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, size: 36, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 15,
                  fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              sub,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _rowActions({
    required VoidCallback onEdit,
    VoidCallback? onDelete,
  }) {
    return SizedBox(
      width: 68,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          InkWell(
            onTap: onEdit,
            borderRadius: BorderRadius.circular(6),
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                border: Border.all(
                    color: const Color(0xFF1A237E).withOpacity(0.3)),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.edit_outlined,
                  size: 14, color: Color(0xFF1A237E)),
            ),
          ),
          if (onDelete != null) ...[
            const SizedBox(width: 4),
            InkWell(
              onTap: onDelete,
              borderRadius: BorderRadius.circular(6),
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  border: Border.all(
                      color: Colors.red.shade400.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(Icons.delete_outline,
                    size: 14, color: Colors.red.shade400),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProfileTab(SchoolAdminProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _pageHeader('School Profile', 'Basic information about your school'),
          const SizedBox(height: 28),
          Center(
            child: Column(
              children: [
                Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F8FA),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: provider.schoolLogoUrl.isNotEmpty
                          ? const Color(0xFFE8EAED)
                          : Colors.grey.shade300,
                      width: 2,
                    ),
                    boxShadow: provider.schoolLogoUrl.isNotEmpty
                        ? [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 12,
                                offset: const Offset(0, 4))
                          ]
                        : null,
                  ),
                  child: provider.schoolLogoUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Image.network(
                            provider.schoolLogoUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _logoPlaceholder(),
                          ),
                        )
                      : _logoPlaceholder(),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _actionPill(
                      icon: Icons.cloud_upload_outlined,
                      label: 'Upload Logo',
                      color: const Color(0xFF1A237E),
                      onTap: () => _pickAndUploadLogo(provider),
                    ),
                    if (provider.schoolLogoUrl.isNotEmpty) ...[
                      const SizedBox(width: 10),
                      _actionPill(
                        icon: Icons.delete_outline,
                        label: 'Remove',
                        color: Colors.red.shade400,
                        onTap: () => _removeLogo(provider),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 36),
          _sectionHeader(
            icon: Icons.school_rounded,
            iconBg: const Color(0xFFF0F4FF),
            iconColor: const Color(0xFF1A237E),
            title: 'School Information',
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE8EAED)),
            ),
            child: Column(
              children: [
                _textField(_nameController, 'School Name',
                    Icons.business_rounded),
                const SizedBox(height: 16),
                _textField(_addressController, 'Address / Location',
                    Icons.location_on_rounded),
                const SizedBox(height: 16),
                _textField(_phoneController, 'Phone / WhatsApp',
                    Icons.phone_rounded,
                    keyboardType: TextInputType.phone),
                const SizedBox(height: 16),
                _textField(_emailController, 'Email Address',
                    Icons.email_rounded,
                    keyboardType: TextInputType.emailAddress),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _saveBtn(
            label: 'Save Profile',
            loading: _isSaving,
            onTap: _isSaving ? null : _saveProfile,
          ),
              const SizedBox(height: 24),
              ChangePasswordSection(
                title: 'Change Admin Password',
                subtitle: 'Update your login credentials',
                currentLabel: 'Current Password',
                newLabel: 'New Password',
                confirmLabel: 'Confirm New Password',
                onSubmit: (current, newPass) async {
                  final res = await Supabase.instance.client.rpc('change_admin_password', params: {'school_id_param': provider.schoolId, 'old_password': current, 'new_password': newPass});
                  return res as bool? ?? false;
                },
              ),
            ],
          ),
        );
      }

      Widget _buildBrandingTab(SchoolAdminProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _pageHeader('School Branding',
              'These appear on printed result sheets'),
          const SizedBox(height: 28),
          _sectionHeader(
            icon: Icons.format_quote_rounded,
            iconBg: const Color(0xFFF0F4FF),
            iconColor: const Color(0xFF1A237E),
            title: 'School Motto',
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE8EAED)),
            ),
            child: Column(
              children: [
                _textField(_mottoController, 'Enter school motto',
                    Icons.format_quote, maxLength: 100),
                const SizedBox(height: 10),
                _infoCallout('Prints below school name on result sheets'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _sectionHeader(
            icon: Icons.person_rounded,
            iconBg: const Color(0xFFF0FFF4),
            iconColor: const Color(0xFF2E7D32),
            title: 'Principal Name',
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE8EAED)),
            ),
            child: Column(
              children: [
                _textField(
                    _principalController,
                    "Enter principal's full name",
                    Icons.person_outline_rounded),
                const SizedBox(height: 10),
                _infoCallout(
                    'Prints on the signature block of result sheets',
                    accent: const Color(0xFF2E7D32)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _sectionHeader(
            icon: Icons.tune_rounded,
            iconBg: const Color(0xFFFFF8E1),
            iconColor: const Color(0xFFF57F17),
            title: 'Display Options',
          ),
          const SizedBox(height: 12),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE8EAED)),
            ),
            child: Column(
              children: [
                _toggleRow(
                  title: 'Show Student Position',
                  subtitle: 'Display position in class on result sheets',
                  value: provider.schoolSettings?['show_position'] ?? true,
                  activeColor: const Color(0xFF1A237E),
                  onChanged: (v) =>
                      provider.updateSchoolBranding(showPosition: v),
                ),
                Divider(color: Colors.grey.shade200, height: 24),
                _toggleRow(
                  title: 'Show Grade Only',
                  subtitle: 'Hide individual scores, show only grade',
                  value:
                      provider.schoolSettings?['show_grade_only'] ?? false,
                  activeColor: const Color(0xFF1A237E),
                  onChanged: (v) =>
                      provider.updateSchoolBranding(showGradeOnly: v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _saveBtn(
            label: 'Save Branding',
            loading: _isSaving,
            onTap: _isSaving ? null : _saveBranding,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildGradingTab(SchoolAdminProvider provider) {
    final tier = _gradingTier;
    final gs = provider.getEffectiveGradingForTier(tier);
    final hasOv = provider.hasTierGradingOverride(tier);
    final errs = gs.isNotEmpty
        ? GradingUtils.validateGradingSystem(gs)
        : <String>[];
    final isAm =
        (provider.schoolSettings?['grading_standard'] ?? 'Nigerian')
                .toString() ==
            'American';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _pageHeader('Grading System',
              'Configure grade boundaries and remarks'),
          const SizedBox(height: 6),
          Text(
            _tierLabels[tier] ?? '',
            style: TextStyle(fontSize: 13, color: _tierColors[tier]),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE8EAED)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionHeader(
                  icon: Icons.language_rounded,
                  iconBg: const Color(0xFFF0F4FF),
                  iconColor: const Color(0xFF1A237E),
                  title: 'Grading Standard',
                ),
                const SizedBox(height: 6),
                Text(
                  'Nigerian = tier-based grading. American = same GPA grades for all tiers.',
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _standardCard(
                        title: 'Nigerian',
                        sub: 'WAEC \u00B7 BECE \u00B7 Primary',
                        icon: Icons.flag_rounded,
                        on: !isAm,
                        tap: () async {
                          final ok = await provider
                              .updateGradingStandard('Nigerian');
                          if (mounted && ok) setState(() {});
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _standardCard(
                        title: 'American',
                        sub: 'GPA (A to F, 4.0 scale)',
                        icon: Icons.school_rounded,
                        on: isAm,
                        tap: () async {
                          final ok = await provider
                              .updateGradingStandard('American');
                          if (mounted && ok) setState(() {});
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _tierSelector(tier, (t) => setState(() => _gradingTier = t)),
          const SizedBox(height: 12),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: hasOv ? Colors.blue.shade50 : Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: hasOv
                    ? Colors.blue.shade200
                    : Colors.green.shade200,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  hasOv ? Icons.edit_note : Icons.check_circle_outline,
                  size: 18,
                  color: hasOv ? Colors.blue : Colors.green,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    hasOv
                        ? 'Using custom override for $tier'
                        : 'Using default grading for $tier',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: hasOv
                          ? Colors.blue.shade700
                          : Colors.green.shade700,
                    ),
                  ),
                ),
                if (hasOv)
                  TextButton(
                    onPressed: () async {
                      final ok =
                          await provider.resetTierToDefault(tier);
                      if (mounted) {
                        _snack(ok
                            ? 'Reset to default for $tier'
                            : 'Failed to reset');
                      }
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: const Text('Reset',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _actionPill(
                icon: Icons.add_rounded,
                label: 'Add Grade',
                color: const Color(0xFF1A237E),
                onTap: () => _addGradingRow(provider, tier),
              ),
              const SizedBox(width: 10),
              if (!hasOv)
                _actionPill(
                  icon: Icons.content_copy_rounded,
                  label: 'Copy Default as Override',
                  color: Colors.grey.shade600,
                  onTap: () async {
                    final d = GradingUtils.getDefaultGradingSystem(
                      tier == 'SSS'
                          ? provider.examTemplate
                          : (tier == 'JSS' ? 'BECE' : 'PRIMARY'),
                    );
                    final ok =
                        await provider.updateTierGrading(tier, d);
                    if (mounted) {
                      _snack(ok
                          ? 'Default copied as custom override'
                          : 'Failed to copy');
                    }
                  },
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (errs.isNotEmpty) ...[
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
                      Icon(Icons.warning_amber_rounded,
                          color: Colors.red, size: 18),
                      SizedBox(width: 8),
                      Text('Issues found',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.red)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  for (final e in errs.take(3))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('\u2022 ',
                              style: TextStyle(color: Colors.red)),
                          Expanded(
                            child: Text(e,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.red.shade700)),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (gs.isEmpty)
            _emptyState(Icons.grade_outlined, 'No grading system for $tier',
                'Click "Add Grade" or "Copy Default as Override"')
          else
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE8EAED)),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: _tierColors[tier]!.withOpacity(0.08),
                      ),
                      child: const Row(
                        children: [
                          Expanded(
                              child: Text('Min',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                      color: Color(0xFF1A237E)))),
                          Expanded(
                              child: Text('Max',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                      color: Color(0xFF1A237E)))),
                          Expanded(
                              child: Text('Grade',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                      color: Color(0xFF1A237E)))),
                          Expanded(
                              flex: 2,
                              child: Text('Remark',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                      color: Color(0xFF1A237E)))),
                          SizedBox(width: 68),
                        ],
                      ),
                    ),
                    for (int i = 0; i < gs.length; i++)
                      Builder(builder: (_) {
                        final g = gs[i];
                        final mn = (g['min'] as num?)?.toInt() ?? 0;
                        final mx = (g['max'] as num?)?.toInt() ?? 0;
                        final gr = (g['grade'] ?? '').toString();
                        final fail =
                            !GradingUtils.isPassingGrade(gr, gs);
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: i.isEven
                                ? Colors.white
                                : const Color(0xFFFAFBFC),
                            border: Border(
                              bottom: BorderSide(
                                  color: Colors.grey.shade100),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text('$mn',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF1B2A4A))),
                              ),
                              Expanded(
                                child: Text('$mx',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF1B2A4A))),
                              ),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: fail
                                        ? Colors.red.shade50
                                        : _tierColors[tier]!
                                            .withOpacity(0.1),
                                    borderRadius:
                                        BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    gr,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: fail
                                          ? Colors.red
                                          : _tierColors[tier],
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  (g['remark'] ?? '').toString(),
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF1B2A4A)),
                                ),
                              ),
                              _rowActions(
                                onEdit: () => _editGradingRow(
                                    provider, tier, i, g),
                                onDelete: gs.length > 1
                                    ? () => _deleteGradingRow(
                                        provider, tier, i)
                                    : null,
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 24),
          _saveBtn(
            label: 'Save Grading for $tier',
            loading: _isSaving,
            onTap: _isSaving
                ? null
                : () => _saveTierGrading(provider, tier),
            bg: _tierColors[tier],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildAssessmentTab(SchoolAdminProvider provider) {
    final tier = _assessmentTier;
    final ats = provider.getEffectiveAssessmentForTier(tier);
    final hasOv = provider.hasTierAssessmentOverride(tier);
    final total = ats.fold<int>(
        0, (s, a) => s + ((a['max'] as num?)?.toInt() ?? 0));
    final val = GradingUtils.validateAssessmentTypes(ats);
    final ok = val['valid'] == true;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _pageHeader('Assessment Types',
              'Define how scores are broken down'),
          const SizedBox(height: 6),
          Text(
            'Currently configuring: ${_tierLabels[tier]}',
            style: TextStyle(fontSize: 13, color: _tierColors[tier]),
          ),
          const SizedBox(height: 20),
          _tierSelector(
              tier, (t) => setState(() => _assessmentTier = t)),
          const SizedBox(height: 12),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: hasOv ? Colors.blue.shade50 : Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: hasOv
                    ? Colors.blue.shade200
                    : Colors.green.shade200,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  hasOv ? Icons.edit_note : Icons.check_circle_outline,
                  size: 18,
                  color: hasOv ? Colors.blue : Colors.green,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    hasOv
                        ? 'Using custom override for $tier'
                        : 'Using default assessment for $tier',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: hasOv
                          ? Colors.blue.shade700
                          : Colors.green.shade700,
                    ),
                  ),
                ),
                if (hasOv)
                  TextButton(
                    onPressed: () async {
                      final r =
                          await provider.resetTierToDefault(tier);
                      if (mounted) {
                        _snack(r
                            ? 'Reset to default for $tier'
                            : 'Failed to reset');
                      }
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: const Text('Reset',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _actionPill(
                icon: Icons.add_rounded,
                label: 'Add Assessment',
                color: const Color(0xFF1A237E),
                onTap: () => _addAssessmentType(provider, tier),
              ),
              const SizedBox(width: 10),
              if (!hasOv)
                _actionPill(
                  icon: Icons.content_copy_rounded,
                  label: 'Copy Default as Override',
                  color: Colors.grey.shade600,
                  onTap: () async {
                    final d = GradingUtils.getDefaultAssessmentTypes(
                      tier == 'SSS'
                          ? provider.examTemplate
                          : (tier == 'JSS' ? 'BECE' : 'PRIMARY'),
                    );
                    final r = await provider.updateTierAssessment(
                        tier, d);
                    if (mounted) {
                      _snack(r
                          ? 'Default copied as custom override'
                          : 'Failed to copy');
                    }
                  },
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (ats.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: ok ? Colors.green.shade50 : Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: ok
                      ? Colors.green.shade200
                      : Colors.red.shade200,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    ok
                        ? Icons.check_circle
                        : Icons.warning_amber_rounded,
                    color: ok ? Colors.green : Colors.red,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      ok
                          ? 'Total: $total/100 \u2014 Valid configuration'
                          : 'Total: $total/100 \u2014 ${((val['errors'] as List).first).toString()}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: ok
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          if (ats.isEmpty)
            _emptyState(
                Icons.tune_outlined,
                'No assessment types for $tier',
                'Click "Add Assessment" or "Copy Default as Override"')
          else
            for (int i = 0; i < ats.length; i++)
              Builder(builder: (_) {
                final at = ats[i];
                final nm =
                    (at['name'] ?? at['id'] ?? '').toString();
                final mx = (at['max'] as num?)?.toInt() ?? 0;
                final pct = total > 0
                    ? ((mx / total) * 100).toStringAsFixed(0)
                    : '0';
                return ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border:
                          Border.all(color: const Color(0xFFE8EAED)),
                    ),
                    child: Row(
                      children: [
                        Container(
                            width: 4, color: _tierColors[tier]),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: _tierColors[tier]!
                                        .withOpacity(0.1),
                                    borderRadius:
                                        BorderRadius.circular(10),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '$pct%',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: _tierColors[tier],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        nm,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF111827),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Max: $mx marks',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF9CA3AF),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  width: 90,
                                  child: Column(
                                    children: [
                                      ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(4),
                                        child:
                                            LinearProgressIndicator(
                                          value: mx / 100,
                                          backgroundColor:
                                              Colors.grey.shade100,
                                          valueColor:
                                              AlwaysStoppedAnimation(
                                                  _tierColors[tier]!),
                                          minHeight: 6,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '$mx/100',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF9CA3AF),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                _rowActions(
                                  onEdit: () => _editAssessmentType(
                                      provider, tier, i, at),
                                  onDelete: ats.length > 1
                                      ? () => _deleteAssessmentType(
                                          provider, tier, i)
                                      : null,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
          const SizedBox(height: 24),
          _saveBtn(
            label: 'Save Assessment for $tier',
            loading: _isSaving,
            onTap: _isSaving
                ? null
                : () => _saveTierAssessment(provider, tier),
            bg: _tierColors[tier],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<void> _pickAndUploadLogo(SchoolAdminProvider provider) async {
    try {
      final input = html.FileUploadInputElement()..accept = 'image/*';
      final changeFuture = input.onChange.first;
      input.click();
      await changeFuture;
      if (input.files == null || input.files!.isEmpty) return;
      final file = input.files!.first;
      if (file.size > 2 * 1024 * 1024) {
        _snack('Image too large. Max 2MB allowed.', success: false);
        return;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                ),
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
        _snack('Failed to read file', success: false);
        return;
      }
      await _uploadBytes(provider, bytes, file.name);
    } catch (e) {
      _snack('Error: $e', success: false);
    }
  }

  Future<Uint8List?> _readFileBytes(html.File file) async {
    final c = Completer<Uint8List?>();
    final r = html.FileReader();
    r.onLoadEnd.listen((_) {
      c.complete(r.result != null
          ? (r.result as ByteBuffer).asUint8List()
          : null);
    });
    r.onError.listen((_) {
      c.completeError(Exception('FileReader error'));
    });
    r.readAsArrayBuffer(file);
    return c.future;
  }

  Future<void> _uploadBytes(SchoolAdminProvider provider,
      Uint8List bytes, String name) async {
    try {
      final sid = provider.schoolId;
      if (sid.isEmpty) throw Exception('School ID not found.');
      final ext = name.contains('.')
          ? name.split('.').last.toLowerCase()
          : 'png';
      if (!['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext))
        throw Exception('Invalid file type.');
      final path = '$sid/logo.$ext';
      await Supabase.instance.client.storage
          .from('school-logos')
          .upload(path, bytes,
              fileOptions: FileOptions(
                  upsert: true, contentType: 'image/$ext'));
      await provider.updateSchoolLogo(path);
      _snack('Logo uploaded successfully!');
    } catch (e) {
      _snack('Upload failed: $e', success: false);
    }
  }

  Future<void> _removeLogo(SchoolAdminProvider provider) async {
    final ok = await _showConfirmDialog(
      title: 'Remove Logo?',
      message: 'This will remove your school logo from all documents.',
      confirmLabel: 'Remove',
      icon: Icons.delete_outline_rounded,
    );
    if (ok != true) return;
    try {
      final sid = provider.schoolId;
      if (sid.isNotEmpty) {
        try {
          await Supabase.instance.client.storage
              .from('school-logos')
              .remove(['$sid/logo']);
        } catch (_) {}
      }
      await provider.updateSchoolLogo('');
      _snack('Logo removed', success: false);
    } catch (e) {
      _snack('Error removing logo: $e', success: false);
    }
  }

  Future<void> _addGradingRow(SchoolAdminProvider p, String t) async {
    final r = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (c) => const _GradingDialog(title: 'Add Grade'),
    );
    if (r == null) return;
    final u = List<Map<String, dynamic>>.from(
        p.getEffectiveGradingForTier(t))
      ..add(r);
    await p.updateTierGrading(t, u);
  }

  Future<void> _editGradingRow(SchoolAdminProvider p, String t,
      int i, Map<String, dynamic> cur) async {
    final r = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (c) =>
          _GradingDialog(title: 'Edit Grade', initial: cur),
    );
    if (r == null) return;
    final u = List<Map<String, dynamic>>.from(
        p.getEffectiveGradingForTier(t))
      ..[i] = r;
    await p.updateTierGrading(t, u);
  }

  Future<void> _deleteGradingRow(
      SchoolAdminProvider p, String t, int i) async {
    final ok = await _showConfirmDialog(
      title: 'Delete Grade?',
      message: 'This will permanently remove this grade entry.',
      confirmLabel: 'Delete',
    );
    if (ok != true) return;
    final u = List<Map<String, dynamic>>.from(
        p.getEffectiveGradingForTier(t))
      ..removeAt(i);
    await p.updateTierGrading(t, u);
  }

  Future<void> _saveTierGrading(
      SchoolAdminProvider p, String t) async {
    final cur = p.getEffectiveGradingForTier(t);
    final errs = cur.isNotEmpty
        ? GradingUtils.validateGradingSystem(cur)
        : <String>[];
    if (errs.isNotEmpty) {
      _snack('Fix ${errs.length} error(s) before saving',
          success: false);
      return;
    }
    setState(() => _isSaving = true);
    final ok = await p.updateTierGrading(t, cur);
    setState(() => _isSaving = false);
    _snack(ok ? 'Grading saved for $t!' : 'Failed to save');
  }

  Future<void> _addAssessmentType(
      SchoolAdminProvider p, String t) async {
    final r = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (c) =>
          const _AssessDialog(title: 'Add Assessment'),
    );
    if (r == null) return;
    final u = List<Map<String, dynamic>>.from(
        p.getEffectiveAssessmentForTier(t))
      ..add(r);
    await p.updateTierAssessment(t, u);
  }

  Future<void> _editAssessmentType(SchoolAdminProvider p, String t,
      int i, Map<String, dynamic> cur) async {
    final r = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (c) => _AssessDialog(
          title: 'Edit Assessment', initial: cur),
    );
    if (r == null) return;
    final u = List<Map<String, dynamic>>.from(
        p.getEffectiveAssessmentForTier(t))
      ..[i] = r;
    await p.updateTierAssessment(t, u);
  }

  Future<void> _deleteAssessmentType(
      SchoolAdminProvider p, String t, int i) async {
    final ok = await _showConfirmDialog(
      title: 'Delete Assessment?',
      message:
          'This will permanently remove this assessment type.',
      confirmLabel: 'Delete',
    );
    if (ok != true) return;
    final u = List<Map<String, dynamic>>.from(
        p.getEffectiveAssessmentForTier(t))
      ..removeAt(i);
    await p.updateTierAssessment(t, u);
  }

  Future<void> _saveTierAssessment(
      SchoolAdminProvider p, String t) async {
    final cur = p.getEffectiveAssessmentForTier(t);
    final v = GradingUtils.validateAssessmentTypes(cur);
    if (v['valid'] != true) {
      _snack('Fix errors before saving', success: false);
      return;
    }
    setState(() => _isSaving = true);
    final ok = await p.updateTierAssessment(t, cur);
    setState(() => _isSaving = false);
    _snack(ok ? 'Assessment saved for $t!' : 'Failed to save');
  }

  Widget _buildBehavioralTab(SchoolAdminProvider provider) {
    final customLabels = provider.behavioralLabels;
    final allLabels = GradingUtils.getAllBehavioralLabels(customLabels: customLabels);
    final controllers = <String, TextEditingController>{};
    for (final item in allLabels) {
      controllers[item['key']!] = TextEditingController(text: item['label']);
    }
    bool isSaving = false;
    return StatefulBuilder(
      builder: (context, setInner) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _pageHeader('Behavioral Ratings', 'Customize the 11 rating labels on report sheets'),
              const SizedBox(height: 12),
              _infoCallout('Leave any field blank to use the Nigerian default. Your custom labels replace the defaults on all printed results.'),
              const SizedBox(height: 20),
              if (customLabels != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.edit_note, size: 18, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text('${customLabels.length} custom label${customLabels.length != 1 ? 's' : ''} active',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blue.shade700)),
                      ),
                      TextButton(
                        onPressed: () async {
                          final ok = await provider.updateBehavioralLabels({});
                          if (context.mounted) {
                            _snack(ok ? 'All labels reset to defaults' : 'Failed to reset');
                          }
                        },
                        style: TextButton.styleFrom(foregroundColor: Colors.red, padding: const EdgeInsets.symmetric(horizontal: 8)),
                        child: const Text('Reset All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE8EAED)),
                ),
                child: Column(
                  children: [
                    for (int i = 0; i < allLabels.length; i++) ...[
                      if (i > 0) Divider(color: Colors.grey.shade100, height: 1),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 28,
                              child: Text('${i + 1}.',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade500)),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: controllers[allLabels[i]['key']],
                                decoration: InputDecoration(
                                  labelText: 'Rating ${i + 1}',
                                  labelStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                                  hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade300),
                                  hintText: GradingUtils.behavioralFieldLabels[allLabels[i]['key']],
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade200)),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade200)),
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF1A237E), width: 2)),
                                  filled: true,
                                  fillColor: const Color(0xFFFAFBFC),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  isDense: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: isSaving ? null : () async {
                    setInner(() => isSaving = true);
                    final labels = <String, String>{};
                    for (final entry in controllers.entries) {
                      final val = entry.value.text.trim();
                      if (val.isNotEmpty) labels[entry.key] = val;
                    }
                    final ok = await provider.updateBehavioralLabels(labels);
                    setInner(() => isSaving = false);
                    if (context.mounted) {
                      _snack(ok ? 'Behavioral labels saved!' : 'Failed to save');
                    }
                  },
                  icon: isSaving
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.check_rounded, size: 20),
                  label: Text(isSaving ? 'Saving...' : 'Save Behavioral Labels',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A237E),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFF1A237E).withOpacity(0.5),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}

class _GradingDialog extends StatefulWidget {
  final String title;
  final Map<String, dynamic>? initial;
  const _GradingDialog({required this.title, this.initial});

  @override
  State<_GradingDialog> createState() => _GradingDialogState();
}

class _GradingDialogState extends State<_GradingDialog> {
  late TextEditingController _minC, _maxC, _gradeC, _remarkC;

  @override
  void initState() {
    super.initState();
    _minC = TextEditingController(
        text: (widget.initial?['min'] ?? '').toString());
    _maxC = TextEditingController(
        text: (widget.initial?['max'] ?? '').toString());
    _gradeC = TextEditingController(
        text: (widget.initial?['grade'] ?? '').toString());
    _remarkC = TextEditingController(
        text: (widget.initial?['remark'] ?? '').toString());
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
    return Dialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F4FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.grade_rounded,
                      size: 22, color: Color(0xFF1A237E)),
                ),
                const SizedBox(width: 14),
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _minC,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Min Score',
                      labelStyle:
                          TextStyle(color: Colors.grey.shade600),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                              color: Color(0xFF1A237E),
                              width: 2)),
                      filled: true,
                      fillColor: const Color(0xFFFAFBFC),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _maxC,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Max Score',
                      labelStyle:
                          TextStyle(color: Colors.grey.shade600),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                              color: Color(0xFF1A237E),
                              width: 2)),
                      filled: true,
                      fillColor: const Color(0xFFFAFBFC),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _gradeC,
              decoration: InputDecoration(
                labelText: 'Grade (e.g. A1)',
                labelStyle: TextStyle(color: Colors.grey.shade600),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                        color: Color(0xFF1A237E), width: 2)),
                filled: true,
                fillColor: const Color(0xFFFAFBFC),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _remarkC,
              decoration: InputDecoration(
                labelText: 'Remark (e.g. Excellent)',
                labelStyle: TextStyle(color: Colors.grey.shade600),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                        color: Color(0xFF1A237E), width: 2)),
                filled: true,
                fillColor: const Color(0xFFFAFBFC),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding:
                          const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Cancel',
                        style:
                            TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final mn = int.tryParse(_minC.text);
                      final mx = int.tryParse(_maxC.text);
                      final g = _gradeC.text.trim();
                      final r = _remarkC.text.trim();
                      if (mn == null ||
                          mx == null ||
                          g.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text('Fill all required fields'),
                            backgroundColor: Color(0xFFD32F2F),
                            behavior: SnackBarBehavior.floating,
                            shape: StadiumBorder(),
                          ),
                        );
                        return;
                      }
                      Navigator.pop(context, {
                        'min': mn,
                        'max': mx,
                        'grade': g,
                        'remark': r,
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A237E),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding:
                          const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Save',
                        style:
                            TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AssessDialog extends StatefulWidget {
  final String title;
  final Map<String, dynamic>? initial;
  const _AssessDialog({required this.title, this.initial});

  @override
  State<_AssessDialog> createState() => _AssessDialogState();
}

class _AssessDialogState extends State<_AssessDialog> {
  late TextEditingController _nameC, _idC, _maxC;

  @override
  void initState() {
    super.initState();
    _nameC = TextEditingController(
        text: (widget.initial?['name'] ?? '').toString());
    _idC = TextEditingController(
        text: (widget.initial?['id'] ?? '').toString());
    _maxC = TextEditingController(
        text: (widget.initial?['max'] ?? '').toString());
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
    return Dialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.tune_rounded,
                      size: 22, color: Color(0xFFF57F17)),
                ),
                const SizedBox(width: 14),
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nameC,
              decoration: InputDecoration(
                labelText: 'Name (e.g. CA1)',
                labelStyle: TextStyle(color: Colors.grey.shade600),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                        color: Color(0xFF1A237E), width: 2)),
                filled: true,
                fillColor: const Color(0xFFFAFBFC),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _idC,
              decoration: InputDecoration(
                labelText: 'ID (e.g. ca1)',
                labelStyle: TextStyle(color: Colors.grey.shade600),
                helperText: 'Lowercase, no spaces',
                helperStyle: TextStyle(
                    fontSize: 12, color: Colors.grey.shade400),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                        color: Color(0xFF1A237E), width: 2)),
                filled: true,
                fillColor: const Color(0xFFFAFBFC),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _maxC,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Maximum Score',
                labelStyle: TextStyle(color: Colors.grey.shade600),
                helperText: 'All assessments should sum to 100',
                helperStyle: TextStyle(
                    fontSize: 12, color: Colors.grey.shade400),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                        color: Color(0xFF1A237E), width: 2)),
                filled: true,
                fillColor: const Color(0xFFFAFBFC),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding:
                          const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Cancel',
                        style:
                            TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final n = _nameC.text.trim();
                      final id = _idC.text
                          .trim()
                          .toLowerCase()
                          .replaceAll(' ', '_');
                      final mx = int.tryParse(_maxC.text);
                      if (n.isEmpty || id.isEmpty || mx == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Fill all fields'),
                            backgroundColor: Color(0xFFD32F2F),
                            behavior: SnackBarBehavior.floating,
                            shape: StadiumBorder(),
                          ),
                        );
                        return;
                      }
                      Navigator.pop(context, {
                        'id': id,
                        'name': n,
                        'max': mx,
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A237E),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding:
                          const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Save',
                        style:
                            TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
