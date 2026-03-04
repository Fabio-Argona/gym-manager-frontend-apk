import 'package:flutter/material.dart';

// ─── Design tokens ────────────────────────────────────────────────────────────
const _bg2 = Color(0xFF1A1040);
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
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_bg2, _card],
        ),
        border: Border(
          top: BorderSide(color: _border.withOpacity(0.8), width: 1),
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
              Container(width: 1, height: 36, color: _border),
              _NavItem(
                icon: Icons.logout_rounded,
                label: 'Sair',
                selected: false,
                color: _error,
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
    final activeColor = color ?? (selected ? _primary : _textHint);

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
                    ? _primary.withOpacity(0.15)
                    : dangerStyle
                    ? _error.withOpacity(0.08)
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
