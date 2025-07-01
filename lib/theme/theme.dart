import 'package:flutter/material.dart';

class AppColors {
  static const background = Color(0xFFE6EDD4); //0xFFE6EDD4
  static const card =
      Color.fromARGB(255, 32, 42, 7); // Bottom bar arka planı 0xFF1D2606
  static const primary = Color(0xFFCDEB6F); // Seçili ikon/metin
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFCCCCCC); // Seçilmemiş ikon/metin
  static const cardBackground = Color.fromARGB(255, 189, 224, 101);
  // Açık yeşil-gri arası kart rengi Color.fromARGB(255, 184, 212, 113)
  //255, 183, 210, 114
}

final ThemeData appTheme = ThemeData(
  scaffoldBackgroundColor: AppColors.background,
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.card,
    foregroundColor: AppColors.textPrimary,
    elevation: 0,
  ),
  drawerTheme: const DrawerThemeData(
    backgroundColor: AppColors.card,
  ),
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: AppColors.textPrimary),
    bodyMedium: TextStyle(color: AppColors.textSecondary),
  ),
  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: AppColors.card,
    indicatorColor: Color.fromRGBO(
        205, 235, 111, 0.2), // AppColors.primary.withOpacity(0.2),
    labelTextStyle: MaterialStateProperty.all(
      const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
    ),
    iconTheme: MaterialStateProperty.resolveWith<IconThemeData>((states) {
      if (states.contains(MaterialState.selected)) {
        return const IconThemeData(color: AppColors.primary);
      }
      return const IconThemeData(color: AppColors.textSecondary);
    }),
  ),
  colorScheme: ColorScheme.fromSwatch().copyWith(
    primary: AppColors.primary,
    secondary: AppColors.card,
  ),
);
