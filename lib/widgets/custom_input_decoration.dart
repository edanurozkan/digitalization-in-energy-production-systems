import 'package:flutter/material.dart';
import '../theme/theme.dart';

class CustomInputDecoration {
  static InputDecoration input(
      {required String label, required IconData icon}) {
    return InputDecoration(
      prefixIcon: Icon(icon),
      labelText: label,
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: AppColors.primary),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.cardBackground, width: 3),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}
