import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool isLogin = true;
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;

  String email = '';
  String password = '';
  String nome = '';

  final cpfController = TextEditingController();
  final telefoneController = TextEditingController();
  final dataController = TextEditingController();

  final cpfMask = MaskTextInputFormatter(
    mask: '###.###.###-##',
    filter: { "#": RegExp(r'[0-9]') },
  );@override
  void setState(VoidCallback fn) {

    super.setState(fn);
  }

  final telefoneMask = MaskTextInputFormatter(
    mask: '(##)#####-####',
    filter: { "#": RegExp(r'[0-9]') },
  );

  final dataMask = MaskTextInputFormatter(
    mask: '##/##/####',
    filter: { "#": RegExp(r'[0-9]') },
  );

  String _formatarData(String data) {
    try {
      final partes = data.split('/');
      if (partes.length != 3) return '';
      return '${partes[2]}-${partes[1]}-${partes[0]}'; // yyyy-MM-dd
    } catch (_) {
      return '';
    }
  }

  bool _emailValido(String email) {
    final regex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$');
    return regex.hasMatch(email);
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(title: const Text("Full Performance")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text(
                isLogin ? "Entrar" : "Cadastrar",
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 16),

              if (!isLogin) ...[
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Nome'),
                  onChanged: (value) => nome = value.trim(),
                ),
                TextFormField(
                  controller: cpfController,
                  inputFormatters: [cpfMask],
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'CPF',
                    hintText: '999.999.999-99',
                  ),
                  validator: (value) =>
                      value != null && value.length == 14 ? null : 'CPF inválido',
                ),
                TextFormField(
                  controller: telefoneController,
                  inputFormatters: [telefoneMask],
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Telefone',
                    hintText: '(99)99999-9999',
                  ),
                  validator: (value) =>
                      value != null && value.length == 14 ? null : 'Telefone inválido',
                ),
                TextFormField(
                  controller: dataController,
                  inputFormatters: [dataMask],
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Data de Nascimento',
                    hintText: 'dd/mm/aaaa',
                  ),
                  validator: (value) =>
                      value != null && value.length == 10 ? null : 'Data inválida',
                ),
              ],

              TextFormField(
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) =>
                    value != null && _emailValido(value) ? null : 'Email inválido',
                onChanged: (value) => email = value.trim(),
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Senha'),
                obscureText: true,
                validator: (value) => value != null && value.length >= 6
                    ? null
                    : 'Mínimo 6 caracteres',
                onChanged: (value) => password = value.trim(),
              ),
              const SizedBox(height: 16),

              isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          setState(() => isLoading = true);
                          bool success;

                          if (isLogin) {
                            success = await authService.login(email, password);
                          } else {
                            final dataFormatada = _formatarData(dataController.text);
                            success = await authService.register({
                              "nome": nome,
                              "cpf": cpfController.text,
                              "email": email,
                              "telefone": telefoneController.text,
                              "dataNascimento": dataFormatada,
                              "login": email,
                              "password": password,
                            });
                          }

                          setState(() => isLoading = false);

                          if (success) {
                            Navigator.pushReplacementNamed(context, '/home');
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Erro ao autenticar")),
                            );
                          }
                        }
                      },
                      child: Text(isLogin ? "Entrar" : "Cadastrar"),
                    ),
              TextButton(
                onPressed: () => setState(() => isLogin = !isLogin),
                child: Text(
                  isLogin
                      ? "Ainda não tem conta? Cadastre-se"
                      : "Já tem conta? Entrar",
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
