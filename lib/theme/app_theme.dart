import 'package:flutter/material.dart';
import '../models/quest.dart';

abstract class AppColors {
  static const bg       = Color(0xFF181030);
  static const bgDeep   = Color(0xFF0D0820);
  static const surface  = Color(0xFF241848);
  static const surface2 = Color(0xFF2E1D5A);
  static const muted    = Color(0xFFB3A8D9);
  static const border   = Color(0x1AFFFFFF);

  static const pink    = Color(0xFFFF4D8D);
  static const hotPink = Color(0xFFFF2E7D);
  static const violet  = Color(0xFF9D5CFF);
  static const blue    = Color(0xFF4F9BFF);
  static const cyan    = Color(0xFF3EDCFF);
  static const yellow  = Color(0xFFFFD23F);
  static const green   = Color(0xFF3DF09B);
  static const red     = Color(0xFFFF5E6C);
}

abstract class AppTheme {
  static ThemeData get theme => ThemeData(
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.pink,
      secondary: AppColors.violet,
      surface: AppColors.surface,
      error: AppColors.red,
    ),
    useMaterial3: true,
  );
}

extension QuestCategoryVisual on QuestCategory {
  String get glyph => switch (this) {
    QuestCategory.cleaning  => '🧽',
    QuestCategory.groceries => '🥦',
    QuestCategory.bills     => '💸',
    QuestCategory.upgrades  => '🛠️',
  };

  Color get color1 => switch (this) {
    QuestCategory.cleaning  => AppColors.cyan,
    QuestCategory.groceries => AppColors.green,
    QuestCategory.bills     => AppColors.yellow,
    QuestCategory.upgrades  => AppColors.pink,
  };

  Color get color2 => switch (this) {
    QuestCategory.cleaning  => AppColors.blue,
    QuestCategory.groceries => const Color(0xFF22C563),
    QuestCategory.bills     => const Color(0xFFF59E0B),
    QuestCategory.upgrades  => AppColors.hotPink,
  };

  String get roomLabel => switch (this) {
    QuestCategory.cleaning  => 'THE DISHWASHER',
    QuestCategory.groceries => 'THE FRIDGE',
    QuestCategory.bills     => 'THE DESK',
    QuestCategory.upgrades  => 'THE WORKSHOP',
  };

  Color get darkBg => switch (this) {
    QuestCategory.cleaning  => const Color(0xFF0F7C99),
    QuestCategory.groceries => const Color(0xFF16894A),
    QuestCategory.bills     => const Color(0xFFA07000),
    QuestCategory.upgrades  => const Color(0xFFA8125C),
  };
}
