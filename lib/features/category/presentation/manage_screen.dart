// lib/screens/manage/manage_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pitaka/features/category/controllers/category_providers.dart';
import 'package:pitaka/features/category/presentation/categories_screen.dart';

import 'package:pitaka/core/utils/page_transitions.dart';

class ManageScreen extends ConsumerWidget {
  const ManageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final categoryCount = categoriesAsync.maybeWhen(
      data: (categories) => categories.length,
      orElse: () => null,
    );

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
              subtitle: categoryCount != null
                  ? '$categoryCount ${categoryCount == 1 ? 'category' : 'categories'}'
                  : 'Loading…',
              onTap: () {
                Navigator.of(
                  context,
                ).push(SmoothSlideRoute(page: const CategoriesScreen()));
              },
            ),
            const SizedBox(height: 10),
            _ManageListItem(
              icon: Icons.flag_outlined,
              title: 'Personal Goals',
              subtitle: 'Coming Soon!',
              onTap: () {
                // TODO: Build personal goals screen
              },
            ),
            const SizedBox(height: 10),
            _ManageListItem(
              icon: Icons.subscriptions_outlined,
              title: 'Subscriptions',
              subtitle: 'Coming Soon!',
              onTap: () {
                // TODO: Build subscriptions screen
              },
            ),
            const SizedBox(height: 10),
            _ManageListItem(
              icon: Icons.speed,
              title: 'Daily Limit',
              subtitle: 'Coming Soon!',
              onTap: () {
                // TODO: Build daily limit screen
              },
            ),
            const SizedBox(height: 10),
            _ManageListItem(
              icon: Icons.percent_outlined,
              title: 'Interest settings',
              subtitle: 'Coming Soon!',
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
                    onTap: () {
                      //TODO: Build Export Screen
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Coming Soon!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ManageListItem(
                    icon: Icons.settings_outlined,
                    title: 'Settings',
                    onTap: () {
                      //TODO: Build settings screen
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Coming Soon!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
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
