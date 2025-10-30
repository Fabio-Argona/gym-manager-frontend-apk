import 'package:flutter/material.dart';
import 'package:flutter_application_treinoabc/services/treino_service.dart';
import 'package:flutter_application_treinoabc/widgets/footer_nav.dart';
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

  @override
  void initState() {
    super.initState();
    _pages = [
      TreinosPage(nome: widget.nome),
      const ProgressoPage(),
      const ProfilePage(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  void _criarGrupo() {
  final TextEditingController nomeGrupoController = TextEditingController();

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Novo Grupo de Treino'),
      content: TextFormField(
        controller: nomeGrupoController,
        decoration: const InputDecoration(
          labelText: 'Nome do grupo',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () async {
            final nomeGrupo = nomeGrupoController.text.trim();
            if (nomeGrupo.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Digite um nome para o grupo')),
              );
              return;
            }

            try {
              await TreinoService().criarGrupo(nomeGrupo);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Grupo "$nomeGrupo" criado com sucesso')),
              );
              Navigator.pop(context);
              // TODO: atualizar lista de grupos na tela de treinos
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Erro: ${e.toString()}')),
              );
            }
          },
          child: const Text('Salvar'),
        ),
      ],
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Perfil'),
        content: const Text('Aqui você pode editar seu nome, foto ou dados.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              // Salvar alterações...
              Navigator.pop(context);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black26,
      appBar: AppBar(
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: const Text(
          'Fulltreino',
          style: TextStyle(
            backgroundColor: Colors.transparent,
            color: Colors.red,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_selectedIndex == 0)
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Bem-vindo',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.nome}!',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w500,
                            color: Colors.amberAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(child: _pages[_selectedIndex]),
              ],
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
