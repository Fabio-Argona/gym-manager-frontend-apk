import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService extends ChangeNotifier {
  final String baseUrl = 'https://gym-manager-java.onrender.com';

  // LOGIN
  Future<bool> login(String email, String senha) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': senha}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();

        final token = data['token']?.toString();
        final aluno = data['aluno'];
        final nome = aluno?['nome']?.toString();
        final id = aluno?['id']?.toString();

        if (token != null && nome != null && id != null) {
          await prefs.setString('token', token);
          await prefs.setString('nome', nome);
          await prefs.setString('alunoId', id);
          return true;
        }
      } else {
        final erro = _extrairMensagemErro(response);
        throw Exception(erro);
      }
    } catch (e) {
      throw Exception('Erro ao autenticar: ${e.toString().replaceAll('Exception: ', '')}');
    }

    return false;
  }

  // REGISTRO
  Future<bool> register(Map<String, dynamic> dados) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(dados),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final body = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', body['token']);
        await prefs.setString('nome', body['aluno']['nome']);
        await prefs.setString('alunoId', body['aluno']['id']);
        return true;
      } else {
        final erro = _extrairMensagemErro(response);
        throw Exception(erro);
      }
    } catch (e) {
      throw Exception('Erro ao cadastrar: ${e.toString().replaceAll('Exception: ', '')}');
    }
  }

  // ATUALIZAR NOME
  Future<bool> atualizarNome(String novoNome, String alunoId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.put(
      Uri.parse('$baseUrl/alunos/$alunoId/nome'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'nome': novoNome}),
    );

    if (response.statusCode == 200) {
      await prefs.setString('nome', novoNome);
      return true;
    }

    return false;
  }

  // ATUALIZAR PERFIL COMPLETO
  Future<bool> atualizarPerfil({
    required String alunoId,
    required String nome,
    required String telefone,
    required String dataNascimento,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.put(
      Uri.parse('$baseUrl/alunos/$alunoId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'nome': nome,
        'telefone': telefone,
        'dataNascimento': dataNascimento,
      }),
    );

    if (response.statusCode == 200) {
      await prefs.setString('nome', nome);
      return true;
    }

    return false;
  }

  // RECUPERAR NOME SALVO
  Future<String?> getNomeSalvo() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('nome');
  }

  // LOGOUT
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // MÉTODO AUXILIAR PARA ERROS
  String _extrairMensagemErro(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      if (body is String) return body;
      if (body is Map && body.containsKey('message')) return body['message'];
      return response.body;
    } catch (_) {
      return response.body.isNotEmpty ? response.body : 'Erro desconhecido';
    }
  }
}
