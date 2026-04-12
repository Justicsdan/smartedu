import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartedu/core/super_admin_provider.dart';
import 'package:smartedu/core/school_model.dart'; // REVERTED to core import to match provider

class ManageSchoolsPage extends StatefulWidget {
  const ManageSchoolsPage({super.key});

  @override
  State<ManageSchoolsPage> createState() => _ManageSchoolsPageState();
}

class _ManageSchoolsPageState extends State<ManageSchoolsPage> {
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _whatsappController = TextEditingController();
  String _schoolType = 'primary';
  String _logoBase64 = '';
  bool _isSubmitting = false;

  Future<void> _pickLogo() async {
    final input = html.FileUploadInputElement();
    input.accept = 'image/*';
    input.click();

    input.onChange.listen((event) {
      final files = input.files;
      if (files == null || files.isEmpty) return;

      final file = files.first;
      final reader = html.FileReader();

      reader.onLoadEnd.listen((event) {
        setState(() {
          _logoBase64 = reader.result as String;
        });
      });

      reader.readAsDataUrl(file);
    });
  }

  Future<void> _showAddDialog() async {
    _nameController.clear();
    _locationController.clear();
    _whatsappController.clear();
    _schoolType = 'primary';
    _logoBase64 = '';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSt) => AlertDialog(
          title: const Text("Register New School"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: _pickLogo,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(60),
                      border: Border.all(color: Colors.grey.shade300, width: 2),
                    ),
                    child: _logoBase64.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(60),
                            child: Image.network(_logoBase64, fit: BoxFit.cover),
                          )
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.camera_alt, size: 40, color: Colors.grey),
                              SizedBox(height: 8),
                              Text("Upload Logo", style: TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: "School Name",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.school, color: Color(0xFF1E3C72)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    labelText: "Location/Address",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_on, color: Color(0xFF1E3C72)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _whatsappController,
                  decoration: const InputDecoration(
                    labelText: "WhatsApp Number",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.chat, color: Color(0xFF25D366)),
                    hintText: "+234 xxx xxx xxxx",
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _schoolType,
                  decoration: const InputDecoration(
                    labelText: "School Type",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category, color: Color(0xFF1E3C72)),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'primary', child: Text('Primary')),
                    DropdownMenuItem(value: 'secondary', child: Text('Secondary')),
                    DropdownMenuItem(value: 'both', child: Text('Primary & Secondary')),
                  ],
                  onChanged: (v) => setSt(() => _schoolType = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: _isSubmitting ? null : () async {
                if (_nameController.text.isEmpty || _locationController.text.isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text("Please fill required fields"), backgroundColor: Colors.red),
                  );
                  return;
                }

                setSt(() => _isSubmitting = true);

                final provider = context.read<SuperAdminProvider>();
                final result = await provider.addSchool(
                  name: _nameController.text.trim(),
                  location: _locationController.text.trim(),
                  schoolType: _schoolType,
                  logoUrl: _logoBase64,
                  whatsapp: _whatsappController.text.trim(),
                );

                Navigator.pop(ctx);

                if (result != null) {
                  _showCredentialsDialog(result['username']!, result['password']!);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Failed to register school"), backgroundColor: Colors.red),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3C72)),
              child: _isSubmitting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text("Register", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showCredentialsDialog(String username, String password) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("School Registered!"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, size: 60, color: Colors.green),
            const SizedBox(height: 16),
            const Text("Save these credentials for the school admin:"),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text("Username:", style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(username, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF1E3C72))),
                  const Divider(),
                  const Text("Password:", style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(password, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF1E3C72))),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Close")),
        ],
      ),
    );
  }

  void _showLoginDialog(School school) {
    final logoUrl = school.logoUrl;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("School Admin Login"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (logoUrl != null && logoUrl.isNotEmpty)
              CircleAvatar(
                radius: 40,
                backgroundImage: NetworkImage(logoUrl),
              ),
            const SizedBox(height: 16),
            Text(school.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text("Username:"),
                  Text(
                    school.adminUsername ?? 'N/A',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3C72)),
                  ),
                  const SizedBox(height: 12),
                  const Text("Password:"),
                  Text(
                    school.adminPassword ?? 'N/A',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3C72)),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Close")),
        ],
      ),
    );
  }

  void _confirmDelete(School school) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete School"),
        content: Text("Are you sure you want to delete \"${school.name}\"?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<SuperAdminProvider>().deleteSchool(school.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("${school.name} deleted"), backgroundColor: Colors.red),
              );
            },
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _whatsappController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Schools"),
        backgroundColor: const Color(0xFF1E3C72),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        backgroundColor: const Color(0xFF1E3C72),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Register School", style: TextStyle(color: Colors.white)),
      ),
      body: Consumer<SuperAdminProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.schools.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.schools.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.school_outlined, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text("No schools registered yet", style: TextStyle(fontSize: 16, color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.schools.length,
            itemBuilder: (context, index) {
              final school = provider.schools[index];
              return _SchoolCard(
                school: school,
                onToggleStatus: () => provider.toggleSchoolStatus(school.id),
                onTogglePayment: () => provider.togglePaymentStatus(school.id),
                onViewLogin: () => _showLoginDialog(school),
                onDelete: () => _confirmDelete(school),
              );
            },
          );
        },
      ),
    );
  }
}

