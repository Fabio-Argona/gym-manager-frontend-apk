import 'package:flutter/material.dart';
import 'package:flutter_application_treinoabc/services/treino_service.dart';
import 'package:flutter_application_treinoabc/widgets/footer_nav.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

import 'treinos/treinos_page.dart';
import 'progresso_page.dart';
import 'profile_page.dart';

class HomePage extends StatefulWidget {
  final String nome;

  const HomePage({super.key, required this.nome});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  late final List<Widget> _pages;
  String? imagemUrl;
  String? alunoId;

  @override
  void initState() {
    super.initState();
    _pages = [
      TreinosPage(nome: widget.nome),
      const ProgressoPage(),
      const ProfilePage(),
    ];
    carregarImagem();
  }

  Future<void> carregarImagem() async {
    final prefs = await SharedPreferences.getInstance();
    alunoId = prefs.getString('alunoId') ?? '';
    if (alunoId != null && alunoId!.isNotEmpty) {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      setState(() {
        imagemUrl =
            'http://localhost:8080/api/uploads/$alunoId.jpeg?t=$timestamp';
      });
    }
  }

  Future<void> _selecionarImagem() async {
    final prefs = await SharedPreferences.getInstance();
    final alunoId = prefs.getString('alunoId') ?? '';
    final token = prefs.getString('token') ?? '';

    if (alunoId.isEmpty || token.isEmpty) return;

    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result == null || result.files.first.bytes == null) return;

    final fileBytes = result.files.first.bytes!;
    final fileName = '$alunoId.jpeg';
    final uri = Uri.parse('http://localhost:8080/api/upload/$alunoId');

    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..files.add(
        http.MultipartFile.fromBytes('foto', fileBytes, filename: fileName),
      );

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      setState(() {
        imagemUrl =
            'http://localhost:8080/api/uploads/$alunoId.jpeg?t=$timestamp';
      });
    } else {
      print('Erro ao enviar imagem: ${response.statusCode}');
      print('Resposta: $responseBody');
    }
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  void _criarGrupo() {
    final TextEditingController nomeGrupoController = TextEditingController(
      text: 'Treino - ',
    );

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Criar Grupo de Treino',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              TextFormField(
                controller: nomeGrupoController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Nome do grupo',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: const Color(0xFF2C2C2C),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurpleAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 4,
                    ),
                    onPressed: () async {
                      final nomeGrupo = nomeGrupoController.text.trim();
                      if (nomeGrupo.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Digite um nome para o grupo'),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                        return;
                      }

                      try {
                        await TreinoService().criarGrupo(nomeGrupo);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Grupo "$nomeGrupo" criado com sucesso',
                            ),
                            backgroundColor: Colors.greenAccent.shade100,
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Erro: ${e.toString()}'),
                            backgroundColor: Colors.redAccent.shade100,
                          ),
                        );
                      }
                    },
                    child: const Text(
                      'Salvar',
                      style: TextStyle(fontWeight: FontWeight.bold),
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
      builder: (context) => AlertDialog(
        title: const Text('Sair'),
        content: const Text('Tem certeza que deseja sair da conta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sair', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  void _editarPerfil() {
    setState(() => _selectedIndex = 2); // Muda para a aba ProfilePage
  }

  String _mensagemMotivadora() {
    final frases = [
      'Bora treinar e conquistar seus objetivos! 💪',
      'Cada treino é um passo à frente 🚀',
      'Foco, força e fé 🔥',
      'A disciplina vence o cansaço 🧠',
      'Você está superando limites hoje 👊',
      'O corpo alcança o que a mente acredita 🏋️‍♂️',
    ];
    frases.shuffle();
    return frases.first;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.nome,
                  style: const TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              _mensagemMotivadora(),
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: PopupMenuButton<String>(
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
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'editar', child: Text('Meu Perfil')),
                const PopupMenuItem(
                  value: 'imagem',
                  child: Text('Trocar imagem'),
                ),
                const PopupMenuItem(value: 'sair', child: Text('Sair')),
              ],
              child: CircleAvatar(
                radius: 20,
                backgroundColor: Colors.deepPurple,
                backgroundImage: imagemUrl != null
                    ? NetworkImage(imagemUrl!)
                    : null,
                child: imagemUrl == null
                    ? Text(
                        widget.nome[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
            ),
          ),
        ],
      ),
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

          // 🔳 Camada de cor semi-transparente
          Container(color: Colors.black.withOpacity(0.3)),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [Expanded(child: _pages[_selectedIndex])],
            ),
          ),
        ],
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
