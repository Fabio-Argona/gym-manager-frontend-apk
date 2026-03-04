import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
// ignore: depend_on_referenced_packages
import 'package:http_parser/http_parser.dart';
import '../constants/constants.dart';
import '../main.dart';

class TreinoService {
  // 🔍 Lista os grupos do aluno
  Future<List<Map<String, dynamic>>> listarGrupos() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final alunoId = prefs.getString('alunoId') ?? '';

    if (token.isEmpty || alunoId.isEmpty) {
      throw Exception(
        'Credenciais inv\u00e1lidas (token: ${token.isEmpty ? "vazio" : "ok"}, alunoId: ${alunoId.isEmpty ? "vazio" : alunoId})',
      );
    }

    final response = await http.get(
      Uri.parse('$endpointGrupos/aluno/$alunoId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> raw = jsonDecode(utf8.decode(response.bodyBytes));
      return raw.map((e) {
        final m = Map<String, dynamic>.from(e as Map);
        m['id'] = m['id']?.toString();
        return m;
      }).toList();
    } else if (response.statusCode == 401 || response.statusCode == 403) {
      await handleUnauthorized();
      throw Exception('Sess\u00e3o expirada. Fa\u00e7a login novamente.');
    } else {
      throw Exception(
        'HTTP ${response.statusCode} - ${utf8.decode(response.bodyBytes)}',
      );
    }
  }

  Future<Map<String, dynamic>> criarGrupo(String nome) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final alunoId = prefs.getString('alunoId') ?? '';

    if (token.isEmpty || alunoId.isEmpty) {
      throw Exception('Credenciais inválidas');
    }

    final response = await http.post(
      Uri.parse(endpointGrupos),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'nome': nome, 'alunoId': alunoId}),
    );

    if (response.statusCode != 201) {
      throw Exception('Erro ao criar grupo: ${response.body}');
    }

    final m = Map<String, dynamic>.from(jsonDecode(response.body) as Map);
    m['id'] = m['id']?.toString();
    return m;
  }

  // ✏️ Edita o nome de um grupo
  Future<void> editarGrupo(String grupoId, String novoNome) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    if (token.isEmpty) {
      throw Exception('Token não encontrado');
    }

    final response = await http.patch(
      Uri.parse('$endpointGrupos/$grupoId'),
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

  // ❌ Exclui um grupo junto com seus exercícios vinculados
  Future<void> excluirGrupoComExercicios(String grupoId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    if (token.isEmpty) {
      throw Exception('Token não encontrado');
    }

    final response = await http.delete(
      Uri.parse('$endpointGrupos/$grupoId/com-exercicios'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Erro ao excluir grupo e exercícios: ${response.body}');
    }
  }

  // 📤 Upload de imagem do aluno (Flutter Web)
  Future<String> uploadImagemWeb() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final alunoId = prefs.getString('alunoId') ?? '';

    if (token.isEmpty || alunoId.isEmpty) {
      throw Exception('Credenciais inválidas');
    }

    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result == null ||
        result.files.isEmpty ||
        result.files.first.bytes == null) {
      throw Exception('Nenhuma imagem válida selecionada');
    }

    final fileBytes = result.files.first.bytes!;
    final originalName = result.files.first.name.toLowerCase();

    // Detecta tipo MIME com fallback
    MediaType contentType;
    if (originalName.endsWith('.png')) {
      contentType = MediaType('image', 'png');
    } else if (originalName.endsWith('.jpg') ||
        originalName.endsWith('.jpeg')) {
      contentType = MediaType('image', 'jpeg');
    } else {
      contentType = MediaType('application', 'octet-stream');
    }

    final fileName = '$alunoId.jpeg';
    final uri = Uri.parse('$endpointUpload/$alunoId');

    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..files.add(
        http.MultipartFile.fromBytes(
          'foto',
          fileBytes,
          filename: fileName,
          contentType: contentType,
        ),
      );

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      return responseBody;
    } else {
      throw Exception('Erro ao fazer upload da imagem: $responseBody');
    }
  }

  // 🖼️ Busca os bytes da imagem protegida do aluno
  Future<Uint8List> buscarImagemProtegida() async {
    final prefs = await SharedPreferences.getInstance();
    final alunoId = prefs.getString('alunoId') ?? '';
    final token = prefs.getString('token') ?? '';

    if (token.isEmpty || alunoId.isEmpty) {
      throw Exception('Credenciais inválidas');
    }

    final uri = Uri.parse('$endpointUploads/$alunoId.jpeg');
    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      throw Exception('Erro ao carregar imagem: ${response.statusCode}');
    }
  }

  // 🔗 Retorna a URL da imagem pública
  Future<String> buscarImagemUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final alunoId = prefs.getString('alunoId') ?? '';
    if (alunoId.isEmpty) throw Exception('ID do aluno não encontrado');
    return '$endpointUploads/$alunoId.jpeg';
  }

  // ✅ Verifica se a imagem existe
  Future<bool> imagemExiste() async {
    final prefs = await SharedPreferences.getInstance();
    final alunoId = prefs.getString('alunoId') ?? '';
    if (alunoId.isEmpty) return false;

    final uri = Uri.parse('$endpointUploads/$alunoId.jpeg');
    final response = await http.head(uri);
    return response.statusCode == 200;
  }
}
