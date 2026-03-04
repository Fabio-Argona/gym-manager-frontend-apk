import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_application_treinoabc/services/treino_service.dart';
import 'package:flutter_application_treinoabc/widgets/footer_nav.dart';
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import '../constants/constants.dart';

import 'treinos/treinos_page.dart';
import 'progresso_page.dart';
import 'profile_page.dart';

// ─── Design tokens (mesmos da tela de login) ──────────────────────────────────
const _bg1 = Color(0xFF0D0D1A);
const _bg2 = Color(0xFF1A1040);
const _card = Color(0xFF1C1B2E);
const _primary = Color(0xFF7C3AED);
const _primaryDark = Color(0xFF5B21B6);
const _accent = Color(0xFF06B6D4);
const _success = Color(0xFF10B981);
const _error = Color(0xFFEF4444);
const _inputBg = Color(0xFF252438);
const _border = Color(0xFF3A3857);
const _textHint = Color(0xFF8884A8);
const _textSub = Color(0xFFB0ADCC);

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
  String? imagemUrl;
  String? alunoId;
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
    if (_diasAtivos >= 100) return const Color(0xFF10B981);
    if (_diasAtivos >= 60) return const Color(0xFFF59E0B);
    if (_diasAtivos >= 30) return const Color(0xFF06B6D4);
    if (_diasAtivos >= 10) return const Color(0xFF7C3AED);
    return _textHint;
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
    carregarImagem();
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

  Future<void> carregarImagem() async {
    final prefs = await SharedPreferences.getInstance();
    alunoId = prefs.getString('alunoId') ?? '';
    final urlSalva = prefs.getString('imagemUrl');
    if (urlSalva != null && urlSalva.isNotEmpty) {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      if (mounted) {
        setState(() {
          imagemUrl = '$urlSalva?t=$timestamp';
        });
      }
    }
  }

  Future<void> _selecionarImagem() async {
    final prefs = await SharedPreferences.getInstance();
    final alunoId = prefs.getString('alunoId') ?? '';
    final token = prefs.getString('token') ?? '';

    if (alunoId.isEmpty || token.isEmpty) return;

    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result == null) return;

    // Para mobile, use o caminho do arquivo para ler os bytes
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
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final novaUrl = '$endpointUploads/$fileName';
      final prefs2 = await SharedPreferences.getInstance();
      await prefs2.setString('imagemUrl', novaUrl);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      // Limpa cache do NetworkImage
      imageCache.clear();
      imageCache.clearLiveImages();
      setState(() {
        imagemUrl = '$novaUrl?t=$timestamp';
      });
      _snack('Foto alterada com sucesso!', success: true);
    } else {
      print('Erro ao enviar imagem: ${response.statusCode}');
      print('Resposta: $responseBody');
      _snack('Erro ao enviar imagem: ${response.statusCode}');
    }
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  // ─── Snackbar padronizado ────────────────────────────────────────────────
  void _snack(String message, {bool success = false, bool warning = false}) {
    final color = success ? _success : (warning ? Colors.orange[700]! : _error);
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
            color: color.withOpacity(0.15),
            border: Border.all(color: color.withOpacity(0.5)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: color,
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

  void _criarGrupo() {
    final TextEditingController nomeGrupoController = TextEditingController(
      text: 'Treino - ',
    );

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: _card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: _border, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.fitness_center_rounded,
                      color: _primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Criar Grupo de Treino',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: nomeGrupoController,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                cursorColor: _primary,
                decoration: InputDecoration(
                  labelText: 'Nome do grupo',
                  labelStyle: const TextStyle(color: _textHint, fontSize: 14),
                  prefixIcon: const Icon(
                    Icons.label_outline_rounded,
                    color: _textHint,
                    size: 20,
                  ),
                  filled: true,
                  fillColor: _inputBg,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 16,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _border, width: 1.2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _primary, width: 1.8),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    style: TextButton.styleFrom(foregroundColor: _textHint),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 8),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_primary, _primaryDark],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: _primary.withOpacity(0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      onPressed: () async {
                        final nomeGrupo = nomeGrupoController.text.trim();
                        if (nomeGrupo.isEmpty) {
                          _snack('Digite um nome para o grupo', warning: true);
                          return;
                        }
                        try {
                          await TreinoService().criarGrupo(nomeGrupo);
                          if (context.mounted) Navigator.pop(context);
                          _snack(
                            'Grupo "$nomeGrupo" criado com sucesso',
                            success: true,
                          );
                        } catch (e) {
                          _snack('Erro: ${e.toString()}');
                        }
                      },
                      child: const Text('Salvar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmarLogout() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: _card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: _border, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _error.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: _error,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Sair da conta',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tem certeza que deseja sair?',
                style: TextStyle(color: _textSub, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _textSub,
                        side: const BorderSide(color: _border),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _error,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Sair'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmar == true) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  void _editarPerfil() {
    setState(() => _selectedIndex = 2);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg1,
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
              colors: [_bg2.withOpacity(0.95), _bg1.withOpacity(0.0)],
            ),
          ),
        ),
        titleSpacing: 16,
        title: Row(
          children: [
            // ── Avatar com anel gradiente ───────────────────────────
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'editar':
                    _editarPerfil();
                    break;
                  case 'imagem':
                    _selecionarImagem();
                    break;
                  case 'sair':
                    _confirmarLogout();
                    break;
                }
              },
              color: _card,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: _border),
              ),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'editar',
                  child: Row(
                    children: const [
                      Icon(
                        Icons.person_outline_rounded,
                        color: _textSub,
                        size: 18,
                      ),
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
                    children: const [
                      Icon(
                        Icons.photo_camera_outlined,
                        color: _textSub,
                        size: 18,
                      ),
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
                    children: const [
                      Icon(Icons.logout_rounded, color: _error, size: 18),
                      SizedBox(width: 10),
                      Text(
                        'Sair',
                        style: TextStyle(color: _error, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
              child: AnimatedBuilder(
                animation: _ringController,
                builder: (context, child) => SizedBox(
                  width: 43,
                  height: 43,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Transform.rotate(
                        angle: _ringController.value * 2 * math.pi,
                        child: Container(
                          width: 43,
                          height: 43,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: SweepGradient(
                              colors: [
                                Colors.transparent,
                                _accent,
                                _primary,
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
                  backgroundColor: _card,
                  backgroundImage: imagemUrl != null
                      ? NetworkImage(imagemUrl!)
                      : null,
                  onBackgroundImageError: imagemUrl != null
                      ? (_, __) {
                          if (mounted) setState(() => imagemUrl = null);
                        }
                      : null,
                  child: imagemUrl == null
                      ? Text(
                          widget.nome.isNotEmpty
                              ? widget.nome[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Bem-vindo,',
                    style: TextStyle(
                      fontSize: 11,
                      color: _textHint,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.3,
                    ),
                  ),
                  AnimatedBuilder(
                    animation: _ringController,
                    builder: (context, child) {
                      final v = _ringController.value;
                      return ShaderMask(
                        blendMode: BlendMode.srcIn,
                        shaderCallback: (bounds) => LinearGradient(
                          colors: const [
                            Colors.white,
                            _accent,
                            _primary,
                            _accent,
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
                      widget.nome,
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
                      Icon(_iconNivel, color: _corNivel, size: 11),
                      const SizedBox(width: 3),
                      Text(
                        '$_nivelAtual · $_diasAtivos dias',
                        style: TextStyle(
                          color: _corNivel,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
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
            colors: [_bg1, _bg2, Color(0xFF0E1628)],
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
