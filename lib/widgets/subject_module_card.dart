import 'package:flutter/material.dart';

class SubjectModuleCard extends StatelessWidget {
  final String name;
  final IconData iconData;
  final Color color;
  final VoidCallback onTap;

  const SubjectModuleCard({
    super.key,
    required this.name,
    required this.iconData,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        color: color.withAlpha((255 * 0.1).round()),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: color, width: 1),
        ),
        child: Container(
          width: 120,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(iconData, size: 30, color: color),
              const Spacer(),
              Text(
                name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
