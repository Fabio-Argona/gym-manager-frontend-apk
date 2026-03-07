import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'pages/page_login.dart';
import 'pages/home_page.dart';
import 'pages/recuperar_senha_page.dart';
import 'constants/app_theme.dart';
import 'providers/theme_provider.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> handleUnauthorized() async {
  final authService = AuthService();
  await authService.logout();
  navigatorKey.currentState?.pushNamedAndRemoveUntil('/login', (_) => false);
}

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static ThemeData _buildTheme(AppColors colors, Brightness brightness) {
    return ThemeData(
      brightness: brightness,
      fontFamily: 'Poppins',
      colorScheme: ColorScheme.fromSeed(
        seedColor: kPrimary,
        brightness: brightness,
      ),
      scaffoldBackgroundColor: colors.bg1,
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: colors.textSub,
        ),
        bodyMedium: TextStyle(fontSize: 16, color: colors.textSub),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: const TextStyle(fontSize: 16),
        ),
      ),
      extensions: [colors],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (_, tp, __) => MaterialApp(
        title: 'APEX Iron Gym',
        theme: _buildTheme(AppColors.light, Brightness.light),
        darkTheme: _buildTheme(AppColors.dark, Brightness.dark),
        themeMode: tp.mode,
        debugShowCheckedModeBanner: false,
        navigatorKey: navigatorKey,
        initialRoute: '/login',
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/login':
              return _criarRotaAnimada(const LoginPage());
            case '/home':
              final nome = settings.arguments as String? ?? 'Usuário';
              return _criarRotaAnimada(HomePage(nome: nome));
            case '/recuperar':
              return _criarRotaAnimada(const RecuperarSenhaPage());
            default:
              return _criarRotaAnimada(const LoginPage());
          }
        },
      ),
    );
  }

  Route _criarRotaAnimada(Widget page) {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        final offsetAnimation = Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));

        return SlideTransition(position: offsetAnimation, child: child);
      },
    );
  }
}
