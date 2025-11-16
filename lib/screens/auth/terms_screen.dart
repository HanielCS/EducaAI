import 'package:educaai/config/terms_content.dart';
import 'package:educaai/models/user_model.dart';
import 'package:educaai/services/auth_service.dart';
import 'package:educaai/services/firestore_service.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

/// Ecrã de bloqueio que força os utilizadores (especialmente os antigos
/// que ainda não aceitaram os termos) a aceitarem os Termos de Uso
/// e a Política de Privacidade antes de usarem a aplicação.
class TermsScreen extends StatefulWidget {
  const TermsScreen({super.key});

  @override
  State<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends State<TermsScreen> {
  final FirestoreService _firestore = FirestoreService();
  final AuthService _auth = AuthService();
  bool _isLoading = false;

  /// Tenta lançar um URL externo no navegador.
  void _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível abrir o link: $url')),
        );
      }
    }
  }

  /// Chamado quando o utilizador clica em "Aceitar".
  /// Atualiza o 'hasAcceptedTerms' no Firestore.
  void _onAccept(String uid) async {
    setState(() {
      _isLoading = true;
    });
    try {
      await _firestore.acceptTerms(uid);
      // O 'Wrapper' irá detectar esta mudança e navegar automaticamente
      // para a MainScreen.
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ocorreu um erro: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Obtém o utilizador (precisamos do UID dele)
    final user = Provider.of<UserModel?>(context);

    // Este ecrã nunca deve ser acedido se o utilizador estiver nulo
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Erro: Utilizador não encontrado.')),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                termsAndPrivacyTitle, // Vindo do 'terms_content.dart'
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              const Text(
                'Para continuar a usar o EducaAI, por favor, reveja e aceite os nossos Termos de Uso e Política de Privacidade atualizados.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  // Garante que o texto usa a cor correta do tema
                  style: Theme.of(context).textTheme.bodyMedium,
                  children: [
                    TextSpan(text: '$termsCheckboxText '),
                    TextSpan(
                      text: termsLinkText, // "Termos de Uso"
                      style: const TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () => _launchURL(termsURL),
                    ),
                    const TextSpan(text: ' e confirma que leu a nossa '),
                    TextSpan(
                      text: privacyLinkText, // "Política de Privacidade"
                      style: const TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () => _launchURL(privacyURL),
                    ),
                    const TextSpan(text: ' e '),
                    TextSpan(
                      text: cookiesLinkText, // "Política de Cookies"
                      style: const TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () => _launchURL(cookiesURL),
                    ),
                    const TextSpan(text: '.'),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: () => _onAccept(user.uid),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Aceitar e Continuar',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => _auth.signOut(),
                child: const Text(
                  'Sair (Logout)',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
