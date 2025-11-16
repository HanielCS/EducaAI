import 'package:cloud_firestore/cloud_firestore.dart';

/// Define a estrutura de dados para um utilizador da aplicação.
/// Contém informações de autenticação, perfil e preferências.
class UserModel {
  final String uid;
  final String? email;
  final String? name;
  final String? gradeLevel;
  final String? avatarUrl;
  final bool? hasAcceptedTerms;

  // Campos do Quiz de Personalização
  final bool? quizCompleted;
  final String? aiPersonality;
  final String? knowledgeLevel;

  UserModel({
    required this.uid,
    this.email,
    this.name,
    this.gradeLevel,
    this.avatarUrl,
    this.hasAcceptedTerms,
    this.quizCompleted,
    this.aiPersonality,
    this.knowledgeLevel,
  });

  /// Converte um [DocumentSnapshot] do Firestore num objeto [UserModel].
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    // Assegura que os dados são um Map, mesmo que estejam vazios
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>? ?? {};

    return UserModel(
      uid: doc.id,
      email: data['email'],
      name: data['name'],
      gradeLevel: data['gradeLevel'],
      avatarUrl: data['avatarUrl'],
      hasAcceptedTerms: data['hasAcceptedTerms'],
      quizCompleted: data['quizCompleted'],
      aiPersonality: data['aiPersonality'],
      knowledgeLevel: data['knowledgeLevel'],
    );
  }

  /// Converte este objeto [UserModel] num [Map] para ser guardado no Firestore.
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'gradeLevel': gradeLevel,
      'avatarUrl': avatarUrl,
      'hasAcceptedTerms': hasAcceptedTerms,
      'quizCompleted': quizCompleted,
      'aiPersonality': aiPersonality,
      'knowledgeLevel': knowledgeLevel,
    };
  }

  /// Cria uma cópia deste [UserModel] com os campos atualizados.
  UserModel copyWith({
    String? uid,
    String? email,
    String? name,
    String? gradeLevel,
    String? avatarUrl,
    bool? hasAcceptedTerms,
    bool? quizCompleted,
    String? aiPersonality,
    String? knowledgeLevel,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      gradeLevel: gradeLevel ?? this.gradeLevel,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      hasAcceptedTerms: hasAcceptedTerms ?? this.hasAcceptedTerms,
      quizCompleted: quizCompleted ?? this.quizCompleted,
      aiPersonality: aiPersonality ?? this.aiPersonality,
      knowledgeLevel: knowledgeLevel ?? this.knowledgeLevel,
    );
  }
}
