import 'package:cloud_firestore/cloud_firestore.dart';

/// Define a estrutura de dados para uma única mensagem no chat.
class MessageModel {
  /// O autor da mensagem. Os valores esperados são "user" ou "ai".
  final String sender;

  /// O conteúdo de texto da mensagem (pode conter Markdown/LaTeX).
  final String text;

  /// A data e hora em que a mensagem foi criada.
  final Timestamp timestamp;

  MessageModel({
    required this.sender,
    required this.text,
    required this.timestamp,
  });

  /// Converte um [DocumentSnapshot] do Firestore num objeto [MessageModel].
  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>? ?? {};

    return MessageModel(
      sender: data['sender'] ?? 'ai', // Define 'ai' como padrão se houver erro
      text: data['text'] ?? '',
      // Fornece um Timestamp atual como fallback se o dado estiver em falta
      timestamp: data['timestamp'] ?? Timestamp.now(),
    );
  }

  /// Converte este objeto [MessageModel] num [Map] para ser guardado no Firestore.
  Map<String, dynamic> toMap() {
    return {'sender': sender, 'text': text, 'timestamp': timestamp};
  }
}
