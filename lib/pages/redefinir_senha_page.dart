import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class RedefinirSenhaPage extends StatefulWidget {
  final String token;

  const RedefinirSenhaPage({required this.token, super.key});

  @override
  State<RedefinirSenhaPage> createState() => _RedefinirSenhaPageState();
}

class _RedefinirSenhaPageState extends State<RedefinirSenhaPage> {
  final _senhaController = TextEditingController();
  final _confirmaSenhaController = TextEditingController();
  late final TextEditingController _tokenController;
  bool isLoading = false;
  bool senhaRedefinida = false;
  bool mostrarSenha1 = false;
  bool mostrarSenha2 = false;

  @override
  void initState() {
    super.initState();
    _tokenController = TextEditingController(text: widget.token);
  }

  @override
  void dispose() {
    _senhaController.dispose();
    _confirmaSenhaController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  bool _senhasIguais() {
    return _senhaController.text == _confirmaSenhaController.text;
  }

  bool _senhaValida() {
    return _senhaController.text.length >= 6;
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
                        'Redefinir Senha',
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
                    'Digite sua nova senha',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 32),
                  if (senhaRedefinida)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        border: Border.all(color: Colors.green),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Senha redefinida com sucesso!',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 16,
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
                          const SizedBox(height: 16),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                vertical: 16,
                                horizontal: 32,
                              ),
                            ),
                            onPressed: () {
                              Navigator.pushReplacementNamed(context, '/login');
                            },
                            child: const Text('Ir para Login'),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    // Campo de token manual (fallback quando deep link não funcionou)
                    if (widget.token.isEmpty) ...[
                      const Text(
                        'Cole o token recebido no email:',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _tokenController,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Token de recuperação',
                          prefixIcon: const Icon(
                            Icons.vpn_key,
                            color: Colors.amber,
                          ),
                          filled: true,
                          fillColor: Colors.grey[900],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          labelStyle: const TextStyle(color: Colors.white),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 20),
                    ],
                    TextFormField(
                      controller: _senhaController,
                      obscureText: !mostrarSenha1,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Nova Senha',
                        prefixIcon: const Icon(
                          Icons.lock,
                          color: Colors.deepPurple,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            mostrarSenha1
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Colors.deepPurple,
                          ),
                          onPressed: () {
                            setState(() => mostrarSenha1 = !mostrarSenha1);
                          },
                        ),
                        filled: true,
                        fillColor: Colors.grey[900],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        labelStyle: const TextStyle(color: Colors.white),
                        helperText: 'Mínimo 6 caracteres',
                        helperStyle: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _confirmaSenhaController,
                      obscureText: !mostrarSenha2,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Confirmar Senha',
                        prefixIcon: const Icon(
                          Icons.lock,
                          color: Colors.deepPurple,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            mostrarSenha2
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Colors.deepPurple,
                          ),
                          onPressed: () {
                            setState(() => mostrarSenha2 = !mostrarSenha2);
                          },
                        ),
                        filled: true,
                        fillColor: Colors.grey[900],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        labelStyle: const TextStyle(color: Colors.white),
                      ),
                      onChanged: (value) {
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 24),
                    if (!_senhasIguais() &&
                        _confirmaSenhaController.text.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.2),
                          border: Border.all(color: Colors.red),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'As senhas não coincidem',
                          style: TextStyle(color: Colors.red, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    const SizedBox(height: 12),
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
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              textStyle: const TextStyle(fontSize: 16),
                            ),
                            onPressed:
                                (_senhaValida() &&
                                    _senhasIguais() &&
                                    _tokenController.text.trim().isNotEmpty &&
                                    !isLoading)
                                ? () async {
                                    setState(() => isLoading = true);
                                    try {
                                      final success = await authService
                                          .resetPassword(
                                            '',
                                            _tokenController.text.trim(),
                                            _senhaController.text.trim(),
                                          );

                                      if (success) {
                                        setState(() => senhaRedefinida = true);
                                      } else {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Erro ao redefinir senha. Tente novamente.',
                                            ),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(content: Text(e.toString())),
                                      );
                                    } finally {
                                      setState(() => isLoading = false);
                                    }
                                  }
                                : null,
                            child: const Text('Redefinir Senha'),
                          ),
                    const SizedBox(height: 16),
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Voltar',
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
