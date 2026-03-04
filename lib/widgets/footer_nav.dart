import 'package:flutter/material.dart';

// ─── Design tokens ────────────────────────────────────────────────────────────
const _card = Color(0xFF1C1B2E);
const _primary = Color(0xFF7C3AED);
const _accent = Color(0xFF06B6D4);
const _error = Color(0xFFEF4444);
const _border = Color(0xFF3A3857);
const _textHint = Color(0xFF8884A8);

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
    return Container(
      decoration: const BoxDecoration(
        color: _card,
        border: Border(top: BorderSide(color: _border, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
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
              _NavItem(
                icon: Icons.logout_rounded,
                label: 'Sair',
                selected: false,
                color: _error,
                onTap: onLogout,
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
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? (selected ? _primary : _textHint);

    return Expanded(
      child: InkWell(
        onTap: onTap,
        splashColor: activeColor.withOpacity(0.1),
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: activeColor, size: 22),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: activeColor,
                fontSize: 11,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            const SizedBox(height: 2),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: selected ? 18 : 0,
              height: 2,
              decoration: BoxDecoration(
                color: _accent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
