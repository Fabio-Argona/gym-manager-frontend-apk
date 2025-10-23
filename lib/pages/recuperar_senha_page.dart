import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class RecuperarSenhaPage extends StatefulWidget {
  const RecuperarSenhaPage({super.key});

  @override
  State<RecuperarSenhaPage> createState() => _RecuperarSenhaPageState();
}

class _RecuperarSenhaPageState extends State<RecuperarSenhaPage> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  bool isLoading = false;
  bool enviado = false;

  bool _emailValido(String email) {
    final regex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$');
    return regex.hasMatch(email);
  }

  Future<void> _enviarRecuperacao() async {
    setState(() => isLoading = true);

    final response = await http.post(
      Uri.parse('https://gym-manager-java.onrender.com/auth/recuperar-senha'),
      headers: {'Content-Type': 'application/json'},
      body: '{"email": "${emailController.text.trim()}"}',
    );

    setState(() {
      isLoading = false;
      enviado = response.statusCode == 200;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(enviado
            ? 'Email de recuperação enviado!'
            : 'Erro ao enviar recuperação'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Recuperar Senha'),
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
                'Digite seu email para recuperar a senha',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email, color: Colors.deepPurple),
                  filled: true,
                  fillColor: Colors.grey,
                  border: OutlineInputBorder(),
                  labelStyle: TextStyle(color: Colors.white),
                ),
                validator: (value) => value != null && _emailValido(value)
                    ? null
                    : 'Email inválido',
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
                          _enviarRecuperacao();
                        }
                      },
                      child: const Text('Enviar recuperação'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
