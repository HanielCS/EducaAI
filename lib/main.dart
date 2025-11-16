import 'package:educaai/config/constants.dart';
import 'package:educaai/models/user_model.dart';
import 'package:educaai/screens/wrapper.dart';
import 'package:educaai/services/auth_service.dart';
import 'package:educaai/services/theme_notifier.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Inicia o Firebase App Check
  await FirebaseAppCheck.instance.activate(
    // ignore: deprecated_member_use
    androidProvider: AndroidProvider.playIntegrity,
    // ignore: deprecated_member_use
    appleProvider: AppleProvider.appAttest,
  );

  Gemini.init(apiKey: geminiAPIKEY);

  runApp(
    MultiProvider(
      providers: [
        StreamProvider<UserModel?>.value(
          value: AuthService().user,
          initialData: null,
        ),
        ChangeNotifierProvider<ThemeNotifier>(create: (_) => ThemeNotifier()),
      ],
      child: const EducaAIApp(),
    ),
  );
}

class EducaAIApp extends StatelessWidget {
  const EducaAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    // O 'Consumer' "ouve" as mudanças no ThemeNotifier...
    return Consumer<ThemeNotifier>(
      builder: (context, themeNotifier, child) {
        // ...e reconstrói o MaterialApp com o novo tema
        return MaterialApp(
          title: 'EducaAI',

          // Define o modo de tema com base no ThemeNotifier
          themeMode: themeNotifier.themeMode,

          // Tema Claro (Light Mode)
          theme: ThemeData(
            brightness: Brightness.light,
            primarySwatch: Colors.blue,
            appBarTheme: const AppBarTheme(
              elevation: 1,
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
            ),
          ),

          // Tema Escuro (Dark Mode)
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primarySwatch: Colors.blue,
            scaffoldBackgroundColor: Colors.grey[900],
            appBarTheme: AppBarTheme(
              elevation: 1,
              backgroundColor: Colors.grey[850],
              foregroundColor: Colors.white,
            ),
          ),

          debugShowCheckedModeBanner: false,
          home: const Wrapper(),
        );
      },
    );
  }
}
