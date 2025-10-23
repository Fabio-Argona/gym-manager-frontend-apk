import 'package:flutter/material.dart';

class TreinosPage extends StatelessWidget {
  final String nome;

  const TreinosPage({super.key, required this.nome});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bem-vindo, $nome à FullPerformance',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          const Text('Seu próximo treino', style: TextStyle(fontSize: 18, color: Colors.white)),
          const SizedBox(height: 12),
          Card(
            color: Colors.grey[900],
            child: ListTile(
              leading: const Icon(Icons.timer, color: Colors.purple),
              title: const Text('Treino ABC - Peito e Tríceps', style: TextStyle(color: Colors.white)),
              subtitle: const Text('45 minutos • 6 exercícios', style: TextStyle(color: Colors.grey)),
              trailing: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                onPressed: () {},
                child: const Text('Iniciar'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
