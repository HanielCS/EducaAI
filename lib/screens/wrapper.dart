import 'package:educaai/models/user_model.dart';
import 'package:educaai/screens/auth/login_screen.dart';
import 'package:educaai/screens/auth/terms_screen.dart';
import 'package:educaai/screens/auth/quiz_screen.dart';
import 'package:educaai/screens/main_app/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Wrapper extends StatelessWidget {
  const Wrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserModel?>(context);

    // Caso 1: Utilizador não está logado
    if (user == null) {
      return const LoginScreen();
    }

    // Caso 2: Utilizador está logado, mas não aceitou os Termos
    // (Verificamos '!= true' para apanhar 'false' E 'null' (utilizadores antigos))
    if (user.hasAcceptedTerms != true) {
      return const TermsScreen();
    }

    // Caso 3: Utilizador está logado, aceitou os Termos, mas não completou o Quiz
    if (user.quizCompleted != true) {
      return const QuizScreen();
    }

    // Caso 4: Utilizador está logado, aceitou os Termos E completou o Quiz
    return const MainScreen();
  }
}
