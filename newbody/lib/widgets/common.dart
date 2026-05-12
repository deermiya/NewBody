import 'dart:ui';
import 'package:flutter/material.dart';

// ============ 现代设计语言：NewBody Mint Fresh ============
class C {
  // 基础背景
  static const bg = Color(0xFFF7FAF9); // 极淡薄荷绿
  static const bgSurface = Colors.white;
  static const border = Color(0xFFE2E9E7);
  
  // 核心色调 (清新自然系)
  static const green = Color(0xFF2D6A4F);  // 森林深绿
  static const cyan = Color(0xFF52B788);   // 嫩芽绿
  static const accent = Color(0xFF74C69D); // 浅绿
  static const amber = Color(0xFFFFB347);
  static const rose = Color(0xFFFF6B6B);
  static const purple = Color(0xFF9B5DE5);
  
  // 文字颜色层级 (深绿灰色调)
  static const textPrimary = Color(0xFF1B4332);
  static const textSecondary = Color(0xFF40916C);
  static const textMuted = Color(0xFF95A5A6);
  static const textDim = Color(0xFFBDC3C7);

  // 清新渐变
  static const primaryGradient = LinearGradient(
    colors: [Color(0xFF52B788), Color(0xFF2D6A4F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const glassBorder = Color(0xFFE2E9E7);
  static const glassSurface = Color(0xFFFFFFFF);
}

// ============ 清新圆角卡片 ============
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? borderColor;
  final double? blur;

  const AppCard({super.key, required this.child, this.padding, this.borderColor, this.blur});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor ?? C.glassBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: C.green.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(20),
        child: child,
      ),
    );
  }
}

// ============ 自然渐变按钮 ============
class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final IconData? icon;

  const GradientButton({super.key, required this.text, required this.onTap, this.icon});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: C.primaryGradient,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: C.cyan.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[Icon(icon, size: 18, color: Colors.white), const SizedBox(width: 8)],
            Text(text, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }
}

// ============ 辅助函数 ============
String todayStr() {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}

String weekdayCN() {
  const days = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
  return days[DateTime.now().weekday - 1];
}

String nowTime() {
  final now = DateTime.now();
  return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
}
