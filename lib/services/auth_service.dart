import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService with ChangeNotifier {
  final String _baseUrl = 'https://gym-manager-java.onrender.com/auth';


  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  Future<bool> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data['token'];
      final aluno = data['aluno'];

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      await prefs.setString('aluno_nome', aluno['nome']);
      await prefs.setString('aluno_id', aluno['id']);

      Fluttertoast.showToast(msg: "Login realizado com sucesso!");
      return true;
    } else {
      Fluttertoast.showToast(msg: "Erro ao fazer login: ${response.body}");
      return false;
    }
  }

  Future<bool> register(Map<String, dynamic> userData) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(userData),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data['token'];
      final aluno = data['aluno'];

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      await prefs.setString('aluno_nome', aluno['nome']);
      await prefs.setString('aluno_id', aluno['id']);

      Fluttertoast.showToast(msg: "Cadastro realizado com sucesso!");
      return true;
    } else {
      Fluttertoast.showToast(msg: "Erro ao cadastrar: ${response.body}");
      return false;
    }
  }
}
