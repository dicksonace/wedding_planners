import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../store/app_store.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import 'edit_profile_screen.dart';
import 'media_gallery_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppStore>().user!;
    final hasPlan = context.watch<AppStore>().hasPlan;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => Navigator.pop(context)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          AppCard(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: AppColors.softGreen,
                  child: Text(
                    user.name[0].toUpperCase(),
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.deepGreen),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                      Text(user.email, style: const TextStyle(color: AppColors.textMuted)),
                      if (user.region != null)
                        Text(user.region!, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_rounded, color: AppColors.deepGreen),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen())),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (user.isCouple) ...[
            const SectionTitle(title: 'Wedding media'),
            _SettingsTile(
              icon: Icons.mail_rounded,
              title: 'Invitations',
              subtitle: 'Upload invitation card designs',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MediaGalleryScreen(type: 'invitation', title: 'Invitations')),
              ),
            ),
            const SizedBox(height: 12),
            _SettingsTile(
              icon: Icons.photo_library_rounded,
              title: 'Wedding photos',
              subtitle: 'Save engagement & wedding pictures',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MediaGalleryScreen(type: 'wedding_photo', title: 'Wedding Photos')),
              ),
            ),
            if (!hasPlan) ...[
              const SizedBox(height: 12),
              const AppCard(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Create a wedding plan first to upload invitations and photos.',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ),
            ],
            const SizedBox(height: 20),
          ],
          const SectionTitle(title: 'Account'),
          _SettingsTile(
            icon: Icons.person_rounded,
            title: 'Edit profile',
            subtitle: 'Name, phone, partner, region',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen())),
          ),
          const SizedBox(height: 12),
          _SettingsTile(
            icon: Icons.logout_rounded,
            title: 'Log out',
            subtitle: 'Sign out of your account',
            iconColor: AppColors.richRed,
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Log out?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Log out')),
                  ],
                ),
              );
              if (confirm == true && context.mounted) {
                await context.read<AppStore>().logout();
                if (context.mounted) context.go('/login');
              }
            },
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor = AppColors.deepGreen,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(subtitle, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
        ],
      ),
    );
  }
}
