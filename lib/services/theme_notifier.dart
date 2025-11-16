import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Gere o estado do tema da aplicação (Claro/Escuro) e persiste a
/// preferência do utilizador no armazenamento local.
class ThemeNotifier with ChangeNotifier {
  final String _key = "themeMode";
  late ThemeMode _themeMode;

  /// Getter para o tema atual.
  ThemeMode get themeMode => _themeMode;

  ThemeNotifier() {
    // Define um valor padrão antes de carregar o tema guardado
    _themeMode = ThemeMode.light;
    _loadTheme();
  }

  /// Lê a preferência do tema do armazenamento local na inicialização.
  void _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeString = prefs.getString(_key) ?? ThemeMode.light.toString();
    _themeMode = ThemeMode.values.firstWhere(
      (e) => e.toString() == themeString,
      orElse: () => ThemeMode.light,
    );
    // Notifica os 'ouvintes' (o main.dart) assim que o tema guardado é carregado.
    notifyListeners();
  }

  /// Define o novo tema, notifica a UI e guarda a preferência.
  void setTheme(ThemeMode themeMode) async {
    if (themeMode == _themeMode) return; // Não faz nada se o tema for o mesmo

    _themeMode = themeMode;
    notifyListeners(); // Notifica a UI para mudar o tema IMEDIATAMENTE

    // Guarda a preferência em segundo plano
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(_key, _themeMode.toString());
  }
}
