import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

/// Gere a seleção e o upload de imagens para o Firebase Storage.
class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  /// Abre a galeria ou a câmara para o utilizador escolher uma imagem.
  /// Retorna um [File] ou 'null' se o utilizador cancelar.
  Future<File?> pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 800, // Reduz o tamanho da imagem para poupar espaço
        imageQuality: 70, // Comprime a imagem
      );

      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      // ignore: avoid_print
      print("Erro ao escolher imagem: $e");
      return null;
    }
  }

  /// Faz o upload de um ficheiro de imagem de perfil para o Firebase Storage.
  /// Retorna a URL de download da imagem.
  Future<String> uploadProfilePicture(String uid, File image) async {
    try {
      // Define o caminho no Storage: 'profile_pictures/{userId}/profile.jpg'
      final ref = _storage
          .ref()
          .child('profile_pictures')
          .child(uid)
          .child('profile.jpg');

      await ref.putFile(image);
      final String downloadUrl = await ref.getDownloadURL();
      return downloadUrl;
    } on FirebaseException catch (e) {
      // ignore: avoid_print
      print("Erro no upload para o Storage: $e");
      rethrow; // Relança o erro para a UI (ecrã de perfil) o apanhar
    }
  }

  /// Apaga a foto de perfil antiga do utilizador (se existir).
  Future<void> deleteProfilePicture(String uid) async {
    try {
      final ref = _storage
          .ref()
          .child('profile_pictures')
          .child(uid)
          .child('profile.jpg');
      // Tenta apagar, ignora se o ficheiro não existir
      await ref.delete();
    } on FirebaseException catch (e) {
      // Se o erro for 'object-not-found', está tudo bem (não havia foto antiga).
      if (e.code != 'object-not-found') {
        // ignore: avoid_print
        print("Erro ao apagar foto antiga: $e");
      }
    }
  }
}
