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
    QuestCategory.livingAreas  => '🧽',
    QuestCategory.kitchen   => '🍳',
    QuestCategory.admin     => '💸',
    QuestCategory.laundry   => '👕',
    QuestCategory.bathroom  => '🛁',
    QuestCategory.bedroom   => '🛏️',
  };

  Color get color1 => switch (this) {
    QuestCategory.livingAreas  => AppColors.cyan,
    QuestCategory.kitchen   => AppColors.green,
    QuestCategory.admin     => AppColors.yellow,
    QuestCategory.laundry   => const Color(0xFFD9A8FF),
    QuestCategory.bathroom  => const Color(0xFF3EDCFF),    // teal — bathroom tiles + water
    QuestCategory.bedroom   => const Color(0xFFC98AFF),    // soft violet — bed + duvet
  };

  Color get color2 => switch (this) {
    QuestCategory.livingAreas  => AppColors.blue,
    QuestCategory.kitchen   => const Color(0xFF22C563),
    QuestCategory.admin     => const Color(0xFFF59E0B),
    QuestCategory.laundry   => const Color(0xFF9D5CFF),
    QuestCategory.bathroom  => const Color(0xFF2A80A8),    // deeper teal
    QuestCategory.bedroom   => const Color(0xFF7A4FBF),    // deeper violet
  };

  String get roomLabel => switch (this) {
    QuestCategory.livingAreas  => 'THE BROOM',
    QuestCategory.kitchen   => 'THE KITCHEN',
    QuestCategory.admin     => 'THE DESK',
    QuestCategory.laundry   => 'THE LAUNDRY',
    QuestCategory.bathroom  => 'THE BATHROOM',
    QuestCategory.bedroom   => 'THE BEDROOM',
  };

  Color get darkBg => switch (this) {
    QuestCategory.livingAreas  => const Color(0xFF0F7C99),
    QuestCategory.kitchen   => const Color(0xFF16894A),
    QuestCategory.admin     => const Color(0xFFA07000),
    QuestCategory.laundry   => const Color(0xFF5A2080),
    QuestCategory.bathroom  => const Color(0xFF1A5670),
    QuestCategory.bedroom   => const Color(0xFF3A1F66),
  };
}
