import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:smartedu/core/providers/teacher/teacher_provider.dart';

class TeacherProfilePage extends StatelessWidget {
  final Map<String, dynamic> teacherData;

  const TeacherProfilePage({super.key, required this.teacherData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text('Teacher Profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF00C9A7), // Green for teachers
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Consumer<TeacherProvider>(
        builder: (context, provider, child) {
          return SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  decoration: const BoxDecoration(
                    color: Color(0xFF00C9A7),
                    borderRadius: BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.white,
                        // Uses real initials from provider
                        child: Text(
                          provider.fullName.isNotEmpty ? provider.fullName.substring(0, 1).toUpperCase() : '?', 
                          style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Color(0xFF00C9A7))
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Real Name from Provider
                      Text(provider.fullName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                        // Real Staff ID from Provider
                        child: Text('Staff ID: ${provider.staffId}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 30),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      // Real School Name from Provider
                      _buildInfoCard(Icons.school_rounded, 'School', provider.schoolName),
                      const SizedBox(height: 16),
                      // Real Email from Provider (No more mock data)
                      _buildInfoCard(Icons.email_rounded, 'Email', provider.email.isNotEmpty ? provider.email : 'No Email Provided'),
                      const SizedBox(height: 16),
                      // Real Phone from Provider
                      _buildInfoCard(Icons.phone_rounded, 'Phone', provider.phone.isNotEmpty ? provider.phone : 'No Phone Provided'),
                      const SizedBox(height: 30),
                      
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: () => context.go('/dashboard/teacher'),
                          icon: const Icon(Icons.class_rounded),
                          label: const Text('View Assigned Classes', style: TextStyle(fontSize: 16)),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00C9A7), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
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
                          style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF00C9A7), side: const BorderSide(color: Color(0xFF00C9A7)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        ),
                      )
                    ],
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String title, String subtitle) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
      child: ListTile(
        leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFF00C9A7).withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: const Color(0xFF00C9A7))),
        title: Text(title, style: TextStyle(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
      ),
    );
  }
}
