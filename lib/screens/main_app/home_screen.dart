import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educaai/models/user_model.dart';
import 'package:educaai/screens/main_app/chat_screen.dart';
import 'package:educaai/services/firestore_service.dart';
import 'package:educaai/widgets/subject_module_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// O ecrã principal (Aba 1) da aplicação.
/// Mostra os módulos de matérias e as sugestões de chat.
class HomeScreen extends StatefulWidget {
  final PageController pageController;

  const HomeScreen({super.key, required this.pageController});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  /// Navega para um ecrã de chat dedicado (para uma matéria ou sugestão).
  void _startChat(
    String subjectContext,
    String subjectName,
    String? initialPrompt,
  ) {
    // Usa 'Navigator.push' para "empurrar" o ecrã de chat por cima
    // da navegação principal (Abas).
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          subjectContext: subjectContext,
          subjectName: subjectName,
          initialPrompt: initialPrompt,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserModel?>(context);
    if (user == null) {
      return const Center(child: Text("Utilizador não encontrado."));
    }

    // O widget principal é um FutureBuilder que busca a configuração
    // da tela inicial (módulos e sugestões) no Firestore.
    return FutureBuilder<DocumentSnapshot>(
      future: _firestoreService.getHomeScreenConfig(),
      builder: (context, snapshot) {
        // 1. Estado de Carregamento
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // 2. Estado de Erro
        if (snapshot.hasError) {
          return const Center(
            child: Text('Erro ao carregar os dados. Tente novamente.'),
          );
        }

        // 3. Estado de Dados Inexistentes
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Text(
                'Erro: O documento de configuração "appConfig/homeScreen" não foi encontrado no Firebase. Por favor, crie-o na consola.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        // 4. Estado de Sucesso
        Map<String, dynamic> data =
            snapshot.data!.data() as Map<String, dynamic>;
        List<dynamic> modules = data['subjectModules'] ?? [];
        List<dynamic> prompts = data['suggestedPrompts'] ?? [];

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título (O botão de perfil foi removido por si)
              const Text(
                'Explore por Matéria',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              // Lista horizontal de Módulos
              SizedBox(
                height: 150,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: modules.length,
                  itemBuilder: (context, index) {
                    var module = modules[index];
                    return SubjectModuleCard(
                      name: module['name'],
                      iconData: _getIconForSubject(module['icon']),
                      color: Color(int.parse(module['color'])),
                      onTap: () {
                        _startChat(
                          module['promptContext'],
                          module['name'],
                          null, // Sem prompt inicial
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Sugestões para Si',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              // Lista vertical de Sugestões
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: prompts.length,
                itemBuilder: (context, index) {
                  var prompt = prompts[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12.0),
                    child: ListTile(
                      title: Text(prompt['text']),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        _startChat(
                          prompt['promptContext'],
                          "Sugestão",
                          prompt['text'],
                        );
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// Função auxiliar para converter o nome do ícone (do Firebase)
  /// num IconData (do Flutter).
  IconData _getIconForSubject(String iconName) {
    switch (iconName) {
      case 'calculator':
        return Icons.calculate;
      case 'science':
        return Icons.science;
      case 'history_edu':
        return Icons.history_edu;
      case 'book':
        return Icons.menu_book;
      case 'translate':
        return Icons.translate;
      case 'public':
        return Icons.public;
      case 'language':
        return Icons.language;
      case 'palette':
        return Icons.palette;
      default:
        return Icons.school;
    }
  }
}
