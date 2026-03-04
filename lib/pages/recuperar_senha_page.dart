import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class RecuperarSenhaPage extends StatefulWidget {
  const RecuperarSenhaPage({super.key});

  @override
  State<RecuperarSenhaPage> createState() => _RecuperarSenhaPageState();
}

class _RecuperarSenhaPageState extends State<RecuperarSenhaPage> {
  final _emailController = TextEditingController();
  final _cpf6Controller = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmaSenhaController = TextEditingController();

  bool isLoading = false;
  bool senhaRedefinida = false;
  bool mostrarSenha = false;
  bool mostrarConfirma = false;

  @override
  void dispose() {
    _emailController.dispose();
    _cpf6Controller.dispose();
    _senhaController.dispose();
    _confirmaSenhaController.dispose();
    super.dispose();
  }

  bool get _formularioValido {
    final email = _emailController.text.trim();
    final cpf6 = _cpf6Controller.text.trim();
    final senha = _senhaController.text;
    final confirma = _confirmaSenhaController.text;
    final emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$');
    return emailRegex.hasMatch(email) &&
        cpf6.length == 6 &&
        senha.length >= 6 &&
        senha == confirma;
  }

  Future<void> _redefinir(AuthService authService) async {
    setState(() => isLoading = true);
    try {
      await authService.resetPassword(
        _emailController.text.trim(),
        _cpf6Controller.text.trim(),
        _senhaController.text.trim(),
      );
      setState(() => senhaRedefinida = true);
    } catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red[700]),
        );
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/Copilot_20251029_183912.png'),
                repeat: ImageRepeat.repeat,
                alignment: Alignment.topLeft,
                scale: 1.0,
              ),
            ),
          ),
          Container(color: Colors.black.withOpacity(0.3)),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: ListView(
                children: [
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Recuperar Senha',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Informe seu email, os 6 primeiros dígitos do CPF e a nova senha.',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 32),

                  if (senhaRedefinida)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.15),
                        border: Border.all(color: Colors.green),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 56,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Senha redefinida com sucesso!',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Você já pode fazer login com sua nova senha.',
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                vertical: 16,
                                horizontal: 40,
                              ),
                            ),
                            onPressed: () => Navigator.pushReplacementNamed(
                              context,
                              '/login',
                            ),
                            child: const Text('Ir para Login'),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    // EMAIL
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: Colors.white),
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: const Icon(
                          Icons.email,
                          color: Colors.deepPurple,
                        ),
                        filled: true,
                        fillColor: Colors.grey[900],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        labelStyle: const TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 6 PRIMEIROS DÍGITOS DO CPF
                    TextFormField(
                      controller: _cpf6Controller,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      style: const TextStyle(
                        color: Colors.white,
                        letterSpacing: 6,
                        fontSize: 18,
                      ),
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: '6 primeiros dígitos do CPF',
                        prefixIcon: const Icon(
                          Icons.badge,
                          color: Colors.deepPurple,
                        ),
                        helperText: 'Ex: CPF 123.456.789-00 → digite 123456',
                        helperStyle: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                        counterStyle: const TextStyle(color: Colors.grey),
                        filled: true,
                        fillColor: Colors.grey[900],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        labelStyle: const TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // NOVA SENHA
                    TextFormField(
                      controller: _senhaController,
                      obscureText: !mostrarSenha,
                      style: const TextStyle(color: Colors.white),
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: 'Nova Senha',
                        prefixIcon: const Icon(
                          Icons.lock,
                          color: Colors.deepPurple,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            mostrarSenha
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Colors.deepPurple,
                          ),
                          onPressed: () =>
                              setState(() => mostrarSenha = !mostrarSenha),
                        ),
                        helperText: 'Mínimo 6 caracteres',
                        helperStyle: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                        filled: true,
                        fillColor: Colors.grey[900],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        labelStyle: const TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // CONFIRMAR SENHA
                    TextFormField(
                      controller: _confirmaSenhaController,
                      obscureText: !mostrarConfirma,
                      style: const TextStyle(color: Colors.white),
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: 'Confirmar Nova Senha',
                        prefixIcon: const Icon(
                          Icons.lock_outline,
                          color: Colors.deepPurple,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            mostrarConfirma
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Colors.deepPurple,
                          ),
                          onPressed: () => setState(
                            () => mostrarConfirma = !mostrarConfirma,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.grey[900],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        labelStyle: const TextStyle(color: Colors.white),
                      ),
                    ),

                    if (_confirmaSenhaController.text.isNotEmpty &&
                        _senhaController.text !=
                            _confirmaSenhaController.text) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.15),
                          border: Border.all(color: Colors.red),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'As senhas não coincidem',
                          style: TextStyle(color: Colors.red, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],

                    const SizedBox(height: 28),

                    isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Colors.deepPurple,
                            ),
                          )
                        : ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: Colors.deepPurple
                                  .withOpacity(0.3),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              textStyle: const TextStyle(fontSize: 16),
                            ),
                            onPressed: _formularioValido
                                ? () => _redefinir(authService)
                                : null,
                            child: const Text('Redefinir Senha'),
                          ),

                    const SizedBox(height: 16),
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Voltar ao Login',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
