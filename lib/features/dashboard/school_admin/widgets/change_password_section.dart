import 'package:flutter/material.dart';

class ChangePasswordSection extends StatefulWidget {
  final String title;
  final String subtitle;
  final String currentLabel;
  final String newLabel;
  final String confirmLabel;
  final String buttonLabel;
  final Future<bool> Function(String currentPass, String newPass) onSubmit;

  const ChangePasswordSection({
    super.key,
    required this.title,
    required this.subtitle,
    required this.currentLabel,
    required this.newLabel,
    required this.confirmLabel,
    this.buttonLabel = 'Change Password',
    required this.onSubmit,
  });

  @override
  State<ChangePasswordSection> createState() => _ChangePasswordSectionState();
}

class _ChangePasswordSectionState extends State<ChangePasswordSection> {
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final current = _currentCtrl.text.trim();
    final newPass = _newCtrl.text.trim();
    final confirm = _confirmCtrl.text.trim();

    if (current.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter your current password'), backgroundColor: Color(0xFFD32F2F), behavior: SnackBarBehavior.floating, shape: StadiumBorder()));
      return;
    }
    if (newPass.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('New password must be at least 6 characters'), backgroundColor: Color(0xFFD32F2F), behavior: SnackBarBehavior.floating, shape: StadiumBorder()));
      return;
    }
    if (newPass != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('New passwords do not match'), backgroundColor: Color(0xFFD32F2F), behavior: SnackBarBehavior.floating, shape: StadiumBorder()));
      return;
    }
    if (current == newPass) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('New password must be different from current'), backgroundColor: Color(0xFFE65100), behavior: SnackBarBehavior.floating, shape: StadiumBorder()));
      return;
    }

    setState(() => _loading = true);
    try {
      final ok = await widget.onSubmit(current, newPass);
      if (!mounted) return;
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password changed successfully'), backgroundColor: Color(0xFF2E7D32), behavior: SnackBarBehavior.floating, shape: StadiumBorder()));
        _currentCtrl.clear();
        _newCtrl.clear();
        _confirmCtrl.clear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Current password is incorrect'), backgroundColor: Color(0xFFD32F2F), behavior: SnackBarBehavior.floating, shape: StadiumBorder()));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: Color(0xFFD32F2F), behavior: SnackBarBehavior.floating, shape: StadiumBorder()));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        _sectionHeader(),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFE8EAED)), borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              _field(_currentCtrl, widget.currentLabel, _obscureCurrent, (v) => setState(() => _obscureCurrent = v)),
              const SizedBox(height: 16),
              _field(_newCtrl, widget.newLabel, _obscureNew, (v) => setState(() => _obscureNew = v)),
              const SizedBox(height: 16),
              _field(_confirmCtrl, widget.confirmLabel, _obscureConfirm, (v) => setState(() => _obscureConfirm = v)),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E), foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  child: _loading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(widget.buttonLabel, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sectionHeader() {
    return Row(
      children: [
        Container(width: 32, height: 32, decoration: BoxDecoration(color: const Color(0xFFFFF8E1), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.lock_outline_rounded, color: Color(0xFFF57F17), size: 18)),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
          Text(widget.subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
        ]),
      ],
    );
  }

  Widget _field(TextEditingController ctrl, String label, bool obscure, ValueChanged<bool> toggleObscure) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
        filled: true,
        fillColor: const Color(0xFFFAFBFC),
        suffixIcon: IconButton(icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20, color: Colors.grey.shade500), onPressed: () => toggleObscure(!obscure)),
      ),
    );
  }
}
