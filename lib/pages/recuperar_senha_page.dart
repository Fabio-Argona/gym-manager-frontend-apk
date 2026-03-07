import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../constants/app_theme.dart';

// ─── Design tokens ─────────────────────────────────────────────────────────────
const _bg1 = Color(0xFF0D0D1A);
const _bg2 = Color(0xFF1A1040);
const _card = Color(0xFF1C1B2E);
const _primary = Color(0xFF7C3AED);
const _accent = Color(0xFF06B6D4);
const _success = Color(0xFF10B981);
const _error = Color(0xFFEF4444);
const _inputBg = Color(0xFF252438);
const _border = Color(0xFF3A3857);
const _textHint = Color(0xFF8884A8);
const _textSub = Color(0xFFB0ADCC);

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

  void _snack(String message, {bool success = false}) {
    final color = success ? _success : _error;
    final icon = success
        ? Icons.check_circle_outline_rounded
        : Icons.error_outline_rounded;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
      if (mounted) _snack(msg);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Widget _buildInput(
    String label,
    IconData icon, {
    TextEditingController? controller,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    int? maxLength,
    String? helperText,
    bool obscure = false,
    Widget? suffix,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      inputFormatters: inputFormatters,
      maxLength: maxLength,
      onChanged: (_) => setState(() {}),
      style: TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        helperText: helperText,
        helperStyle: TextStyle(color: _textHint, fontSize: 12),
        counterStyle: TextStyle(color: _textHint, fontSize: 11),
        prefixIcon: Icon(icon, color: _primary, size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: _inputBg,
        labelStyle: TextStyle(color: _textHint, fontSize: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 16,
        ),
      ),
    );
  }

  Widget _buildSucesso() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _success.withOpacity(0.12),
            border: Border.all(color: _success.withOpacity(0.4)),
          ),
          child: const Icon(
            Icons.check_circle_outline_rounded,
            color: _success,
            size: 48,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Senha redefinida!',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        const Text(
          'Você já pode entrar com sua nova senha.',
          style: TextStyle(color: _textSub, fontSize: 14),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
            child: const Text('Ir para Login'),
          ),
        ),
      ],
    );
  }

  Widget _buildFormulario(AuthService authService) {
    final senhaDiferente =
        _confirmaSenhaController.text.isNotEmpty &&
        _senhaController.text != _confirmaSenhaController.text;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildInput(
          'Email',
          Icons.alternate_email_rounded,
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 14),
        _buildInput(
          '6 primeiros dígitos do CPF',
          Icons.badge_outlined,
          controller: _cpf6Controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          maxLength: 6,
          helperText: 'Ex: CPF 123.456.789-00 → digite 123456',
        ),
        const SizedBox(height: 14),
        _buildInput(
          'Nova Senha',
          Icons.lock_outline_rounded,
          controller: _senhaController,
          obscure: !mostrarSenha,
          helperText: 'Mínimo 6 caracteres',
          suffix: IconButton(
            icon: Icon(
              mostrarSenha
                  ? Icons.visibility_rounded
                  : Icons.visibility_off_rounded,
              color: _textHint,
              size: 20,
            ),
            onPressed: () => setState(() => mostrarSenha = !mostrarSenha),
          ),
        ),
        const SizedBox(height: 14),
        _buildInput(
          'Confirmar Nova Senha',
          Icons.lock_rounded,
          controller: _confirmaSenhaController,
          obscure: !mostrarConfirma,
          suffix: IconButton(
            icon: Icon(
              mostrarConfirma
                  ? Icons.visibility_rounded
                  : Icons.visibility_off_rounded,
              color: _textHint,
              size: 20,
            ),
            onPressed: () => setState(() => mostrarConfirma = !mostrarConfirma),
          ),
        ),
        if (senhaDiferente) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _error.withOpacity(0.1),
              border: Border.all(color: _error.withOpacity(0.4)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: const [
                Icon(Icons.warning_amber_rounded, color: _error, size: 16),
                SizedBox(width: 8),
                Text(
                  'As senhas não coincidem',
                  style: TextStyle(color: _error, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
        isLoading
            ? const Center(child: CircularProgressIndicator(color: _primary))
            : ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: _primary.withOpacity(0.3),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onPressed: _formularioValido
                    ? () => _redefinir(authService)
                    : null,
                child: const Text('Redefinir Senha'),
              ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _bg1,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_bg1, _bg2, Color(0xFF0E1628)],
              stops: [0.0, 0.55, 1.0],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Botão voltar ────────────────────────────────────────
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _card,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _border),
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // ── Ícone + título ──────────────────────────────────────
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            _primary.withOpacity(0.25),
                            _accent.withOpacity(0.15),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(
                          color: _primary.withOpacity(0.4),
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.lock_reset_rounded,
                        color: _primary,
                        size: 36,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Recuperar Senha',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Informe seu email, os 6 primeiros dígitos\ndo CPF e escolha uma nova senha.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: _textSub,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── Card principal ──────────────────────────────────────
                  Container(
                    decoration: BoxDecoration(
                      color: _card,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: _border.withOpacity(0.6)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.35),
                          blurRadius: 32,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(24),
                    child: senhaRedefinida
                        ? _buildSucesso()
                        : _buildFormulario(authService),
                  ),

                  const SizedBox(height: 20),

                  if (!senhaRedefinida)
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Voltar ao Login',
                          style: TextStyle(color: _textHint, fontSize: 13),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
