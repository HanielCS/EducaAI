import 'package:educaai/models/user_model.dart';
import 'package:educaai/services/auth_service.dart';
import 'package:educaai/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Ecrã de "boas-vindas" que aparece uma vez após o registo.
/// Recolhe as preferências de personalidade e nível da IA
/// para personalizar as respostas do Gemini.
class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final FirestoreService _firestore = FirestoreService();
  final AuthService _auth = AuthService();

  // Estado das seleções do utilizador
  String? _selectedPersonality;
  String? _selectedLevel;
  bool _isLoading = false;

  /// Guarda as seleções do utilizador no Firestore e marca o quiz como concluído.
  void _saveQuizResults(String uid) async {
    // Valida se ambas as opções foram selecionadas
    if (_selectedPersonality == null || _selectedLevel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecione uma opção em cada categoria.'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _firestore.saveQuizResults(
        uid,
        _selectedPersonality!,
        _selectedLevel!,
      );
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
    // Obtém o utilizador (necessário para o UID)
    final user = Provider.of<UserModel?>(context);

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Erro: Utilizador não encontrado.')),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Personalize a sua IA!',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Como você prefere que o EducaAI fale consigo?',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Seletor de Personalidade
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'Amigável',
                      label: Text('Amigável'),
                      icon: Icon(Icons.sentiment_satisfied_alt),
                    ),
                    ButtonSegment(
                      value: 'Professor',
                      label: Text('Professor'),
                      icon: Icon(Icons.school),
                    ),
                    ButtonSegment(
                      value: 'Divertido',
                      label: Text('Divertido'),
                      icon: Icon(Icons.celebration),
                    ),
                  ],
                  selected: _selectedPersonality == null
                      ? {}
                      : {_selectedPersonality!},
                  onSelectionChanged: (Set<String> newSelection) {
                    setState(() {
                      _selectedPersonality = newSelection.first;
                    });
                  },
                  emptySelectionAllowed: true, // Permite começar vazio
                  showSelectedIcon: false,
                ),

                const SizedBox(height: 40),

                Text(
                  'Qual o seu nível de conhecimento?',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Seletor de Nível de Conhecimento
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'Iniciante',
                      label: Text('Iniciante'),
                      icon: Icon(Icons.child_care),
                    ),
                    ButtonSegment(
                      value: 'Intermediário',
                      label: Text('Intermediário'),
                      icon: Icon(Icons.lightbulb_outline),
                    ),
                    ButtonSegment(
                      value: 'Avançado',
                      label: Text('Avançado'),
                      icon: Icon(Icons.auto_awesome),
                    ),
                  ],
                  selected: _selectedLevel == null ? {} : {_selectedLevel!},
                  onSelectionChanged: (Set<String> newSelection) {
                    setState(() {
                      _selectedLevel = newSelection.first;
                    });
                  },
                  emptySelectionAllowed: true, // Permite começar vazio
                  showSelectedIcon: false,
                ),

                const SizedBox(height: 40),

                // Botão de Submissão
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        // O botão só é ativado se ambas as opções forem selecionadas
                        onPressed:
                            (_selectedPersonality != null &&
                                _selectedLevel != null)
                            ? () => _saveQuizResults(user.uid)
                            : null,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'Começar a Aprender!',
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
      ),
    );
  }
}
