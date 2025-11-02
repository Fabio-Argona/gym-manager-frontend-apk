import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  bool isLogin = true;
  bool isLoading = false;

  String nome = '';
  String email = '';
  String password = '';

  final cpfController = TextEditingController();
  final telefoneController = TextEditingController();
  final dataController = TextEditingController();

  final cpfMask = MaskTextInputFormatter(
    mask: '###.###.###-##',
    filter: {"#": RegExp(r'[0-9]')},
  );
  final telefoneMask = MaskTextInputFormatter(
    mask: '(##)#####-####',
    filter: {"#": RegExp(r'[0-9]')},
  );
  final dataMask = MaskTextInputFormatter(
    mask: '##/##/####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  String _formatarData(String data) {
    final partes = data.split('/');
    if (partes.length != 3) return '';
    return '${partes[2]}-${partes[1]}-${partes[0]}';
  }

  bool _emailValido(String email) {
    final regex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$');
    return regex.hasMatch(email);
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 🔳 Imagem de fundo
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
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    const SizedBox(height: 32),
                    const Text(
                      'Full Performance',
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isLogin ? "Bem-vindo de volta" : "Crie sua conta",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Text(
                      isLogin
                          ? "Acesse sua conta para continuar"
                          : "Preencha os dados abaixo",
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 32),

                    if (!isLogin) ...[
                      _buildInput(
                        "Nome",
                        Icons.person,
                        onChanged: (v) => nome = v.trim(),
                      ),
                      const SizedBox(height: 12),
                      _buildInput(
                        "CPF",
                        Icons.badge,
                        controller: cpfController,
                        inputFormatters: [cpfMask],
                        validator: (v) =>
                            v != null && v.length == 14 ? null : 'CPF inválido',
                      ),
                      const SizedBox(height: 12),
                      _buildInput(
                        "Telefone",
                        Icons.phone,
                        controller: telefoneController,
                        inputFormatters: [telefoneMask],
                        validator: (v) => v != null && v.length == 14
                            ? null
                            : 'Telefone inválido',
                      ),
                      const SizedBox(height: 12),
                      _buildInput(
                        "Data de Nascimento",
                        Icons.cake,
                        controller: dataController,
                        inputFormatters: [dataMask],
                        validator: (v) => v != null && v.length == 10
                            ? null
                            : 'Data inválida',
                      ),
                      const SizedBox(height: 12),
                    ],

                    _buildInput(
                      "Email",
                      Icons.email,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) => v != null && _emailValido(v)
                          ? null
                          : 'Email inválido',
                      onChanged: (v) => email = v.trim(),
                    ),
                    const SizedBox(height: 12),
                    _buildInput(
                      "Senha",
                      Icons.lock,
                      obscureText: true,
                      validator: (v) => v != null && v.length >= 6
                          ? null
                          : 'Mínimo 6 caracteres',
                      onChanged: (v) => password = v.trim(),
                    ),
                    const SizedBox(height: 8),

                    if (isLogin)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Funcionalidade de recuperação em construção",
                                ),
                              ),
                            );
                          },
                          child: const Text(
                            "Esqueci minha senha",
                            style: TextStyle(
                              color: Color.fromARGB(255, 144, 116, 219),
                            ),
                          ),
                        ),
                      ),

                    const SizedBox(height: 24),
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
                            onPressed: () async {
                              if (_formKey.currentState!.validate()) {
                                setState(() => isLoading = true);

                                try {
                                  bool success;

                                  if (isLogin) {
                                    success = await authService.login(
                                      email,
                                      password,
                                    );
                                  } else {
                                    final dataFormatada = _formatarData(
                                      dataController.text,
                                    );
                                    success = await authService.register({
                                      "nome": nome,
                                      "cpf": cpfController.text,
                                      "email": email,
                                      "telefone": telefoneController.text,
                                      "data_nascimento": dataFormatada,
                                      "login": email,
                                      "password": password,
                                    });
                                  }

                                  setState(() => isLoading = false);

                                  if (success) {
                                    final nomeSalvo = await authService
                                        .getNomeSalvo();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          isLogin
                                              ? 'Login realizado com sucesso!'
                                              : 'Cadastro realizado com sucesso!',
                                        ),
                                      ),
                                    );
                                    await Future.delayed(
                                      const Duration(seconds: 1),
                                    );
                                    Navigator.pushReplacementNamed(
                                      context,
                                      '/home',
                                      arguments: nomeSalvo ?? 'Usuário',
                                    );
                                  }
                                } catch (e) {
                                  setState(() => isLoading = false);
                                  // ignore: use_build_context_synchronously
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(e.toString())),
                                  );
                                }
                              }
                            },
                            child: Text(isLogin ? "Entrar" : "Cadastrar"),
                          ),
                    const SizedBox(height: 16),
                    Center(
                      child: TextButton(
                        onPressed: () => setState(() => isLogin = !isLogin),
                        child: Text(
                          isLogin
                              ? "Ainda não tem conta? Cadastre-se"
                              : "Já tem conta? Entrar",
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput(
    String label,
    IconData icon, {
    TextEditingController? controller,
    List<TextInputFormatter>? inputFormatters,
    TextInputType? keyboardType,
    bool obscureText = false,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      inputFormatters: inputFormatters,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.deepPurple),
        filled: true,
        fillColor: Colors.grey[900],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        labelStyle: const TextStyle(color: Colors.white),
      ),
      validator: validator,
      onChanged: onChanged,
    );
  }
}
