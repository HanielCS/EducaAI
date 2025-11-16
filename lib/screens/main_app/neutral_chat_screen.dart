import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educaai/models/message_model.dart';
import 'package:educaai/models/user_model.dart';
import 'package:educaai/services/firestore_service.dart';
import 'package:educaai/services/gemini_service.dart';
import 'package:educaai/widgets/chat_bubble.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class NeutralChatScreen extends StatefulWidget {
  const NeutralChatScreen({super.key});

  @override
  State<NeutralChatScreen> createState() => _NeutralChatScreenState();
}

class _NeutralChatScreenState extends State<NeutralChatScreen> {
  // Serviços e Controladores
  final FirestoreService _firestore = FirestoreService();
  final GeminiService _gemini = GeminiService();
  final _messageController = TextEditingController();

  // Estado da Conversa
  String? _conversationId;
  bool _isLoading = false;
  AsyncSnapshot<QuerySnapshot>? _streamSnapshot;

  // Perfil do Utilizador (carregado no initState)
  late String _currentUserId;
  String? _gradeLevel;
  String? _aiPersonality;
  String? _knowledgeLevel;

  // Constantes do Chat Neutro
  final String _neutralContext =
      "Aja como um assistente geral prestável e amigável. Responda a qualquer tipo de pergunta.";
  final String _neutralSubjectName = "Chat Geral";

  // Estado do Indicador "A Pensar"
  Timer? _thinkingTimer;
  int _thinkingMessageIndex = 0;
  String _thinkingMessage = 'A analisar...';
  static const List<String> _thinkingMessages = [
    'A analisar...',
    'A pensar...',
    'Aguarde um momento...',
    'Quase lá...',
  ];

  @override
  void initState() {
    super.initState();
    // Obtém os dados completos do utilizador (incluindo resultados do quiz)
    final user = Provider.of<UserModel?>(context, listen: false);
    if (user != null) {
      _currentUserId = user.uid;
      _gradeLevel = user.gradeLevel;
      _aiPersonality = user.aiPersonality;
      _knowledgeLevel = user.knowledgeLevel;
    } else {
      _currentUserId = ""; // Segurança, não deve acontecer
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _thinkingTimer?.cancel(); // Cancela o timer para evitar memory leaks
    super.dispose();
  }

  /// Inicia o temporizador que alterna as mensagens de "a pensar..."
  void _startThinkingTimer() {
    _thinkingTimer?.cancel();
    _thinkingMessageIndex = 0;
    setState(() {
      _thinkingMessage = _thinkingMessages[0];
    });

    _thinkingTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      _thinkingMessageIndex =
          (_thinkingMessageIndex + 1) % _thinkingMessages.length;
      setState(() {
        _thinkingMessage = _thinkingMessages[_thinkingMessageIndex];
      });
    });
  }

  /// Processa o envio de uma nova mensagem.
  Future<void> _sendMessage([String? text]) async {
    final messageText = text ?? _messageController.text.trim();
    if (messageText.isEmpty) return;

    if (text == null) _messageController.clear();

    setState(() {
      _isLoading = true;
      _startThinkingTimer();
    });

    // Cria a conversa no Firestore (apenas na primeira mensagem)
    _conversationId ??= await _firestore.createConversation(
      _currentUserId,
      messageText,
      _neutralSubjectName,
    );

    // Garante que o build() saiba o novo ID antes de continuar
    if (!mounted) return;
    setState(() {});

    // Envia a mensagem do utilizador
    final userMessage = MessageModel(
      sender: "user",
      text: messageText,
      timestamp: Timestamp.now(),
    );
    await _firestore.sendMessage(_currentUserId, _conversationId!, userMessage);

    // Constrói o histórico para a IA
    List<MessageModel> currentHistory = [];
    if (_streamSnapshot != null && _streamSnapshot!.hasData) {
      currentHistory = _streamSnapshot!.data!.docs
          .map((doc) => MessageModel.fromFirestore(doc))
          .toList()
          .reversed
          .toList();
    }

    // Chama o Gemini (passando o perfil do utilizador)
    final aiResponse = await _gemini.generateResponse(
      _neutralContext,
      currentHistory,
      messageText,
      _gradeLevel,
      _aiPersonality,
      _knowledgeLevel,
    );

    // Envia a resposta da IA
    final aiMessage = MessageModel(
      sender: "ai",
      text: aiResponse,
      timestamp: Timestamp.now(),
    );

    _thinkingTimer?.cancel(); // Para o timer

    await _firestore.sendMessage(_currentUserId, _conversationId!, aiMessage);

    setState(() {
      _isLoading = false; // Esconde o indicador "a pensar"
    });
  }

  /// Constrói a UI principal (o conteúdo da aba de Chat)
  @override
  Widget build(BuildContext context) {
    if (_currentUserId.isEmpty) {
      return const Center(
        child: Text("Erro: Utilizador não foi carregado corretamente."),
      );
    }

    return Column(
      children: [
        // Área das Mensagens
        Expanded(
          child: (_conversationId == null)
              // Placeholder (antes da primeira mensagem)
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      'Faça-me uma pergunta!',
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              // Lista de Mensagens (Stream)
              : StreamBuilder<QuerySnapshot>(
                  stream: _firestore.getMessages(
                    _currentUserId,
                    _conversationId!,
                  ),
                  builder: (context, snapshot) {
                    _streamSnapshot = snapshot;

                    final messages = snapshot.data?.docs ?? [];

                    if (snapshot.connectionState == ConnectionState.waiting &&
                        messages.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    return ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.symmetric(vertical: 10.0),
                      itemCount: messages.length + (_isLoading ? 1 : 0),
                      itemBuilder: (context, index) {
                        // Mostra a bolha "A pensar..."
                        if (_isLoading && index == 0) {
                          return ChatBubble(
                            text: _thinkingMessage,
                            isUser: false,
                          );
                        }

                        final msgIndex = _isLoading ? index - 1 : index;

                        final msg = MessageModel.fromFirestore(
                          messages[msgIndex],
                        );
                        final isUser = msg.sender == "user";
                        return ChatBubble(text: msg.text, isUser: isUser);
                      },
                    );
                  },
                ),
        ),

        // Área de Input
        _buildMessageInput(),
      ],
    );
  }

  /// Constrói a barra de input de texto
  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: 'Digite sua mensagem...',
                border: InputBorder.none,
              ),
              onSubmitted: (text) => _sendMessage(),
            ),
          ),
          IconButton(
            icon: Icon(Icons.send, color: Theme.of(context).primaryColor),
            onPressed: _isLoading ? null : () => _sendMessage(),
          ),
        ],
      ),
    );
  }
}
