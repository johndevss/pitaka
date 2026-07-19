// lib/screens/home_shell.dart

import 'package:flutter/material.dart';
import '../widgets/floating_nav_bar.dart';
import 'account/accounts_screen.dart';
import 'dashboard_screen.dart';
import 'expense_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  NavTab _selectedTab = NavTab.home;

  Widget _screenForTab(NavTab tab) {
    switch (tab) {
      case NavTab.home:
        return const DashboardScreen();
      case NavTab.wallet:
        return const AccountsScreen();
      case NavTab.plan:
        // Budget/planning screen not built yet — placeholder for now
        return const Scaffold(
          body: Center(child: Text('Plan (planned)')),
        );
      case NavTab.history:
        // Transactions/history screen not built yet — placeholder for now
        return const Scaffold(
          body: Center(child: Text('History (planned)')),
        );
    }
  }

  void _onAddPressed() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const ExpenseScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screenForTab(_selectedTab),
      bottomNavigationBar: FloatingNavBar(
        selectedTab: _selectedTab,
        onTabSelected: (tab) => setState(() => _selectedTab = tab),
        onAddPressed: _onAddPressed,
      ),
    );
  }
}