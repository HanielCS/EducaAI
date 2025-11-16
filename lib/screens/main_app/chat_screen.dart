import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educaai/models/message_model.dart';
import 'package:educaai/models/user_model.dart';
import 'package:educaai/services/firestore_service.dart';
import 'package:educaai/services/gemini_service.dart';
import 'package:educaai/widgets/chat_bubble.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Ecrã de chat individual
class ChatScreen extends StatefulWidget {
  final String subjectContext;
  final String subjectName;
  final String? initialPrompt;
  final String? conversationId; // ID de um chat existente (opcional)

  const ChatScreen({
    super.key,
    required this.subjectContext,
    required this.subjectName,
    this.initialPrompt,
    this.conversationId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
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
  late String _currentSubjectContext;
  String? _gradeLevel;
  String? _aiPersonality;
  String? _knowledgeLevel;

  // Estado do Indicador "A Pensar"
  Timer? _thinkingTimer;
  int _thinkingMessageIndex = 0;
  String _thinkingMessage = 'A analisar...';
  static const List<String> _thinkingMessages = [
    'A analisar a sua pergunta...',
    'A pensar...',
    'A consultar a BNCC...',
    'A elaborar a resposta...',
  ];

  @override
  void initState() {
    super.initState();

    // Obtém os dados completos do utilizador (incluindo resultados do quiz)
    final user = Provider.of<UserModel?>(context, listen: false);
    if (user == null) {
      // Isto não deve acontecer se o Wrapper estiver funcional
      _currentUserId = "";
      return;
    }

    _currentUserId = user.uid;
    _currentSubjectContext = widget.subjectContext;
    _gradeLevel = user.gradeLevel;
    _aiPersonality = user.aiPersonality;
    _knowledgeLevel = user.knowledgeLevel;

    // Se um ID foi passado, carrega o chat existente
    if (widget.conversationId != null) {
      _conversationId = widget.conversationId;
    }

    // Se um prompt inicial foi passado (ex: da HomeScreen), envia-o
    if (widget.initialPrompt != null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _sendMessage(widget.initialPrompt!),
      );
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
      widget.subjectName,
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

    // Chama o Gemini (passando o perfil completo do utilizador)
    final aiResponse = await _gemini.generateResponse(
      _currentSubjectContext,
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

  /// Constrói a UI principal (ecrã de chat)
  @override
  Widget build(BuildContext context) {
    if (_currentUserId.isEmpty) {
      return const Scaffold(
        body: Center(
          child: Text("Erro: Utilizador não foi carregado corretamente."),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(widget.subjectName)),
      body: Column(
        children: [
          // Área das Mensagens
          Expanded(
            child: (_conversationId == null)
                // Placeholder (antes da primeira mensagem)
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text(
                        'Faça uma pergunta sobre ${widget.subjectName}!',
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
      ),
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
                hintText: 'Digite sua pergunta...',
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
