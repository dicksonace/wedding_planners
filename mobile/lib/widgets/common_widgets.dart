import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../store/app_store.dart';
import '../theme/app_theme.dart';
import '../screens/couple/settings_screen.dart';

class AppAddFab extends StatelessWidget {
  const AppAddFab({super.key, required this.onPressed, this.tooltip});

  final VoidCallback onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 72),
      child: FloatingActionButton(
        onPressed: onPressed,
        tooltip: tooltip ?? 'Add',
        child: const Icon(Icons.add_rounded, size: 28),
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: AppDecor.radiusMd,
        gradient: const LinearGradient(
          colors: [AppColors.deepGreen, AppColors.deepGreenLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.deepGreen.withValues(alpha: 0.28),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          minimumSize: const Size(double.infinity, 54),
        ),
        onPressed: loading ? null : onPressed,
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
                  Text(label),
                ],
              ),
      ),
    );
  }
}

class ProfileMenuButton extends StatelessWidget {
  const ProfileMenuButton({super.key, this.light = false});

  final bool light;

  Future<void> _logout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You will need to sign in again to access your wedding plan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Log out')),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;
    await context.read<AppStore>().logout();
    if (context.mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppStore>().user;
    final initial = (user?.name.isNotEmpty == true ? user!.name[0] : 'U').toUpperCase();

    return PopupMenuButton<String>(
      offset: const Offset(0, 48),
      shape: RoundedRectangleBorder(borderRadius: AppDecor.radiusMd),
      onSelected: (value) {
        if (value == 'settings') {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
        } else if (value == 'logout') {
          _logout(context);
        }
      },
      itemBuilder: (_) => [
        if (user != null)
          PopupMenuItem(
            enabled: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(user.email, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
              ],
            ),
          ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'settings',
          child: Row(
            children: [
              Icon(Icons.settings_rounded, size: 20, color: AppColors.deepGreen),
              SizedBox(width: 10),
              Text('Settings', style: TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout_rounded, size: 20, color: AppColors.richRed),
              SizedBox(width: 10),
              Text('Log out', style: TextStyle(color: AppColors.richRed, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: light ? Colors.white.withValues(alpha: 0.18) : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: light ? Colors.white24 : Colors.grey.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: light ? Colors.white : AppColors.softGreen,
              child: Text(initial, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: light ? AppColors.deepGreen : AppColors.deepGreen)),
            ),
            if (!light) ...[
              const SizedBox(width: 6),
              const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: AppColors.textMuted),
            ],
          ],
        ),
      ),
    );
  }
}

class CoupleAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CoupleAppBar({super.key, required this.title});

  final String title;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      actions: const [ProfileMenuButton()],
    );
  }
}

class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.onTap, this.padding = const EdgeInsets.all(20)});

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 0,
      shadowColor: Colors.transparent,
      borderRadius: AppDecor.radiusLg,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppDecor.radiusLg,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: AppDecor.radiusLg,
            boxShadow: AppDecor.cardShadow,
            border: Border.all(color: Colors.white),
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.color = AppColors.deepGreen,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: AppDecor.radiusLg,
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.14), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: AppDecor.cardShadow,
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 14),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, maxLines: 1, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12, height: 1.2, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.softGreen, Colors.white],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: AppDecor.cardShadow,
              ),
              child: Icon(icon, size: 40, color: AppColors.deepGreen),
            ),
            const SizedBox(height: 20),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(subtitle!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textMuted, height: 1.4)),
            ],
            if (action != null) ...[const SizedBox(height: 24), action!],
          ],
        ),
      ),
    );
  }
}

class GradientHeader extends StatelessWidget {
  const GradientHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 16, 24, 32),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF004D2E), AppColors.deepGreenLight, Color(0xFF00A35C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Stack(
        children: [
          Positioned(right: -20, top: -10, child: _orb(90, 0.08)),
          Positioned(left: -30, bottom: -20, child: _orb(120, 0.06)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('WedPlan Ghana', style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.6)),
                        const SizedBox(height: 6),
                        Text(title, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800, height: 1.1)),
                      ],
                    ),
                  ),
                  trailing ?? const ProfileMenuButton(light: true),
                ],
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 10),
                Text(subtitle!, style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 15, height: 1.3)),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _orb(double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: opacity),
      ),
    );
  }
}

class QuickActionChip extends StatelessWidget {
  const QuickActionChip({super.key, required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: AppDecor.radiusMd,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppDecor.radiusMd,
        child: Ink(
          width: 96,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: AppDecor.radiusMd,
            boxShadow: AppDecor.cardShadow,
          ),
          child: Column(
            children: [
              Icon(icon, color: AppColors.deepGreen),
              const SizedBox(height: 8),
              Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle({super.key, required this.title, this.action});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
          if (action != null) action!,
        ],
      ),
    );
  }
}
