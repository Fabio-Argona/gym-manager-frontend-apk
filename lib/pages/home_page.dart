import 'dart:math' as math;
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_application_treinoabc/services/treino_service.dart';
import 'package:flutter_application_treinoabc/widgets/footer_nav.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import '../constants/constants.dart';
import 'treinos/treinos_design_tokens.dart';
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
    if (_diasAtivos >= 500) return const Color(0xFFFFD700);
    if (_diasAtivos >= 300) return const Color(0xFFAB47BC);
    if (_diasAtivos >= 200) return const Color(0xFF26C6DA);
    if (_diasAtivos >= 150) return const Color(0xFF42A5F5);
    if (_diasAtivos >= 100) return kSuccess;
    if (_diasAtivos >= 60) return const Color(0xFFF59E0B);
    if (_diasAtivos >= 30) return kAccent;
    if (_diasAtivos >= 10) return kPrimary;
    return kTextHint;
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
      TreinosPage(nome: widget.nome),
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
        if (mounted) setState(() => _diasAtivos = datas.length);
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
    return Scaffold(
      backgroundColor: kBg1,
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
                kBg2.withValues(alpha: 0.95),
                kBg1.withValues(alpha: 0.0),
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
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [kBg1, kBg2, Color(0xFF0E1628)],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [Expanded(child: _pages[_selectedIndex])],
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
      color: kCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: kBorder),
      ),
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: 'editar',
          child: Row(
            children: [
              Icon(Icons.person_outline_rounded, color: kTextSub, size: 18),
              SizedBox(width: 10),
              Text(
                'Meu Perfil',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'imagem',
          child: Row(
            children: [
              Icon(Icons.photo_camera_outlined, color: kTextSub, size: 18),
              SizedBox(width: 10),
              Text(
                'Trocar foto',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'sair',
          child: Row(
            children: [
              Icon(Icons.logout_rounded, color: kError, size: 18),
              SizedBox(width: 10),
              Text('Sair', style: TextStyle(color: kError, fontSize: 14)),
            ],
          ),
        ),
      ],
      child: AnimatedBuilder(
        animation: ringController,
        builder: (context, child) => SizedBox(
          width: 43,
          height: 43,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.rotate(
                angle: ringController.value * 2 * math.pi,
                child: Container(
                  width: 43,
                  height: 43,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: SweepGradient(
                      colors: [
                        Colors.transparent,
                        kAccent,
                        kPrimary,
                        Colors.transparent,
                      ],
                      stops: [0.0, 0.2, 0.7, 1.0],
                    ),
                  ),
                ),
              ),
              child!,
            ],
          ),
        ),
        child: CircleAvatar(
          radius: 19,
          backgroundColor: kCard,
          backgroundImage: imagemUrl != null ? NetworkImage(imagemUrl!) : null,
          onBackgroundImageError: imagemUrl != null
              ? (_, __) => onImageError()
              : null,
          child: imagemUrl == null
              ? Text(
                  nome.isNotEmpty ? nome[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                )
              : null,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Bem-vindo,',
          style: TextStyle(
            fontSize: 11,
            color: kTextHint,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.3,
          ),
        ),
        AnimatedBuilder(
          animation: ringController,
          builder: (context, child) {
            final v = ringController.value;
            return ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (bounds) => LinearGradient(
                colors: const [
                  Colors.white,
                  kAccent,
                  kPrimary,
                  kAccent,
                  Colors.white,
                ],
                stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
                begin: Alignment(-3.0 + v * 4.0, 0),
                end: Alignment(-1.0 + v * 4.0, 0),
              ).createShader(bounds),
              child: child,
            );
          },
          child: Text(
            nome,
            style: const TextStyle(
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
