// lib/widgets/floating_nav_bar.dart

import 'package:flutter/material.dart';

enum NavTab { home, wallet, plan, history }

class FloatingNavBar extends StatelessWidget {
  final NavTab selectedTab;
  final ValueChanged<NavTab> onTabSelected;
  final VoidCallback onAddPressed;
  final bool isMenuOpen;

  const FloatingNavBar({
    super.key,
    required this.selectedTab,
    required this.onTabSelected,
    required this.onAddPressed,
    this.isMenuOpen = false, // Defaults to false
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // The pill now wraps EVERYTHING, including the add button
            Expanded(
              child: Container(
                height: 64,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    _NavItem(
                      icon: Icons.home_rounded,
                      label: 'Home',
                      isSelected: selectedTab == NavTab.home,
                      onTap: () => onTabSelected(NavTab.home),
                    ),
                    _NavItem(
                      icon: Icons.account_balance_wallet_rounded,
                      label: 'Wallet',
                      isSelected: selectedTab == NavTab.wallet,
                      onTap: () => onTabSelected(NavTab.wallet),
                    ),
                    _NavItem(
                      icon: Icons.calendar_today_rounded,
                      label: 'Plan',
                      isSelected: selectedTab == NavTab.plan,
                      onTap: () => onTabSelected(NavTab.plan),
                    ),
                    _NavItem(
                      icon: Icons.history_rounded,
                      label: 'History',
                      isSelected: selectedTab == NavTab.history,
                      onTap: () => onTabSelected(NavTab.history),
                    ),
                    
                    Container(
                      height: 32, // Floating divider line look
                      width: 1,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.12),
                    ),
                    
                    // Passed isMenuOpen into _AddButton
                    _AddButton(
                      onPressed: onAddPressed,
                      isMenuOpen: isMenuOpen,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isMenuOpen;

  const _AddButton({
    required this.onPressed,
    required this.isMenuOpen,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          // Color changes to gray when open, or theme primary when closed
          color: isMenuOpen ? Colors.grey.shade600 : theme.colorScheme.primary,
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(32),
            bottomRight: Radius.circular(32),
            topLeft: Radius.circular(12),
            bottomLeft: Radius.circular(12),
          ),
        ),
        child: Icon(
          // Icon flips between 'X' and '+'
          isMenuOpen ? Icons.close_rounded : Icons.add_rounded,
          color: theme.colorScheme.onPrimary,
          size: 28,
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isSelected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurface.withValues(alpha: 0.5);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          margin: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primary.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}