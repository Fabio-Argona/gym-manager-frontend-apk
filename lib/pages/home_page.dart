import 'dart:math' as math;
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_treinoabc/services/treino_service.dart';
import 'package:flutter_application_treinoabc/widgets/footer_nav.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import '../constants/constants.dart';
import '../constants/app_theme.dart';
import '../providers/theme_provider.dart';
import 'treinos/treinos_shared_widgets.dart';
import 'treinos/treinos_dialogs.dart';
import 'treinos/treinos_page.dart';
import 'progresso_page.dart';
import 'profile_page.dart';

class HomePage extends StatefulWidget {
  final String nome;

  const HomePage({super.key, required this.nome});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late final List<Widget> _pages;
  String? _imagemUrl;
  int _diasAtivos = 0;
  Set<String> _datasAtivas = {};
  late AnimationController _ringController;

  static const _limitesNivel = [0, 10, 30, 60, 100, 150, 200, 300, 500];
  static const _nomesNivel = [
    'Iniciante',
    'Aprendiz',
    'Dedicado',
    'Consistente',
    'Intermediário',
    'Avançado',
    'Elite',
    'Mestre',
    'Lendário',
  ];

  String get _nivelAtual {
    for (int i = _limitesNivel.length - 1; i >= 0; i--) {
      if (_diasAtivos >= _limitesNivel[i]) return _nomesNivel[i];
    }
    return _nomesNivel[0];
  }

  Color get _corNivel {
    final c = AppColors.of(context);
    if (_diasAtivos >= 500) return const Color(0xFFFFD700);
    if (_diasAtivos >= 300) return const Color(0xFFAB47BC);
    if (_diasAtivos >= 200) return const Color(0xFF26C6DA);
    if (_diasAtivos >= 150) return const Color(0xFF42A5F5);
    if (_diasAtivos >= 100) return c.success;
    if (_diasAtivos >= 60) return const Color(0xFFF59E0B);
    if (_diasAtivos >= 30) return c.accent;
    if (_diasAtivos >= 10) return c.primary;
    return c.textHint;
  }

  IconData get _iconNivel {
    if (_diasAtivos >= 500) return Icons.auto_awesome_rounded;
    if (_diasAtivos >= 300) return Icons.workspace_premium_rounded;
    if (_diasAtivos >= 200) return Icons.diamond_rounded;
    if (_diasAtivos >= 150) return Icons.star_rounded;
    if (_diasAtivos >= 100) return Icons.emoji_events_rounded;
    if (_diasAtivos >= 60) return Icons.local_fire_department_rounded;
    if (_diasAtivos >= 30) return Icons.fitness_center_rounded;
    if (_diasAtivos >= 10) return Icons.bolt_rounded;
    return Icons.eco_rounded;
  }

  @override
  void initState() {
    super.initState();
    _pages = [
      TreinosPage(
        nome: widget.nome,
        onTreinoIniciado: () {
          final hoje = DateTime.now();
          final dataStr =
              '${hoje.year}-${hoje.month.toString().padLeft(2, '0')}-${hoje.day.toString().padLeft(2, '0')}';
          if (!_datasAtivas.contains(dataStr)) {
            setState(() {
              _datasAtivas = {..._datasAtivas, dataStr};
              _diasAtivos = _datasAtivas.length;
            });
          }
        },
      ),
      const ProgressoPage(),
      const ProfilePage(),
    ];
    _carregarImagem();
    _carregarDiasAtivos();
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _ringController.dispose();
    super.dispose();
  }

