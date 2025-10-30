import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class TreinoService {
  final String baseUrl = 'https://gym-manager-java.onrender.com';

  Future<List<Map<String, dynamic>>> listarGrupos() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token') ?? '';
  final alunoId = prefs.getString('alunoId') ?? '';

  final response = await http.get(
    Uri.parse('$baseUrl/grupos/aluno/$alunoId'),
    headers: {'Authorization': 'Bearer $token'},
  );

  if (response.statusCode == 200) {
    final List<dynamic> grupos = jsonDecode(response.body);
    return grupos.cast<Map<String, dynamic>>();
  } else {
    throw Exception('Erro ao buscar grupos: ${response.body}');
  }
}

  Future<void> criarGrupo(String nome) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final alunoId = prefs.getString('alunoId') ?? '';

    final response = await http.post(
      Uri.parse('$baseUrl/grupos'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'nome': nome,
        'alunoId': alunoId,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Erro ao criar grupo: ${response.body}');
    }
  }

  Future<void> editarGrupo(String id, String novoNome) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final response = await http.patch(
      Uri.parse('$baseUrl/grupos/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'nome': novoNome}),
    );

    if (response.statusCode != 200) {
      throw Exception('Erro ao editar grupo: ${response.body}');
    }
  }

  Future<void> excluirGrupo(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final response = await http.delete(
      Uri.parse('$baseUrl/grupos/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 204) {
      throw Exception('Erro ao excluir grupo: ${response.body}');
    }
  }
}
