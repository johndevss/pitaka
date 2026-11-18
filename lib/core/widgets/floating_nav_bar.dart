// lib/core/widgets/floating_nav_bar.dart

import 'package:flutter/material.dart';
import 'package:pitaka/core/utils/haptic_engine.dart';

enum NavTab { home, wallet, manage, history }

class FloatingNavBar extends StatelessWidget {
  final NavTab selectedTab;
  final ValueChanged<NavTab> onTabSelected;
  final VoidCallback onAddPressed;
  final VoidCallback? onAddLongPressed;
  final bool isMenuOpen;

  const FloatingNavBar({
    super.key,
    required this.selectedTab,
    required this.onTabSelected,
    required this.onAddPressed,
    this.onAddLongPressed,
    this.isMenuOpen = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Container(
                height: 64,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.10),
                      blurRadius: 20,
                      spreadRadius: 0,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
                    _CenterAddButton(
                      onPressed: onAddPressed,
                      onLongPressed: onAddLongPressed,
                      isMenuOpen: isMenuOpen,
                    ),
                    _NavItem(
                      icon: Icons.calendar_today_rounded,
                      label: 'Manage',
                      isSelected: selectedTab == NavTab.manage,
                      onTap: () => onTabSelected(NavTab.manage),
                    ),
                    _NavItem(
                      icon: Icons.history_rounded,
                      label: 'History',
                      isSelected: selectedTab == NavTab.history,
                      onTap: () => onTabSelected(NavTab.history),
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

class _CenterAddButton extends StatelessWidget {
  final VoidCallback onPressed;
  final VoidCallback? onLongPressed;
  final bool isMenuOpen;

  const _CenterAddButton({
    required this.onPressed,
    this.onLongPressed,
    required this.isMenuOpen,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        onTap: onPressed,
        onLongPress: onLongPressed != null
            ? () {
                HapticEngine.heavy();
                onLongPressed!();
              }
            : null,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isMenuOpen
                  ? [Colors.grey.shade700, Colors.grey.shade800]
                  : [
                      primaryColor,
                      HSLColor.fromColor(primaryColor)
                          .withLightness(
                            (HSLColor.fromColor(primaryColor).lightness - 0.08)
                                .clamp(0.0, 1.0),
                          )
                          .toColor(),
                    ],
            ),
            boxShadow: [
              BoxShadow(
                color: isMenuOpen
                    ? Colors.black26
                    : primaryColor.withValues(alpha: 0.40),
                blurRadius: 12,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: AnimatedRotation(
            turns: isMenuOpen ? 0.125 : 0.0,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutBack,
            child: Icon(
              isMenuOpen ? Icons.close_rounded : Icons.add_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
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
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primary.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
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
