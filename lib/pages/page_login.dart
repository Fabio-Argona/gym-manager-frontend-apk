import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../services/auth_service.dart';
import 'recuperar_senha_page.dart';
import '../constants/app_theme.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  late AnimationController _titleController;
  late AnimationController _subtitleController;

  final _formKey = GlobalKey<FormState>();
  bool isLogin = true;
  bool isLoading = false;
  bool _biometriaDisponivel = false;
  bool _showPassword = false;

  @override
  void initState() {
    super.initState();
    _titleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..forward();
    _subtitleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (mounted) _subtitleController.forward();
    });
    _verificarBiometria();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    super.dispose();
  }

  Future<void> _verificarBiometria() async {
    if (kIsWeb) return;
    final authService = Provider.of<AuthService>(context, listen: false);
    final disponivel = await authService.isBiometricsAvailable();
    if (mounted) setState(() => _biometriaDisponivel = disponivel);
  }

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

  bool _emailValido(String v) =>
      RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$').hasMatch(v);

  // â”€â”€â”€ Snackbar padronizado â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  void _snack(String message, {bool success = false, bool warning = false}) {
    final c = AppColors.of(context);
    final color = success
        ? c.success
        : (warning ? Colors.orange[700]! : c.error);
    final icon = success
        ? Icons.check_circle_outline_rounded
        : (warning ? Icons.warning_amber_rounded : Icons.error_outline_rounded);
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

  // â”€â”€â”€ Build â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final authService = Provider.of<AuthService>(context, listen: false);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: c.bg1,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [c.bg1, c.bg2, c.bg3],
              stops: [0.0, 0.55, 1.0],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // â”€â”€ Logo / Branding â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                      _buildBranding(),
                      const SizedBox(height: 36),

                      // â”€â”€ Card principal â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                      _buildCard(authService),

                      const SizedBox(height: 20),

                      // â”€â”€ Alternar Login / Cadastro â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                      _buildToggle(),
                      const SizedBox(height: 32),

                      _buildCredits(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // â”€â”€â”€ Branding â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildBranding() {
    const title = 'APEX Iron Gym';
    const n = title.length;

    return AnimatedBuilder(
      animation: _titleController,
      builder: (context, _) {
        final letterWidgets = List.generate(n, (i) {
          final c = AppColors.of(context);
          final start = i / n * 0.70;
          final end = (start + 0.30).clamp(0.0, 1.0);
          final fadeEnd = (start + 0.18).clamp(0.0, 1.0);

          final slideAnim =
              Tween<Offset>(
                begin: const Offset(0, -1.8),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(
                  parent: _titleController,
                  curve: Interval(start, end, curve: Curves.elasticOut),
                ),
              );

          final fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(
              parent: _titleController,
              curve: Interval(start, fadeEnd, curve: Curves.easeIn),
            ),
          );

          return FadeTransition(
            opacity: fadeAnim,
            child: SlideTransition(
              position: slideAnim,
              child: Text(
                title[i],
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: c.primary,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          );
        });

        return Column(
          children: [
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: letterWidgets,
            ),
            const SizedBox(height: 4),
            AnimatedBuilder(
              animation: _subtitleController,
              builder: (context, _) {
                final c = AppColors.of(context);
                final slideAnim =
                    Tween<Offset>(
                      begin: const Offset(2.0, 0),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: _subtitleController,
                        curve: const Interval(
                          0.0,
                          0.55,
                          curve: Curves.easeOutCubic,
                        ),
                      ),
                    );

                final scaleAnim =
                    TweenSequence<double>([
                      TweenSequenceItem(
                        tween: Tween(
                          begin: 1.0,
                          end: 1.28,
                        ).chain(CurveTween(curve: Curves.easeOut)),
                        weight: 40,
                      ),
                      TweenSequenceItem(
                        tween: Tween(
                          begin: 1.28,
                          end: 1.0,
                        ).chain(CurveTween(curve: Curves.easeInOut)),
                        weight: 60,
                      ),
                    ]).animate(
                      CurvedAnimation(
                        parent: _subtitleController,
                        curve: const Interval(0.50, 1.0),
                      ),
                    );

                return ClipRect(
                  child: SlideTransition(
                    position: slideAnim,
                    child: ScaleTransition(
                      scale: scaleAnim,
                      child: Text(
                        'Forje seu limite.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          color: c.textHint,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  // â”€â”€â”€ Card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildCard(AuthService authService) {
    final c = AppColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: c.border.withOpacity(0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Campos de cadastro
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: isLogin
                ? const SizedBox.shrink()
                : Column(
                    children: [
                      _buildInput(
                        'Nome completo',
                        Icons.person_outline_rounded,
                        textCapitalization: TextCapitalization.words,
                        onChanged: (v) => nome = v.trim(),
                      ),
                      const SizedBox(height: 14),
                      _buildInput(
                        'CPF',
                        Icons.badge_outlined,
                        controller: cpfController,
                        inputFormatters: [cpfMask],
                        validator: (v) => v != null && v.length == 14
                            ? null
                            : 'CPF inv\u00e1lido',
                      ),
                      const SizedBox(height: 14),
                      _buildInput(
                        'Telefone',
                        Icons.phone_outlined,
                        controller: telefoneController,
                        inputFormatters: [telefoneMask],
                        validator: (v) => v != null && v.length == 14
                            ? null
                            : 'Telefone inv\u00e1lido',
                      ),
                      const SizedBox(height: 14),
                      _buildInput(
                        'Data de Nascimento',
                        Icons.cake_outlined,
                        controller: dataController,
                        inputFormatters: [dataMask],
                        validator: (v) => v != null && v.length == 10
                            ? null
                            : 'Data inv\u00e1lida',
                      ),
                      const SizedBox(height: 14),
                    ],
                  ),
          ),

          // Email
          _buildInput(
            'Email',
            Icons.alternate_email_rounded,
            keyboardType: TextInputType.emailAddress,
            validator: (v) =>
                v != null && _emailValido(v) ? null : 'Email inv\u00e1lido',
            onChanged: (v) => email = v.trim(),
          ),
          const SizedBox(height: 14),

          // Senha
          _buildPasswordInput(),

          // Esqueci a senha
          if (isLogin) ...[
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 6,
                  ),
                ),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RecuperarSenhaPage()),
                ),
                child: Text(
                  'Esqueci minha senha',
                  style: TextStyle(
                    color: c.accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ] else
            const SizedBox(height: 12),

          const SizedBox(height: 8),

          // BotÃ£o biometria
          if (isLogin && _biometriaDisponivel) ...[
            _buildBiometriaButton(authService),
            const SizedBox(height: 12),
          ],

          // BotÃ£o principal
          _buildPrimaryButton(authService),
        ],
      ),
    );
  }

  // â”€â”€â”€ Biometria button â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildBiometriaButton(AuthService authService) {
    final c = AppColors.of(context);
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: c.accent,
        side: BorderSide(color: c.border, width: 1.2),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      onPressed: isLoading
          ? null
          : () async {
              setState(() => isLoading = true);
              try {
                final ok = await authService.authenticateWithBiometrics();
                if (ok) {
                  _snack(
                    'Autentica\u00e7\u00e3o biom\u00e9trica realizada!',
                    success: true,
                  );
                  await Future.delayed(const Duration(milliseconds: 800));
                  final nome = await authService.getNomeSalvo();
                  if (mounted) {
                    Navigator.pushReplacementNamed(
                      context,
                      '/home',
                      arguments: nome ?? 'Usu\u00e1rio',
                    );
                  }
                } else {
                  _snack('Falha na autentica\u00e7\u00e3o biom\u00e9trica');
                }
              } catch (e) {
                _snack(e.toString().replaceAll('Exception: ', ''));
              } finally {
                if (mounted) setState(() => isLoading = false);
              }
            },
      icon: const Icon(Icons.fingerprint_rounded, size: 20),
      label: const Text(
        'Usar Biometria',
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    );
  }

  // â”€â”€â”€ Primary button â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildPrimaryButton(AuthService authService) {
    final c = AppColors.of(context);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: isLoading
          ? SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                color: c.accent,
                strokeWidth: 2.5,
              ),
            )
          : OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: c.accent,
                side: BorderSide(color: c.border, width: 1.2),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              onPressed: () => _submit(authService),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 340) {
                    return const Text('Entrar');
                  }
                  return Text(isLogin ? 'Entrar' : '  Criar conta  ');
                },
              ),
            ),
    );
  }

  // â”€â”€â”€ Toggle login/cadastro â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildToggle() {
    final c = AppColors.of(context);
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          isLogin ? 'Ainda n\u00e3o tem conta?' : 'J\u00e1 tem uma conta?',
          style: TextStyle(color: c.textHint, fontSize: 14),
        ),
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: c.accent,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            textStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          onPressed: () {
            setState(() => isLogin = !isLogin);
          },
          child: Text(isLogin ? 'Criar conta' : 'Entrar'),
        ),
      ],
    );
  } // <-- Adicionado fechamento de função aqui

  // ─── Input genérico ────────────────────────────────────────────────────────────
  Widget _buildInput(
    String label,
    IconData icon, {
    TextEditingController? controller,
    List<TextInputFormatter>? inputFormatters,
    TextInputType? keyboardType,
    bool obscureText = false,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    final c = AppColors.of(context);
    return TextFormField(
      controller: controller,
      inputFormatters: inputFormatters,
      keyboardType: keyboardType,
      obscureText: obscureText,
      textCapitalization: textCapitalization,
      style: TextStyle(color: c.textSub, fontSize: 15),
      cursorColor: c.primary,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: c.textHint, fontSize: 14),
        floatingLabelStyle: TextStyle(color: c.textSub, fontSize: 14),
        prefixIcon: Icon(icon, color: c.textHint, size: 20),
        filled: true,
        fillColor: c.inputBg,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 16,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c.border, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c.primary, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c.error, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c.error, width: 1.8),
        ),
        errorStyle: TextStyle(color: c.error, fontSize: 12),
      ),
      validator: validator,
      onChanged: onChanged,
    );
  }

  // ─── Input de senha com toggle ────────────────────────────────────────────────
  Widget _buildPasswordInput() {
    final c = AppColors.of(context);
    return TextFormField(
      obscureText: !_showPassword,
      style: TextStyle(color: c.textSub, fontSize: 15),
      cursorColor: c.primary,
      validator: (v) =>
          v != null && v.length >= 6 ? null : 'Mínimo 6 caracteres',
      onChanged: (v) => password = v.trim(),
      decoration: InputDecoration(
        labelText: 'Senha',
        labelStyle: TextStyle(color: c.textHint, fontSize: 14),
        floatingLabelStyle: TextStyle(color: c.textSub, fontSize: 14),
        prefixIcon: Icon(
          Icons.lock_outline_rounded,
          color: c.textHint,
          size: 20,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _showPassword
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            color: c.textHint,
            size: 20,
          ),
          onPressed: () => setState(() => _showPassword = !_showPassword),
        ),
        filled: true,
        fillColor: c.inputBg,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 16,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c.border, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c.primary, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c.error, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c.error, width: 1.8),
        ),
        errorStyle: TextStyle(color: c.error, fontSize: 12),
      ),
    );
  }

  // ─── Submit logic ────────────────────────────────────────────────────────────
  Future<void> _submit(AuthService authService) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isLoading = true);
    try {
      if (isLogin) {
        if (_biometriaDisponivel) {
          final ok = await authService.authenticateWithBiometrics();
          if (!ok) {
            _snack('Autenticação biométrica falhou', warning: true);
            setState(() => isLoading = false);
            return;
          }
        }
        final ok = await authService.login(email, password);
        setState(() => isLoading = false);
        if (ok) {
          _snack('Login realizado com sucesso!', success: true);
          await Future.delayed(const Duration(milliseconds: 900));
          final nomeSalvo = await authService.getNomeSalvo();
          if (mounted) {
            Navigator.pushReplacementNamed(
              context,
              '/home',
              arguments: nomeSalvo ?? 'Usuário',
            );
          }
        }
      } else {
        final ok = await authService.register({
          'nome': nome,
          'email': email,
          'password': password,
          'cpf': cpfController.text,
          'telefone': telefoneController.text,
          'data_nascimento': dataController.text,
        });
        setState(() => isLoading = false);
        if (ok) {
          _snack('Cadastro realizado com sucesso!', success: true);
          await Future.delayed(const Duration(milliseconds: 900));
          final nomeSalvo = await authService.getNomeSalvo();
          if (mounted) {
            Navigator.pushReplacementNamed(
              context,
              '/home',
              arguments: nomeSalvo ?? 'Usuário',
            );
          }
        }
      }
    } catch (e) {
      setState(() => isLoading = false);
      _snack(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // ─── Créditos ────────────────────────────────────────────────────────────
  Widget _buildCredits() {
    final c = AppColors.of(context);
    return Column(
      children: [
        SizedBox(height: 8),
        Text(
          'dev. Fabio Argona - Patricia Martins',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 10, color: c.textHint, letterSpacing: 0.3),
        ),
        SizedBox(height: 8),
      ],
    );
  }

  // ...existing code...
}
