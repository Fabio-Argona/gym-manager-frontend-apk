import 'package:flutter/material.dart';

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
    return BottomAppBar(
      color: Colors.black,
      elevation: 8,
      shape: const CircularNotchedRectangle(),
      child: Row(
        children: [
          Expanded(
            child: IconButton(
              icon: Icon(
                Icons.fitness_center,
                color: selectedIndex == 0 ? Colors.purple : Colors.grey,
              ),
              onPressed: () => onItemTapped(0),
            ),
          ),
          Expanded(
            child: IconButton(
              icon: Icon(
                Icons.bar_chart,
                color: selectedIndex == 1 ? Colors.purple : Colors.grey,
              ),
              onPressed: () => onItemTapped(1),
            ),
          ),
          Expanded(
            child: IconButton(
              icon: Icon(
                Icons.person,
                color: selectedIndex == 2 ? Colors.purple : Colors.grey,
              ),
              onPressed: () => onItemTapped(2),
            ),
          ),
          if (selectedIndex == 0)
            Expanded(
              child: IconButton(
                icon: const Icon(Icons.add, color: Colors.greenAccent),
                tooltip: 'Adicionar grupo',
                onPressed: onAddGrupo,
              ),
            ),
          Expanded(
            child: IconButton(
              icon: const Icon(Icons.logout, color: Colors.redAccent),
              tooltip: 'Sair',
              onPressed: onLogout,
            ),
          ),
        ],
      ),
    );
  }
}
