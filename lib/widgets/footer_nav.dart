import 'package:flutter/material.dart';
import '../constants/app_theme.dart';

class FooterNav extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;
  final VoidCallback onAddGrupo;
  final VoidCallback onLogout;

  const FooterNav({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
    required this.onAddGrupo,
    required this.onLogout,
  });

  @override
    Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [c.bg2, c.card],
        ),
        border: Border(
          top: BorderSide(color: c.border.withOpacity(0.8), width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: [
              _NavItem(
                icon: Icons.fitness_center_rounded,
                label: 'Treinos',
                selected: selectedIndex == 0,
                onTap: () => onItemTapped(0),
              ),
              _NavItem(
                icon: Icons.bar_chart_rounded,
                label: 'Progresso',
                selected: selectedIndex == 1,
                onTap: () => onItemTapped(1),
              ),
              Container(width: 1, height: 36, color: c.border),
              _NavItem(
                icon: Icons.logout_rounded,
                label: 'Sair',
                selected: false,
                color: c.error,
                onTap: onLogout,
                dangerStyle: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final Color? color;
  final bool dangerStyle;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
    this.dangerStyle = false,
  });

  @override
    Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final activeColor = color ?? (selected ? c.primary : c.textHint);

    return Expanded(
      child: InkWell(
        onTap: onTap,
        splashColor: activeColor.withOpacity(0.12),
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: selected
                    ? c.primary.withOpacity(0.15)
                    : dangerStyle
                    ? c.error.withOpacity(0.08)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, color: activeColor, size: 21),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: activeColor,
                fontSize: 11,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
