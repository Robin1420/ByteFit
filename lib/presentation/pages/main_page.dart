import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import 'add_meal_page.dart';
import 'ai_assistant_page.dart';
import 'dashboard_page.dart';
import 'settings_page.dart';
import 'workout_routines_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const DashboardPage(),
    const AddMealPage(),
    const AiAssistantPage(),
    const WorkoutRoutinesPage(),
    const SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const primaryColor = Color(0xFF0080F5);

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        height: 70,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, -1),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(0, Icons.analytics_outlined, Icons.analytics),
                _buildNavItem(1, Icons.restaurant_outlined, Icons.restaurant),
                _buildNavItem(2, Icons.smart_toy_outlined, Icons.smart_toy,
                    isCenter: true),
                _buildNavItem(
                    3, Icons.fitness_center_outlined, Icons.fitness_center),
                _buildNavItem(4, Icons.settings_outlined, Icons.settings),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData iconOutlined, IconData iconFilled,
      {bool isCenter = false}) {
    final isSelected = _currentIndex == index;
    const primaryColor = Color(0xFF0080F5);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final iconWidget = Icon(
      isSelected ? iconFilled : iconOutlined,
      color:
          isSelected ? primaryColor : (isDark ? Colors.grey[400] : Colors.grey),
      size: isCenter ? 28 : 24,
    );

    if (isCenter) {
      final centerChild = ClipOval(
        child: Image.asset(
          'assets/icons/icon2.png',
          width: 56,
          height: 56,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => iconWidget,
        ),
      );
      return GestureDetector(
        onTap: () {
          setState(() {
            _currentIndex = index;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: isSelected
                ? primaryColor.withOpacity(0.14)
                : (isDark ? const Color(0xFF2A2A2A) : Colors.grey[200]),
            shape: BoxShape.circle,
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Center(child: centerChild),
        ),
      );
    }

    return IconButton(
      onPressed: () {
        setState(() {
          _currentIndex = index;
        });
      },
      icon: iconWidget,
      splashRadius: 26,
    );
  }
}
