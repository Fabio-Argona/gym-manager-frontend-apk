import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ExercicioService {
  final String baseUrl = 'http://localhost:8080';

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

    final grupoMuscular = dados['grupoMuscular'] ?? dados['grupo_muscular'];
    if (grupoMuscular == null || grupoMuscular.toString().isEmpty) {
      throw Exception('grupo_muscular é obrigatório para criar exercício');
    }

    final body = {
      'nome': dados['nome'],
      'grupo_id': grupoId,
      'grupo_muscular': grupoMuscular,
      'series': dados['series'] ?? 3,
      'repeticoes': dados['repeticoes'] ?? 10,
      'peso_inicial': dados['pesoInicial'] ?? 10.0,
      'observacao': dados['observacao'] ?? '',
      'ativo': dados['ativo'] ?? true,
      'aluno_id': alunoId,
    };

    // Log detalhado para depuração
    print('POST $baseUrl/exercicios');
    print('Headers: $headers');
    print('Body: ${jsonEncode(body)}');

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

    return jsonData
        .map((ex) {
          if (ex is Map<String, dynamic>) {
            num? toNumber(dynamic value) {
              if (value == null) return null;
              if (value is num) return value;
              if (value is String) return num.tryParse(value);
              return null;
            }

            return {
              'id': ex['id'],
              'nome': ex['nome'],
              'grupoId': ex['grupo_id'] ?? ex['grupoId'],
              'grupo_id': ex['grupo_id'],
              'grupoMuscular': ex['grupo_muscular'] ?? ex['grupoMuscular'],
              'series': toNumber(ex['series']) ?? 0,
              'repeticoes': toNumber(ex['repeticoes']) ?? 0,
              'pesoInicial': (toNumber(ex['peso_inicial']) ?? 0.0).toDouble(),
              'peso_inicial': ex['peso_inicial'],
              'observacao': ex['observacao'] ?? '',
              'ativo': ex['ativo'] ?? true,
              'exercicioId': ex['exercicioId'] ?? ex['id'],
              'alunoId': ex['aluno_id'] ?? ex['alunoId'],
              'aluno_id': ex['aluno_id'],
              'dataCriacao': ex['data_criacao'] ?? ex['dataCriacao'],
              'dataAtualizacao':
                  ex['data_atualizacao'] ?? ex['dataAtualizacao'],
            };
          }
          return ex;
        })
        .cast<Map<String, dynamic>>()
        .toList();
  }

  Future<void> editarExercicio(Map<String, dynamic> dados) async {
    final headers = await _getHeaders(includeAlunoId: true);
    final id = dados['id'];

    if (id == null || id.toString().isEmpty) {
      throw Exception('ID do exercício é obrigatório para edição');
    }

    final grupoMuscular = dados['grupoMuscular'] ?? 'Peito';

    final body = {
      'nome': dados['nome'],
      'grupoId': dados['grupoId'] ?? dados['grupo_id'],
      'grupoMuscular': grupoMuscular,
      'series': dados['series'],
      'repeticoes': dados['repeticoes'] ?? 0,
      'pesoInicial': dados['pesoInicial'] ?? 0.0,
      'observacao': dados['observacao'] ?? '',
      'ativo': dados['ativo'],
    };

    print('PUT $baseUrl/exercicios/$id');
    print('Headers: $headers');
    print('Body: ${jsonEncode(body)}');

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
        'repeticoes': exercicio['repeticoes'],
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao desativar: $e')));
      }
    }
  }

  Future<void> atualizarStatus(String id, bool ativo) async {
    final headers = await _getHeaders(includeAlunoId: true);

    final uri = Uri.parse('$baseUrl/exercicios/$id/status');
    final body = jsonEncode({'ativo': ativo});

    print('PATCH $uri');
    print('Headers: $headers');
    print('Body: $body');

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
