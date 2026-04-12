import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SaDrawer extends StatelessWidget {
  final String adminName;

  const SaDrawer({
    super.key,
    this.adminName = 'Platform Owner',
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: const Color(0xFF1E3C72),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 24),
              // Logo
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.admin_panel_settings, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'SmartEdu',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Admin info
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      adminName,
                      style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Super Admin',
                      style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // Menu items
              _DrawerItem(
                icon: Icons.dashboard_rounded,
                label: 'Dashboard',
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              _DrawerItem(
                icon: Icons.domain_rounded,
                label: 'Schools',
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              _DrawerItem(
                icon: Icons.people_rounded,
                label: 'All Users',
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              _DrawerItem(
                icon: Icons.account_balance_wallet_rounded,
                label: 'Payments',
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              _DrawerItem(
                icon: Icons.bar_chart_rounded,
                label: 'Analytics',
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              _DrawerItem(
                icon: Icons.settings_rounded,
                label: 'Settings',
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              const Spacer(),
              // Logout
              Padding(
                padding: const EdgeInsets.all(16),
                child: GestureDetector(
                  onTap: () => context.go('/role-selection'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.logout, color: Colors.redAccent, size: 20),
                        SizedBox(width: 12),
                        Text('Logout', style: TextStyle(color: Colors.redAccent, fontSize: 14, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: Icon(icon, color: Colors.white54, size: 20),
      title: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
      onTap: onTap,
    );
  }
}
