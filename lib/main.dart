import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'pages/page_login.dart';
import 'pages/home_page.dart';
import 'pages/recuperar_senha_page.dart';
import 'pages/redefinir_senha_page.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Full Performance',
      theme: ThemeData(
        brightness: Brightness.dark,
        fontFamily: 'Poppins',
        textTheme: const TextTheme(
          headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          bodyMedium: TextStyle(fontSize: 16),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 16),
            textStyle: TextStyle(fontSize: 16),
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: '/login',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/login':
            return _criarRotaAnimada(const LoginPage());
          case '/home':
            return _criarRotaAnimada(const HomePage(nome: 'Usuário'));
          case '/recuperar':
            return _criarRotaAnimada(const RecuperarSenhaPage());
          case '/redefinir':
            return _criarRotaAnimada(const RedefinirSenhaPage());
          default:
            return _criarRotaAnimada(const LoginPage());
        }
      },
    );
  }

  Route _criarRotaAnimada(Widget page) {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        final offsetAnimation = Tween<Offset>(
          begin: const Offset(1.0, 0.0), // desliza da direita
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));

        return SlideTransition(position: offsetAnimation, child: child);
      },
    );
  }
}
