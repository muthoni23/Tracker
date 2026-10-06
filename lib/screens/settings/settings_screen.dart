import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/theme_controller.dart';
import '../account/account_screen.dart';
import '../auth/login_screen.dart';
import '../courses/courses_screen.dart';
import '../help/help_support_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final authService = AuthService();
    await authService.signOut();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'My Assignment Tracker',
      applicationVersion: '1.0.0',
      applicationLegalese: 'Plan · Focus · Achieve',
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: AuthService.profileVersion,
      builder: (context, _, __) => ValueListenableBuilder<ThemeMode>(
        valueListenable: ThemeController.themeMode,
        builder: (context, mode, __) => _buildBody(context, mode == ThemeMode.dark),
      ),
    );
  }

  Widget _buildBody(BuildContext context, bool isDarkMode) {
    final colors = context.surfaceColors;
    final user = FirebaseAuth.instance.currentUser;
    final name = (user?.displayName?.isNotEmpty ?? false) ? user!.displayName! : 'Student';
    final email = user?.email ?? '';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Settings', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: colors.textPrimary)),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primary,
                  child: Text(initial, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: TextStyle(fontWeight: FontWeight.w700, color: colors.textPrimary)),
                      Text(email, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _SettingsTile(
            icon: Icons.person_outline,
            label: 'Account',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AccountScreen()),
            ),
          ),
          _SettingsTile(
            icon: Icons.dark_mode_outlined,
            label: 'Appearance',
            subtitle: isDarkMode ? 'Dark mode' : 'Light mode',
            trailing: Switch(
              value: isDarkMode,
              onChanged: (v) => ThemeController.setDarkMode(v),
            ),
          ),
          _SettingsTile(icon: Icons.menu_book_outlined, label: 'Courses', onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CoursesScreen()),
          )),
          _SettingsTile(
            icon: Icons.help_outline,
            label: 'Help & Support',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const HelpSupportScreen()),
            ),
          ),
          _SettingsTile(icon: Icons.info_outline, label: 'About', onTap: () => _showAbout(context)),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            icon: const Icon(Icons.logout, color: AppColors.priorityHigh),
            label: const Text('Log Out', style: TextStyle(color: AppColors.priorityHigh)),
            style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.priorityHigh)),
            onPressed: () => _logout(context),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.label,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.surfaceColors;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: colors.textPrimary)),
        subtitle: subtitle != null ? Text(subtitle!, style: TextStyle(color: colors.textSecondary)) : null,
        trailing: trailing ?? Icon(Icons.chevron_right, color: colors.textSecondary),
        onTap: onTap,
      ),
    );
  }
}
