import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educaai/models/message_model.dart';
import 'package:educaai/models/user_model.dart';

/// Gere todas as interações com a base de dados Cloud Firestore.
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // -------------------------------------
  // ## Operações de Utilizador
  // -------------------------------------

  Future<void> createUser(UserModel user) async {
    await _db.collection('users').doc(user.uid).set(user.toMap());
  }

  /// Obtém um 'snapshot' único do documento do utilizador.
  Future<DocumentSnapshot> getUserDocument(String uid) async {
    return await _db.collection('users').doc(uid).get();
  }

  /// "Ouve" o documento do utilizador em tempo real.
  /// (Usado pelo AuthService para atualizar o estado do utilizador).
  Stream<DocumentSnapshot> getUserDocumentStream(String uid) {
    return _db.collection('users').doc(uid).snapshots();
  }

  Future<void> updateUser(UserModel user) async {
    await _db.collection('users').doc(user.uid).update(user.toMap());
  }

  Future<void> deleteUserData(String uid) async {
    try {
      await _db.collection('users').doc(uid).delete();
    } catch (e) {
      // ignore: avoid_print
      print("Erro ao apagar dados do utilizador no Firestore: $e");
      rethrow;
    }
  }

  /// Define 'hasAcceptedTerms' como 'true' para um utilizador.
  Future<void> acceptTerms(String uid) async {
    await _db.collection('users').doc(uid).update({'hasAcceptedTerms': true});
  }

  /// Guarda os resultados do quiz e marca o quiz como 'concluído'.
  Future<void> saveQuizResults(
    String uid,
    String personality,
    String knowledgeLevel,
  ) async {
    await _db.collection('users').doc(uid).update({
      'aiPersonality': personality,
      'knowledgeLevel': knowledgeLevel,
      'quizCompleted': true,
    });
  }

  // -------------------------------------
  // ## Operações de Configuração do App
  // -------------------------------------

  /// Obtém a configuração da tela inicial (módulos e sugestões).
  Future<DocumentSnapshot> getHomeScreenConfig() async {
    return await _db.collection('appConfig').doc('homeScreen').get();
  }

  // -------------------------------------
  // ## Operações de Chat
  // -------------------------------------

  /// "Ouve" a lista de conversas de um utilizador.
  Stream<QuerySnapshot> getConversations(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('conversations')
        .orderBy('lastMessageAt', descending: true)
        .snapshots();
  }

  /// Apaga o documento principal de uma conversa.
  Future<void> deleteConversation(String uid, String conversationId) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('conversations')
        .doc(conversationId)
        .delete();
  }

  /// Cria um novo documento de conversa e retorna o seu ID.
  Future<String> createConversation(
    String uid,
    String title,
    String subject,
  ) async {
    DocumentReference convoRef = await _db
        .collection('users')
        .doc(uid)
        .collection('conversations')
        .add({
          'title': title,
          'subject': subject,
          'lastMessageAt': Timestamp.now(),
        });
    return convoRef.id;
  }

  /// Adiciona um novo documento de mensagem a uma conversa.
  Future<void> sendMessage(
    String uid,
    String conversationId,
    MessageModel message,
  ) async {
    // Adiciona a mensagem
    await _db
        .collection('users')
        .doc(uid)
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .add(message.toMap());

    // Atualiza o 'lastMessageAt' da conversa principal para ordenação
    await _db
        .collection('users')
        .doc(uid)
        .collection('conversations')
        .doc(conversationId)
        .update({'lastMessageAt': message.timestamp});
  }

  /// "Ouve" a lista de mensagens de uma conversa específica.
  Stream<QuerySnapshot> getMessages(String uid, String conversationId) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }
}
