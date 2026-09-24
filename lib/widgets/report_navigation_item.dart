import 'package:flutter/material.dart';
import '../screens/report_generation_screen.dart';

class ReportNavigationItem extends StatelessWidget {
  const ReportNavigationItem({super.key, this.selected = false, this.onTap});
  final bool selected;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    child: Material(
      color: selected ? Colors.white : Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        leading: Image.asset(
          'assets/images/report_generation.png',
          width: 23,
          height: 23,
          color: const Color(0xFF4D2F18),
        ),
        title: const Text(
          'Report Generation',
          style: TextStyle(
            color: Color(0xFF4D2F18),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        onTap:
            onTap ??
            () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const ReportGenerationScreen(),
                ),
              );
            },
      ),
    ),
  );
}
