import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educaai/models/user_model.dart';
import 'package:educaai/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxdart/rxdart.dart';

/// Gere todas as interações com o Firebase Authentication (Login, Registo, etc.)
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();

  /// Stream em tempo real do utilizador atual.
  /// Combina o estado de autenticação (Auth) com os dados do (Firestore).
  /// Isto notifica o 'Wrapper' sobre logins, logouts E atualizações de perfil
  /// (ex: 'quizCompleted' muda para 'true').
  Stream<UserModel?> get user {
    return _auth.authStateChanges().switchMap((User? firebaseUser) {
      if (firebaseUser == null) {
        // Se o utilizador estiver deslogado, emite 'null'.
        return Stream.value(null);
      } else {
        // Se o utilizador estiver logado, "ouve" o documento
        // dele no Firestore EM TEMPO REAL.
        return _firestoreService
            .getUserDocumentStream(firebaseUser.uid)
            .map((DocumentSnapshot doc) {
          if (doc.exists) {
            return UserModel.fromFirestore(doc);
          }
          return null;
        });
      }
    });
  }

  /// Regista um novo utilizador com e-mail/senha e cria o seu
  /// documento na base de dados Firestore.
  Future<UserModel?> registerWithEmail(
    String email,
    String password,
    String name,
    String gradeLevel,
  ) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? firebaseUser = result.user;

      if (firebaseUser == null) {
        return null;
      }

      UserModel newUser = UserModel(
        uid: firebaseUser.uid,
        email: email,
        name: name,
        gradeLevel: gradeLevel,
        hasAcceptedTerms: true, // Assumido como 'true' a partir do ecrã de registo
        quizCompleted: false, // O novo utilizador ainda NÃO fez o quiz
      );

      await _firestoreService.createUser(newUser);
      return newUser;
    } catch (e) {
      // ignore: avoid_print
      print(e.toString());
      return null;
    }
  }

  /// Efetua o login de um utilizador existente.
  Future<UserModel?> signInWithEmail(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? firebaseUser = result.user;
      if (firebaseUser == null) {
        return null;
      }
      
      // Retorna os dados do utilizador (o 'stream' 'user' tratará da atualização)
      DocumentSnapshot doc =
          await _firestoreService.getUserDocument(firebaseUser.uid);
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } on FirebaseAuthException {
      rethrow; // Relança o erro (ex: 'invalid-credential') para a UI
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  /// Envia um e-mail de redefinição de senha.
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  /// Reautentica o utilizador (necessário para ações sensíveis).
  Future<void> reauthenticate(String password) async {
    User? user = _auth.currentUser;
    if (user == null || user.email == null) {
      throw Exception('Utilizador não encontrado para reautenticação.');
    }
    AuthCredential credential = EmailAuthProvider.credential(
      email: user.email!,
      password: password,
    );
    await user.reauthenticateWithCredential(credential);
  }

  /// Inicia o fluxo de atualização de e-mail (envia e-mail de verificação).
  Future<void> updateUserEmail(String newEmail) async {
    try {
      await _auth.currentUser?.verifyBeforeUpdateEmail(newEmail);
    } on FirebaseAuthException {
      rethrow;
    }
  }

  /// Atualiza a senha do utilizador (requer reautenticação prévia).
  Future<void> updateUserPassword(String newPassword) async {
    try {
      await _auth.currentUser?.updatePassword(newPassword);
    } on FirebaseAuthException {
      rethrow;
    }
  }

  /// Apaga a conta do utilizador do Firebase Auth (requer reautenticação prévia).
  Future<void> deleteUserAccount() async {
    try {
      await _auth.currentUser?.delete();
    } on FirebaseAuthException {
      rethrow;
    }
  }

  /// Efetua o logout do utilizador atual.
  Future<void> signOut() async {
    try {
      return await _auth.signOut();
    } catch (e) {
      // ignore: avoid_print
      print(e.toString());
      return;
    }
  }
}