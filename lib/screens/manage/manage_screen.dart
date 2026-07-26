// lib/screens/manage/manage_screen.dart

import 'package:flutter/material.dart';

class ManageScreen extends StatelessWidget {
  const ManageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            // Header
            const Text(
              'Manage',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Manage your accounts, categories, and more.',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),

            // Full-width rows
            _ManageListItem(
              icon: Icons.category_outlined,
              title: 'Categories',
              subtitle: '8 categories',
              onTap: () {
                // TODO: Build categories screen
              },
            ),
            const SizedBox(height: 10),
            _ManageListItem(
              icon: Icons.flag_outlined,
              title: 'Personal Goals',
              subtitle: '5 accounts tracked',
              onTap: () {
                // TODO: Build personal goals screen
              },
            ),
            const SizedBox(height: 10),
            _ManageListItem(
              icon: Icons.subscriptions_outlined,
              title: 'Subscriptions',
              subtitle: '5 accounts tracked',
              onTap: () {
                // TODO: Build subscriptions screen
              },
            ),
            const SizedBox(height: 10),
            _ManageListItem(
              icon: Icons.speed,
              title: 'Daily Limit',
              subtitle: 'Set a limit for daily spending',
              onTap: () {
                // TODO: Build daily limit screen
              },
            ),
            const SizedBox(height: 10),
            _ManageListItem(
              icon: Icons.percent_outlined,
              title: 'Interest settings',
              subtitle: '2 accounts earning interest',
              onTap: () {
                // TODO: Build interest settings screen
              },
            ),
            const SizedBox(height: 20),

            // Two-per-row section (like Travel/Tags/Tools/Overview)
            Row(
              children: [
                Expanded(
                  child: _ManageListItem(
                    icon: Icons.download_outlined,
                    title: 'Export',
                    onTap: () {},
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ManageListItem(
                    icon: Icons.settings_outlined,
                    title: 'Settings',
                    onTap: () {
                      // TODO: Build tags screen
                    },
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

// Reusable row widget — the "module" you plug different values into
class _ManageListItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _ManageListItem({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 22, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
