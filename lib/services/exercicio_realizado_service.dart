import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../dto/ExercicioRealizadoDTO.dart';

class ExercicioRealizadoService {
  final String baseUrl = 'http://localhost:8080';

  // INICIAR TREINO (criar TreinoRealizado)
  Future<String?> iniciarTreino(String grupoId, String data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final alunoId = prefs.getString('alunoId') ?? '';
      final token = prefs.getString('token') ?? '';

      if (alunoId.isEmpty || token.isEmpty) return null;

      // Tenta o endpoint principal
      final response = await http.post(
        Uri.parse('$baseUrl/treinos/realizado'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'aluno-id': alunoId,
        },
        body: jsonEncode({
          'grupoId': grupoId,
          'dataSessao': data,
          'alunoId': alunoId,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = jsonDecode(response.body);
        return json['id']?.toString();
      }

      print(
        'Erro ao iniciar treino: ${response.statusCode} - ${response.body}',
      );

      // Se falhar, usa um ID temporário com timestamp
      // Isso permite que o usuário registre exercícios mesmo sem o TreinoRealizado ser criado
      final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
      print('Usando ID temporário: $tempId');
      return tempId;
    } catch (e) {
      print('Erro ao iniciar treino: $e');
      return null;
    }
  }

  // REGISTRAR EXERCÍCIO REALIZADO
  Future<bool> registrarExercicio({
    required String treinoRealizadoId,
    required String exercicioId,
    required int seriesRealizadas,
    required int repeticoesRealizadas,
    required double pesoUtilizado,
    required String dataSessao,
    String? observacoes,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      if (token.isEmpty) return false;

      final response = await http.post(
        Uri.parse('$baseUrl/exercicios-realizados'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'treinoRealizadoId': treinoRealizadoId,
          'exercicioId': exercicioId,
          'seriesRealizadas': seriesRealizadas,
          'repeticoesRealizadas': repeticoesRealizadas,
          'pesoUtilizado': pesoUtilizado,
          'dataSessao': dataSessao,
          'observacoes': observacoes ?? '',
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }
      print('Erro ao registrar exercício: ${response.body}');
      return false;
    } catch (e) {
      print('Erro ao registrar exercício: $e');
      return false;
    }
  }

  // BUSCAR HISTÓRICO PARA GRÁFICOS
  Future<List<ExercicioRealizadoDTO>> buscarProgressao({
    String? exercicioId,
    String? dataInicio,
    String? dataFim,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final alunoId = prefs.getString('alunoId') ?? '';
      final token = prefs.getString('token') ?? '';

      if (alunoId.isEmpty || token.isEmpty) return [];

      String url = '$baseUrl/exercicios-realizados/progressao?alunoId=$alunoId';

      if (exercicioId != null) url += '&exercicioId=$exercicioId';
      if (dataInicio != null) url += '&dataInicio=$dataInicio';
      if (dataFim != null) url += '&dataFim=$dataFim';

      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> json = jsonDecode(response.body);
        return json.map((e) => ExercicioRealizadoDTO.fromJson(e)).toList();
      }
      print('Erro ao buscar progressão: ${response.body}');
      return [];
    } catch (e) {
      print('Erro ao buscar progressão: $e');
      return [];
    }
  }

  // BUSCAR ÚLTIMA SESSÃO DE UM GRUPO
  Future<TreinoRealizadoDTO?> buscarUltimaSessao(String grupoId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      if (token.isEmpty) return null;

      final response = await http.get(
        Uri.parse('$baseUrl/treinos/realizado/grupo/$grupoId/ultima'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return TreinoRealizadoDTO.fromJson(json);
      }
      return null;
    } catch (e) {
      print('Erro ao buscar última sessão: $e');
      return null;
    }
  }

  // BUSCAR TODAS AS SESSÕES DE UM ALUNO
  Future<List<TreinoRealizadoDTO>> buscarSessoes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final alunoId = prefs.getString('alunoId') ?? '';
      final token = prefs.getString('token') ?? '';

      if (alunoId.isEmpty || token.isEmpty) return [];

      final response = await http.get(
        Uri.parse('$baseUrl/treinos/realizado/aluno/$alunoId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> json = jsonDecode(response.body);
        return json.map((e) => TreinoRealizadoDTO.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      print('Erro ao buscar sessões: $e');
      return [];
    }
  }
}
