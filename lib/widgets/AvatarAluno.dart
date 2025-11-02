import 'package:flutter/material.dart';

class AvatarAluno extends StatelessWidget {
  final String nome;
  final String? imagemUrl;
  final double tamanho;
  final VoidCallback? onTap;

  const AvatarAluno({
    super.key,
    required this.nome,
    required this.imagemUrl,
    this.tamanho = 80,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        radius: tamanho / 2,
        backgroundColor: Colors.deepPurple,
        child: imagemUrl == null
            ? Text(
                nome[0].toUpperCase(),
                style: TextStyle(
                  fontSize: tamanho / 2.5,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              )
            : ClipOval(
                child: Image.network(
                  imagemUrl!,
                  width: tamanho,
                  height: tamanho,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return SizedBox(
                      width: tamanho,
                      height: tamanho,
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Text(
                        nome[0].toUpperCase(),
                        style: TextStyle(
                          fontSize: tamanho / 2.5,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }
}
