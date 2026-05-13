import 'package:flutter/material.dart';
import 'common.dart';

void showDailyGreetingDialog(
  BuildContext context, {
  required String message,
  required double totalLostJin,
  required int daysSinceStart,
}) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'greeting',
    barrierColor: Colors.black38,
    transitionDuration: const Duration(milliseconds: 400),
    pageBuilder: (_, __, ___) => const SizedBox(),
    transitionBuilder: (ctx, anim, secAnim, child) {
      final curved = CurvedAnimation(
        parent: anim,
        curve: Curves.easeOutCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0, 0.3),
            end: Offset.zero,
          ).animate(curved),
          child: _GreetingDialogContent(
            message: message,
            totalLostJin: totalLostJin,
            daysSinceStart: daysSinceStart,
          ),
        ),
      );
    },
  );
}

class _GreetingDialogContent extends StatelessWidget {
  final String message;
  final double totalLostJin;
  final int daysSinceStart;

  const _GreetingDialogContent({
    required this.message,
    required this.totalLostJin,
    required this.daysSinceStart,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Center(
      child: Container(
        width: screenWidth * 0.85,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: C.cyan.withOpacity(0.15), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: C.green.withOpacity(0.08),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top gradient accent bar
            Container(
              height: 4,
              decoration: BoxDecoration(
                gradient: C.primaryGradient,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: C.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.auto_awesome_rounded,
                          color: C.green,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'AI 今日寄语',
                            style: TextStyle(
                              color: C.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'NewBody Mint',
                            style: TextStyle(
                              color: C.textMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Message
                  Text(
                    '"$message"',
                    style: const TextStyle(
                      color: C.textSecondary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      height: 1.7,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Divider
                  Container(
                    height: 1,
                    color: C.border,
                  ),
                  const SizedBox(height: 16),
                  // Context strip
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.trending_down_rounded,
                        size: 14,
                        color: C.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '已减 ${totalLostJin.toStringAsFixed(1)} 斤',
                        style: const TextStyle(
                          color: C.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 3,
                        height: 3,
                        decoration: BoxDecoration(
                          color: C.textMuted,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 13,
                        color: C.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '第 $daysSinceStart 天',
                        style: const TextStyle(
                          color: C.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Close button
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: C.bg,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.wb_sunny_rounded,
                            color: C.green,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            '开始新的一天',
                            style: TextStyle(
                              color: C.green,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
