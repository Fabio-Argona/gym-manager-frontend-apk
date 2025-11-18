import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ExercicioService {
  final String baseUrl = 'http://18.222.56.92:8080';

  Future<Map<String, String>> _getHeaders({bool includeAlunoId = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final alunoId = prefs.getString('alunoId');

    if (token == null || token.isEmpty) {
      throw Exception('Token de autenticação não encontrado');
    }

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    if (includeAlunoId) {
      if (alunoId == null || alunoId.isEmpty) {
        throw Exception('ID do aluno não encontrado');
      }
      headers['aluno-id'] = alunoId;
    }

    return headers;
  }

  Future<void> criarExercicio(Map<String, dynamic> dados) async {
    final headers = await _getHeaders(includeAlunoId: true);

    final grupoId = dados['grupoId'] ?? dados['grupo_id'];
    if (grupoId == null || grupoId.toString().isEmpty) {
      throw Exception('grupo_id é obrigatório para criar exercício');
    }

    final prefs = await SharedPreferences.getInstance();
    final alunoId = prefs.getString('alunoId');

    final body = {
      'nome': dados['nome'],
      'grupo_id': grupoId,
      'grupo_muscular': dados['grupoMuscular'] ?? dados['grupo_muscular'],
      'series': dados['series'] ?? 3,
      'rep_min': dados['repMin'] ?? 10,
      'rep_max': dados['repMax'] ?? 12,
      'peso_inicial': dados['pesoInicial'] ?? 10.0,
      'observacao': dados['observacao'] ?? '',
      'ativo': dados['ativo'] ?? true,
      'aluno_id': alunoId,
    };

    print('POST /exercicios\nBody: ${jsonEncode(body)}');

    final response = await http.post(
      Uri.parse('$baseUrl/exercicios'),
      headers: headers,
      body: jsonEncode(body),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      final erro = jsonDecode(response.body);
      throw Exception(
        'Erro ao criar exercício: ${erro['message'] ?? response.statusCode}',
      );
    }
  }

  Future<List<Map<String, dynamic>>> listarExercicios() async {
    final headers = await _getHeaders(includeAlunoId: true);

    final response = await http.get(
      Uri.parse('$baseUrl/exercicios'),
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Erro ao carregar exercícios');
    }

    final List<dynamic> jsonData = jsonDecode(response.body);
    return jsonData.cast<Map<String, dynamic>>();
  }

  Future<void> editarExercicio(Map<String, dynamic> dados) async {
  final headers = await _getHeaders(includeAlunoId: true);
  final id = dados['id'];

  if (id == null || id.toString().isEmpty) {
    throw Exception('ID do exercício é obrigatório para edição');
  }

  

  final body = {
    'nome': dados['nome'],
    'grupoId': dados['grupoId'] ?? dados['grupo_id'],
    'grupoMuscular': dados['grupoMuscular'] ?? 'Peito',
    'series': dados['series'],
    'repMin': dados['repMin'] ?? 0,
    'repMax': dados['repMax'] ?? 0,
    'pesoInicial': dados['pesoInicial'] ?? 0.0,
    'observacao': dados['observacao'] ?? '',
    'ativo': dados['ativo'],
  };

  print('PUT /exercicios/$id\nBody: ${jsonEncode(body)}');

  final response = await http.put(
    Uri.parse('$baseUrl/exercicios/$id'),
    headers: headers,
    body: jsonEncode(body),
  );

  if (response.statusCode != 200) {
    final erro = jsonDecode(response.body);
    throw Exception(
      'Erro ao editar exercício: ${erro['message'] ?? response.statusCode}',
    );
  }
}

Future<void> excluirGrupoComExercicios(String grupoId) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token') ?? '';

  if (token.isEmpty) {
    throw Exception('Token não encontrado');
  }

  final response = await http.delete(
    Uri.parse('$baseUrl/grupos/$grupoId/com-exercicios'),
    headers: {'Authorization': 'Bearer $token'},
  );

  if (response.statusCode != 200 && response.statusCode != 204) {
    throw Exception('Erro ao excluir grupo e exercícios: ${response.body}');
  }
}



Future<void> desativarExercicio(
  BuildContext context,
  Map<String, dynamic> exercicio,
  VoidCallback onAtualizar,
) async {
  try {
    await editarExercicio({
      'id': exercicio['id'],
      'nome': exercicio['nome'],
      'grupoId': exercicio['grupoId'],
      'grupoMuscular': exercicio['grupoMuscular'] ?? 'Peito', 
      'series': exercicio['series'],
      'repMin': exercicio['repMin'],
      'repMax': exercicio['repMax'],
      'pesoInicial': exercicio['pesoInicial'],
      'observacao': exercicio['observacao'],
      'ativo': false,
    });

    onAtualizar();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Exercício desativado com sucesso')),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao desativar: $e')),
      );
    }
  }
}

  Future<void> atualizarStatus(String id, bool ativo) async {
    final headers = await _getHeaders(includeAlunoId: true);

    final uri = Uri.parse('$baseUrl/exercicios/$id/status');
    final body = jsonEncode({'ativo': ativo});

    print('PATCH $uri\nBody: $body');

    final response = await http.patch(uri, headers: headers, body: body);

    if (response.statusCode == 200 || response.statusCode == 204) {
      return;
    }

    String mensagemErro;
    try {
      final erro = jsonDecode(response.body);
      mensagemErro = erro['message'] ?? 'Erro desconhecido';
    } catch (_) {
      mensagemErro = 'Erro ao atualizar status: ${response.statusCode}';
    }

    throw Exception(mensagemErro);
  }
}