  Future<void> _carregarDiasAtivos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final id = prefs.getString('alunoId') ?? '';
      final token = prefs.getString('token') ?? '';
      if (id.isEmpty || token.isEmpty) return;
      final res = await http.get(
        Uri.parse('$endpointTreinosRealizado/aluno/$id'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 200) {
        final lista = jsonDecode(res.body) as List;
        final datas = lista
            .map(
              (s) => (s['data'] ?? s['dataSessao'] ?? s['data_sessao'] ?? '')
                  .toString(),
            )
            .where((d) => d.length >= 10)
            .map((d) => d.substring(0, 10))
            .toSet();
        if (mounted)
          setState(() {
            _diasAtivos = datas.length;
            _datasAtivas = datas;
          });
      }
    } catch (_) {}
  }

  Future<void> _carregarImagem() async {
    final prefs = await SharedPreferences.getInstance();
    final urlSalva = prefs.getString('imagemUrl');
    if (urlSalva != null && urlSalva.isNotEmpty) {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      if (mounted) setState(() => _imagemUrl = '$urlSalva?t=$timestamp');
    }
  }

  Future<void> _selecionarImagem() async {
    final prefs = await SharedPreferences.getInstance();
    final alunoId = prefs.getString('alunoId') ?? '';
    final token = prefs.getString('token') ?? '';
    if (alunoId.isEmpty || token.isEmpty) return;

    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result == null) return;

    final filePath = result.files.first.path;
    if (filePath == null) return;
    final fileBytes = await File(filePath).readAsBytes();
    final originalName = result.files.first.name;
    final extensao = originalName.contains('.')
        ? originalName.split('.').last.toLowerCase()
        : 'jpeg';
    final fileName = '$alunoId.$extensao';
    final uri = Uri.parse('$endpointUpload/$alunoId');

    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..files.add(
        http.MultipartFile.fromBytes('foto', fileBytes, filename: fileName),
      );

    final response = await request.send();
    await response.stream.bytesToString();
    if (!mounted) return;

    if (response.statusCode == 200) {
      final novaUrl = '$endpointUploads/$fileName';
      final prefs2 = await SharedPreferences.getInstance();
      await prefs2.setString('imagemUrl', novaUrl);
      if (!mounted) return;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      imageCache.clear();
      imageCache.clearLiveImages();
      setState(() => _imagemUrl = '$novaUrl?t=$timestamp');
      showCustomSnackBar(context, 'Foto alterada com sucesso!', success: true);
    } else {
      showCustomSnackBar(
        context,
        'Erro ao enviar imagem: ${response.statusCode}',
      );
    }
  }

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  void _criarGrupo() async {
    final controller = TextEditingController(text: 'Treino - ');
    final nome = await showDialog<String>(
      context: context,
      builder: (_) => GrupoDialog(nomeInicial: '', controller: controller),
    );
    if (nome == null || nome.trim().isEmpty) return;
    if (!mounted) return;
    try {
      await TreinoService().criarGrupo(nome.trim());
      if (!mounted) return;
      showCustomSnackBar(
        context,
        'Grupo "$nome" criado com sucesso',
        success: true,
      );
    } catch (e) {
      if (!mounted) return;
      showCustomSnackBar(context, 'Erro: ${e.toString()}');
    }
  }

  void _confirmarLogout() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => const ConfirmDialog(
        title: 'Sair da conta',
        message: 'Tem certeza que deseja sair?',
        confirmLabel: 'Sair',
        danger: true,
      ),
    );
    if (confirmar == true && mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  void _editarPerfil() => setState(() => _selectedIndex = 2);

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      backgroundColor: c.bg1,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                c.bg2.withValues(alpha: 0.95),
                c.bg1.withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
        titleSpacing: 16,
        title: Row(
          children: [
            _AvatarMenu(
              ringController: _ringController,
              imagemUrl: _imagemUrl,
              nome: widget.nome,
              onEditarPerfil: _editarPerfil,
              onSelecionarImagem: _selecionarImagem,
              onLogout: _confirmarLogout,
              onImageError: () {
                if (mounted) setState(() => _imagemUrl = null);
              },
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _NomeHeader(
                nome: widget.nome,
                nivelAtual: _nivelAtual,
                diasAtivos: _diasAtivos,
                corNivel: _corNivel,
                iconNivel: _iconNivel,
                ringController: _ringController,
              ),
            ),
          ],
        ),
        actions: [
          Consumer<ThemeProvider>(
            builder: (_, tp, __) => IconButton(
              tooltip: tp.isDark ? 'Tema claro' : 'Tema escuro',
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Icon(
                  tp.isDark
                      ? Icons.light_mode_rounded
                      : Icons.dark_mode_rounded,
                  key: ValueKey(tp.isDark),
                  color: tp.isDark ? Colors.amber : c.primary,
                ),
              ),
              onPressed: tp.toggle,
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _WeekStrip(datasAtivas: _datasAtivas),
              Expanded(
                child: IndexedStack(index: _selectedIndex, children: _pages),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: FooterNav(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
        onAddGrupo: _criarGrupo,
        onLogout: _confirmarLogout,
      ),
    );
  }
}

// ─── Sub-widgets extraídos ────────────────────────────────────────────────────

// ─── Week Strip ───────────────────────────────────────────────────────────────────
class _WeekStrip extends StatelessWidget {
  final Set<String> datasAtivas;
  const _WeekStrip({required this.datasAtivas});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final hoje = DateTime.now();
    // Mostra hoje + 7 dias anteriores (8 dias no total)
    final dias = List.generate(8, (i) => hoje.subtract(Duration(days: 7 - i)));
    const letras = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];

    final totalTreinos = datasAtivas.length;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 0),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [c.card.withValues(alpha: 0.9), c.bg2.withValues(alpha: 0.7)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: c.primary.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Coluna lateral com streak info
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$totalTreinos',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: c.primary,
                  height: 1,
                ),
              ),
              Text(
                'treinos',
                style: TextStyle(
                  fontSize: 9,
                  color: c.textHint,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
          Container(
            width: 1,
            height: 36,
            color: c.border.withValues(alpha: 0.5),
          ),
          const SizedBox(width: 10),
          // Dias da semana
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: dias.map((d) {
                final dataStr =
                    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
                final treinou = datasAtivas.contains(dataStr);
                final ehHoje =
                    d.year == hoje.year &&
                    d.month == hoje.month &&
                    d.day == hoje.day;
                final letra = letras[d.weekday % 7];

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      letra,
                      style: TextStyle(
                        fontSize: 9,
                        color: ehHoje
                            ? c.accent
                            : treinou
                            ? c.primary.withValues(alpha: 0.8)
                            : c.textHint.withValues(alpha: 0.5),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 5),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: treinou
                            ? LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  c.primary,
                                  c.primary.withValues(alpha: 0.7),
                                ],
                              )
                            : null,
                        color: !treinou
                            ? ehHoje
                                  ? c.accent.withValues(alpha: 0.12)
                                  : Colors.transparent
                            : null,
                        border: ehHoje && !treinou
                            ? Border.all(color: c.accent, width: 1.5)
                            : treinou
                            ? null
                            : Border.all(
                                color: c.border.withValues(alpha: 0.3),
                                width: 1,
                              ),
                        boxShadow: treinou
                            ? [
                                BoxShadow(
                                  color: c.primary.withValues(alpha: 0.35),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: treinou
                            ? Icon(
                                Icons.check_rounded,
                                size: 14,
                                color: Colors.white,
                              )
                            : Text(
                                '${d.day}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: ehHoje
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                                  color: ehHoje ? c.accent : c.textHint,
                                ),
                              ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Avatar com anel giratório e menu de contexto.
class _AvatarMenu extends StatelessWidget {
  final AnimationController ringController;
  final String? imagemUrl;
  final String nome;
  final VoidCallback onEditarPerfil;
  final VoidCallback onSelecionarImagem;
  final VoidCallback onLogout;
  final VoidCallback onImageError;

  const _AvatarMenu({
    required this.ringController,
    required this.imagemUrl,
    required this.nome,
    required this.onEditarPerfil,
    required this.onSelecionarImagem,
    required this.onLogout,
    required this.onImageError,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return PopupMenuButton<String>(
      onSelected: (value) {
        switch (value) {
          case 'editar':
            onEditarPerfil();
            break;
          case 'imagem':
            onSelecionarImagem();
            break;
          case 'sair':
            onLogout();
            break;
        }
      },
      color: c.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: c.border),
      ),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'editar',
          child: Row(
            children: [
              Icon(Icons.person_outline_rounded, color: c.textSub, size: 18),
              SizedBox(width: 10),
              Text(
                'Meu Perfil',
                style: TextStyle(color: c.textSub, fontSize: 14),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'imagem',
          child: Row(
            children: [
              Icon(Icons.photo_camera_outlined, color: c.textSub, size: 18),
              SizedBox(width: 10),
              Text(
                'Trocar foto',
                style: TextStyle(color: c.textSub, fontSize: 14),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'sair',
          child: Row(
            children: [
              Icon(Icons.logout_rounded, color: c.error, size: 18),
              SizedBox(width: 10),
              Text('Sair', style: TextStyle(color: c.error, fontSize: 14)),
            ],
          ),
        ),
      ],
      child: SizedBox(
        width: 43,
        height: 43,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 43,
              height: 43,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(
                  colors: [
                    Colors.transparent,
                    c.accent,
                    c.primary,
                    Colors.transparent,
                  ],
                  stops: [0.0, 0.2, 0.7, 1.0],
                ),
              ),
            ),
            CircleAvatar(
              radius: 19,
              backgroundColor: c.card,
              backgroundImage: imagemUrl != null
                  ? NetworkImage(imagemUrl!)
                  : null,
              onBackgroundImageError: imagemUrl != null
                  ? (_, __) => onImageError()
                  : null,
              child: imagemUrl == null
                  ? Text(
                      nome.isNotEmpty ? nome[0].toUpperCase() : '?',
                      style: TextStyle(
                        color: c.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

/// Coluna de nome + nível exibida na AppBar.
class _NomeHeader extends StatelessWidget {
  final String nome;
  final String nivelAtual;
  final int diasAtivos;
  final Color corNivel;
  final IconData iconNivel;
  final AnimationController ringController;

  const _NomeHeader({
    required this.nome,
    required this.nivelAtual,
    required this.diasAtivos,
    required this.corNivel,
    required this.iconNivel,
    required this.ringController,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Bem-vindo,',
          style: TextStyle(
            fontSize: 11,
            color: c.textHint,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.3,
          ),
        ),
        AnimatedBuilder(
          animation: ringController,
          builder: (context, child) {
            final c = AppColors.of(context);
            final v = ringController.value;
            return ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (bounds) => LinearGradient(
                colors: [c.textSub, c.accent, c.primary, c.accent, c.textSub],
                stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
                begin: Alignment(-3.0 + v * 4.0, 0),
                end: Alignment(-1.0 + v * 4.0, 0),
              ).createShader(bounds),
              child: child,
            );
          },
          child: Text(
            nome,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.2,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 3),
        Row(
          children: [
            Icon(iconNivel, color: corNivel, size: 11),
            const SizedBox(width: 3),
            Text(
              '$nivelAtual · $diasAtivos dias',
              style: TextStyle(
                color: corNivel,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
