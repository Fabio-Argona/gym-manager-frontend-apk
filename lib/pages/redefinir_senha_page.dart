import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class RedefinirSenhaPage extends StatefulWidget {
  const RedefinirSenhaPage({super.key});

  @override
  State<RedefinirSenhaPage> createState() => _RedefinirSenhaPageState();
}

class _RedefinirSenhaPageState extends State<RedefinirSenhaPage> {
  final _formKey = GlobalKey<FormState>();
  final tokenController = TextEditingController();
  final senhaController = TextEditingController();
  bool isLoading = false;

  Future<void> _redefinirSenha() async {
    setState(() => isLoading = true);

    final response = await http.post(
      Uri.parse('http://18.222.56.92:8080/auth/resetar-senha'),
      headers: {'Content-Type': 'application/json'},
      body:
          '''
      {
        "token": "${tokenController.text.trim()}",
        "novaSenha": "${senhaController.text.trim()}"
      }
      ''',
    );

    setState(() => isLoading = false);

    final sucesso = response.statusCode >= 200 && response.statusCode < 300;

    print('Status: ${response.statusCode}');
    print('Body: ${response.body}');

    if (sucesso) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Senha redefinida com sucesso!')),
      );
      await Future.delayed(const Duration(seconds: 2));
      Navigator.pushReplacementNamed(context, '/login');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao redefinir senha: ${response.body}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Redefinir Senha'),
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 32),
              const Text(
                'Insira o token recebido e sua nova senha',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: tokenController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Token',
                  prefixIcon: Icon(Icons.vpn_key, color: Colors.deepPurple),
                  filled: true,
                  fillColor: Colors.grey,
                  border: OutlineInputBorder(),
                  labelStyle: TextStyle(color: Colors.white),
                ),
                validator: (value) => value != null && value.length > 10
                    ? null
                    : 'Token inválido',
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: senhaController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Nova senha',
                  prefixIcon: Icon(Icons.lock, color: Colors.deepPurple),
                  filled: true,
                  fillColor: Colors.grey,
                  border: OutlineInputBorder(),
                  labelStyle: TextStyle(color: Colors.white),
                ),
                validator: (value) => value != null && value.length >= 6
                    ? null
                    : 'Mínimo 6 caracteres',
              ),
              const SizedBox(height: 24),
              isLoading
                  ? const CircularProgressIndicator(color: Colors.deepPurple)
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          _redefinirSenha();
                        }
                      },
                      child: const Text('Redefinir senha'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
