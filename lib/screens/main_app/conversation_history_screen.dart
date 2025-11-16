import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educaai/models/user_model.dart';
import 'package:educaai/screens/main_app/chat_screen.dart';
import 'package:educaai/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Ecrã (Aba 2) que exibe a lista de todas as conversas
/// passadas do utilizador (histórico).
class ConversationHistoryScreen extends StatefulWidget {
  const ConversationHistoryScreen({super.key});

  @override
  State<ConversationHistoryScreen> createState() =>
      _ConversationHistoryScreenState();
}

class _ConversationHistoryScreenState extends State<ConversationHistoryScreen> {
  final FirestoreService _firestore = FirestoreService();
  late String _currentUserId;

  @override
  void initState() {
    super.initState();
    // Obtém o utilizador para que possamos ler o seu histórico
    final user = Provider.of<UserModel?>(context, listen: false);
    if (user != null) {
      _currentUserId = user.uid;
    } else {
      _currentUserId = ""; // Segurança, não deve acontecer
    }
  }

  /// Mapeia o nome da matéria (salvo no chat) de volta
  /// para o prompt de contexto que o Gemini precisa.
  String _getContextFromSubject(String subject) {
    switch (subject) {
      case 'Matemática':
        return 'Aja como um professor de matemática para o ensino fundamental.';
      case 'Ciências':
        return 'Aja como um professor de ciências para o ensino fundamental.';
      case 'História':
        return 'Aja como um professor de história para o ensino fundamental.';
      case 'Geografia':
        return 'Aja como um professor de geografia, explicando sobre mapas, climas e culturas.';
      case 'Português':
        return 'Aja como um professor de português e literatura, focado em gramática.';
      // Adicione mais matérias aqui...

      case 'Chat Geral':
      default:
        return 'Aja como um assistente geral prestável e amigável. Responda a qualquer tipo de pergunta.';
    }
  }

  /// Navega para um ecrã de chat existente.
  void _openExistingChat(DocumentSnapshot conversation) {
    final data = conversation.data() as Map<String, dynamic>;
    final String subject = data['subject'] ?? 'Chat Geral';
    final String subjectContext = _getContextFromSubject(subject);
    final String conversationId = conversation.id;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          subjectContext: subjectContext,
          subjectName: subject,
          conversationId: conversationId, // Passa o ID existente
          initialPrompt: null,
        ),
      ),
    );
  }

  /// Navega para um novo ecrã de chat "Geral" (neutro).
  void _startNewNeutralChat() {
    const String neutralContext =
        'Aja como um assistente geral prestável e amigável. Responda a qualquer tipo de pergunta.';
    const String neutralSubject = 'Chat Geral';

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          subjectContext: neutralContext,
          subjectName: neutralSubject,
          conversationId: null, // ID é nulo (força a criação de um novo chat)
          initialPrompt: null,
        ),
      ),
    );
  }

  /// Apaga uma conversa do Firestore.
  void _deleteChat(String conversationId) {
    _firestore.deleteConversation(_currentUserId, conversationId);

    // Mostra uma confirmação (SnackBar)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Conversa apagada.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserId.isEmpty) {
      return const Center(child: Text('Erro: Utilizador não encontrado.'));
    }

    // Um Scaffold é necessário aqui para permitir o FloatingActionButton
    // nesta aba específica do PageView.
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.getConversations(_currentUserId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Text(
                  'Nenhuma conversa encontrada.\n\nInicie um novo chat no botão (+)!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ),
            );
          }

          final conversations = snapshot.data!.docs;

          // Mostra a lista de conversas
          return ListView.builder(
            itemCount: conversations.length,
            itemBuilder: (context, index) {
              final convo = conversations[index];
              final data = convo.data() as Map<String, dynamic>;
              final title = data['title'] ?? 'Chat sem título';
              final subject = data['subject'] ?? 'Geral';

              // O Dismissible permite o "arrastar para apagar"
              return Dismissible(
                key: Key(convo.id), // Chave única
                direction: DismissDirection.endToStart, // Arrastar da direita
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (direction) {
                  _deleteChat(convo.id);
                },
                child: ListTile(
                  leading: Icon(
                    subject == 'Chat Geral'
                        ? Icons.chat_bubble_outline
                        : Icons.school_outlined,
                  ),
                  title: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(subject),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _openExistingChat(convo),
                ),
              );
            },
          );
        },
      ),
      // Botão Flutuante para iniciar um novo "Chat Geral"
      floatingActionButton: FloatingActionButton(
        onPressed: _startNewNeutralChat,
        // Usa 'colorScheme' para se adaptar ao Modo Escuro
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        child: const Icon(Icons.add),
      ),
    );
  }
}
