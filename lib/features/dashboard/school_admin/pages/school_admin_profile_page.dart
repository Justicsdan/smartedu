import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SchoolAdminProfilePage extends StatelessWidget {
  final Map<String, dynamic>? schoolData;

  const SchoolAdminProfilePage({super.key, this.schoolData});

  @override
  Widget build(BuildContext context) {
    // Safely extract school data from login payload
    final schoolName = schoolData?['name'] ?? 'School Name';
    final location = schoolData?['location'] ?? 'Location not set';
    final whatsapp = schoolData?['whatsapp'] ?? 'Not provided';
    final schoolType = schoolData?['school_type'] ?? 'N/A';
    final logoUrl = schoolData?['logo_url'] ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text('School Profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF4F8CFF), // Admin Blue
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40),
              decoration: const BoxDecoration(
                color: Color(0xFF4F8CFF),
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.white,
                    backgroundImage: logoUrl.isNotEmpty ? NetworkImage(logoUrl) : null,
                    child: logoUrl.isEmpty
                        ? Text(
                            schoolName.isNotEmpty ? schoolName.substring(0, 1).toUpperCase() : '?',
                            style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Color(0xFF4F8CFF)),
                          )
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    schoolName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                    child: Text(
                      schoolType.toString().toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // School Info Cards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  _buildInfoCard(Icons.location_on_rounded, 'School Address', location),
                  const SizedBox(height: 16),
                  _buildInfoCard(Icons.phone_rounded, 'WhatsApp / Phone', whatsapp),
                  const SizedBox(height: 16),
                  _buildInfoCard(Icons.admin_panel_settings_rounded, 'Admin Username', schoolData?['admin_username'] ?? 'N/A'),
                  const SizedBox(height: 30),

                  // Action Buttons
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Navigate to your existing settings page
                        context.go('/dashboard/schooladmin'); 
                      },
                      icon: const Icon(Icons.settings_rounded),
                      label: const Text('Edit School Settings', style: TextStyle(fontSize: 16)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F8CFF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                      label: const Text('Back to Dashboard', style: TextStyle(fontSize: 16)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF4F8CFF),
                        side: const BorderSide(color: Color(0xFF4F8CFF)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String title, String subtitle) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: const Color(0xFF4F8CFF).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: const Color(0xFF4F8CFF)),
        ),
        title: Text(title, style: TextStyle(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
      ),
    );
  }
}