class _SchoolCard extends StatelessWidget {
  final School school;
  final VoidCallback onToggleStatus;
  final VoidCallback onTogglePayment;
  final VoidCallback onViewLogin;
  final VoidCallback onDelete;

  const _SchoolCard({
    required this.school,
    required this.onToggleStatus,
    required this.onTogglePayment,
    required this.onViewLogin,
    required this.onDelete,
  });

  // Fixed: Use string parsing to avoid enum conflict between core and models files
  String get _typeString => school.schoolType.toString().split('.').last.toLowerCase();

  Color get _typeColor {
    switch (_typeString) {
      case 'primary':
        return Colors.blue;
      case 'secondary':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String get _typeLabel {
    final name = _typeString;
    return name.isEmpty ? '' : '${name[0].toUpperCase()}${name.substring(1)}';
  }

  // Fixed: Avoid importing the second School model by checking string status
  bool get _isPaid {
    final statusStr = school.subscriptionStatus.toString().split('.').last.toLowerCase();
    return statusStr == 'active';
  }

  @override
  Widget build(BuildContext context) {
    final logoUrl = school.logoUrl;
    final whatsapp = school.whatsapp;

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: _typeColor.withOpacity(0.1),
                  backgroundImage: (logoUrl != null && logoUrl.isNotEmpty) ? NetworkImage(logoUrl) : null,
                  child: (logoUrl == null || logoUrl.isEmpty) ? Icon(Icons.school, size: 30, color: _typeColor) : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(school.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1E3C72))),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              school.location ?? '',
                              style: const TextStyle(fontSize: 13, color: Colors.grey),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (whatsapp != null && whatsapp.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.chat, size: 14, color: Color(0xFF25D366)),
                            const SizedBox(width: 4),
                            Text(whatsapp, style: const TextStyle(fontSize: 13, color: Color(0xFF25D366), fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: _typeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                  child: Text(_typeLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _typeColor)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                GestureDetector(
                  onTap: onToggleStatus,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: (school.isActive ? Colors.green : Colors.red).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, size: 8, color: school.isActive ? Colors.green : Colors.red),
                        const SizedBox(width: 4),
                        Text(school.isActive ? "Active" : "Inactive", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: school.isActive ? Colors.green : Colors.red)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onTogglePayment,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: (_isPaid ? Colors.green : Colors.orange).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, size: 8, color: _isPaid ? Colors.green : Colors.orange),
                        const SizedBox(width: 4),
                        Text(_isPaid ? "Paid" : "Unpaid", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _isPaid ? Colors.green : Colors.orange)),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(icon: const Icon(Icons.key, size: 20), tooltip: "View Login", onPressed: onViewLogin),
                IconButton(icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red), tooltip: "Delete", onPressed: onDelete),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
