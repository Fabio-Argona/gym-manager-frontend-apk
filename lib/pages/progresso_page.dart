import 'package:flutter/material.dart';

class ProgressoPage extends StatelessWidget {
  const ProgressoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Seu progresso', style: TextStyle(fontSize: 18, color: Colors.white)),
          const SizedBox(height: 12),
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text('📊 Gráfico de evolução aqui', style: TextStyle(color: Colors.grey)),
            ),
          ),
        ],
      ),
    );
  }
}
