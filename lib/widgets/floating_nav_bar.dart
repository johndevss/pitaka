// lib/widgets/floating_nav_bar.dart

import 'package:flutter/material.dart';

enum NavTab { home, wallet, plan, history }

class FloatingNavBar extends StatelessWidget {
  final NavTab selectedTab;
  final ValueChanged<NavTab> onTabSelected;
  final VoidCallback onAddPressed;

  const FloatingNavBar({
    super.key,
    required this.selectedTab,
    required this.onTabSelected,
    required this.onAddPressed,
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
                    
                    // 1. The divider line separating the tabs from the filled action block
                    Container(
                      height: 32, // Floating divider line look
                      width: 1,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.12),
                    ),
                    
                    // 2. Wrap the button in an Expanded or let it define its width, 
                    // removing the outer padding so the color fills right to the edge.
                    _AddButton(onPressed: onAddPressed),
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

  const _AddButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 64,
        height: 64, // Matches the exact height of the pill container (64)
        decoration: BoxDecoration(
          color: theme.colorScheme.primary, // The filled color
          borderRadius: const BorderRadius.only(
            // 3. Matches the parent pill's outer 32px rounding on the right side
            topRight: Radius.circular(32),
            bottomRight: Radius.circular(32),
            // 4. Keeps a slight square-rounded corner on the inner side facing the divider
            topLeft: Radius.circular(12),
            bottomLeft: Radius.circular(12),
          ),
        ),
        child: Icon(
          Icons.add_rounded,
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