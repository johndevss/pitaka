// lib/screens/home_shell.dart

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:pitaka/core/utils/page_transitions.dart';
import 'package:pitaka/core/widgets/floating_nav_bar.dart';
import 'package:pitaka/core/widgets/shared_axis_tab_switcher.dart';
import 'package:pitaka/features/account/presentation/accounts_screen.dart';
import 'package:pitaka/features/dashboard/presentation/dashboard_screen.dart';
import 'package:pitaka/features/transaction/presentation/expense_screen.dart';
import 'package:pitaka/features/transaction/presentation/transfer_screen.dart';
import 'package:pitaka/features/category/presentation/manage_screen.dart';
import 'package:pitaka/features/transaction/presentation/history_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  NavTab _selectedTab = NavTab.home;
  bool _isMenuOpen = false; // Tracks if the floating menu is currently open
  bool _isNavBarVisible = true; // Tracks if the navigation bar is visible

  static const List<Widget> _screens = [
    DashboardScreen(),
    AccountsScreen(),
    ManageScreen(),
    HistoryScreen(),
  ];

  void _onTabSelected(NavTab tab) {
    if (_selectedTab != tab) {
      HapticFeedback.selectionClick();
      setState(() => _selectedTab = tab);
    }
  }

  void _onAddPressed() {
    HapticFeedback.mediumImpact();
    // Turn button state to 'X' and gray
    setState(() => _isMenuOpen = true);

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.transparent, // 1. No background overlay shadow
      transitionDuration: const Duration(
        milliseconds: 150,
      ), // 2. Faster animation speed (150ms)
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.bottomRight,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 100, right: 20),
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 200,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.grey.shade200,
                  ), // Clean border instead of shadow
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _MenuOption(
                      heroTag: 'hero_income_option',
                      icon: Icons.arrow_upward_rounded,
                      color: const Color(0xFF2E9F5D),
                      label: 'Income',
                      onTap: () {
                        final nav = Navigator.of(dialogContext);
                        nav.pop();
                        nav.push(
                          SmoothExpandRoute(
                            alignment: const Alignment(0.6, 0.65),
                            page: const ExpenseScreen(
                              initialIsExpense: false,
                              heroTag: 'hero_income_option',
                            ),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1, color: Color(0xFFF5F7F5)),
                    _MenuOption(
                      heroTag: 'hero_expense_option',
                      icon: Icons.arrow_downward_rounded,
                      color: const Color(0xFFD64545),
                      label: 'Expense',
                      onTap: () {
                        final nav = Navigator.of(dialogContext);
                        nav.pop();
                        nav.push(
                          SmoothExpandRoute(
                            alignment: const Alignment(0.6, 0.73),
                            page: const ExpenseScreen(
                              initialIsExpense: true,
                              heroTag: 'hero_expense_option',
                            ),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1, color: Color(0xFFF5F7F5)),
                    _MenuOption(
                      heroTag: 'hero_transfer_option',
                      icon: Icons.swap_horiz_rounded,
                      color: const Color(0xFF2D88D4),
                      label: 'Transfer',
                      onTap: () {
                        final nav = Navigator.of(dialogContext);
                        nav.pop();
                        nav.push(
                          SmoothExpandRoute(
                            alignment: const Alignment(0.6, 0.81),
                            page: const TransferScreen(
                              heroTag: 'hero_transfer_option',
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim, secondaryAnim, child) {
        return ScaleTransition(
          scale: CurvedAnimation(
            parent: anim,
            curve: Curves.easeOutCubic, // Fast and snappy exit/entry
          ),
          alignment: Alignment.bottomRight,
          child: FadeTransition(opacity: anim, child: child),
        );
      },
    ).then((_) {
      // Revert button back to '+' when menu closes
      if (mounted) {
        setState(() => _isMenuOpen = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: NotificationListener<UserScrollNotification>(
        onNotification: (notification) {
          // Ignore horizontal scrolls (e.g. the accounts card carousel)
          if (notification.metrics.axis != Axis.vertical) {
            return false;
          }
          // Check the scroll direction
          if (notification.direction == ScrollDirection.reverse) {
            // User is scrolling down, hide the nav bar
            if (_isNavBarVisible) {
              setState(() => _isNavBarVisible = false);
            }
          } else if (notification.direction == ScrollDirection.forward) {
            // User is scrolling up, show the nav bar
            if (!_isNavBarVisible) {
              setState(() => _isNavBarVisible = true);
            }
          }
          return true;
        },
        child: SharedAxisTabSwitcher(
          selectedIndex: _selectedTab.index,
          children: _screens,
        ),
      ),
      bottomNavigationBar: AnimatedSlide(
        duration: const Duration(
          milliseconds: 300,
        ), // Adjust value to control speed of animation
        curve: Curves.easeOutCubic,
        // Slide down off-screen if false, stay in place if true
        offset: _isNavBarVisible ? Offset.zero : const Offset(0, 2),
        child: FloatingNavBar(
          selectedTab: _selectedTab,
          isMenuOpen: _isMenuOpen,
          onTabSelected: _onTabSelected,
          onAddPressed: _onAddPressed,
        ),
      ),
    );
  }
}

class _MenuOption extends StatelessWidget {
  final String heroTag;
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _MenuOption({
    required this.heroTag,
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: heroTag,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            child: Row(
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(width: 14),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF222222),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
