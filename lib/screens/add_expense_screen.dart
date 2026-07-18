// lib/screens/add_expense_screen.dart

import 'package:flutter/material.dart';

class AddExpenseScreen extends StatelessWidget {
  const AddExpenseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Expense')),
      body: const Center(
        child: Text('Add expense form goes here (not built yet).'),
      ),
    );
  }
}