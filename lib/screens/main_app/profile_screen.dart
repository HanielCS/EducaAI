import 'dart:io';
import 'package:educaai/models/user_model.dart';
import 'package:educaai/services/auth_service.dart';
import 'package:educaai/services/firestore_service.dart';
import 'package:educaai/services/storage_service.dart';
import 'package:educaai/services/theme_notifier.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:educaai/config/terms_content.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

/// Controla o estado da tela de Perfil, que é dividida em duas abas:
/// Perfil (edição de dados) e Configurações (segurança, tema, etc.).
class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  // Serviços
  final AuthService _auth = AuthService();
  final FirestoreService _firestore = FirestoreService();
  final StorageService _storage = StorageService();

  // Chaves de formulário
  final _profileFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  // Controladores de texto
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Estado da UI
  late String _currentUserId;
  UserModel? _currentUserData;
  String? _selectedGrade;
  bool _isLoading = true;
  bool _isLoadingPhoto = false;

  final List<String> _gradeLevels = [
    "1º Ano",
    "2º Ano",
    "3º Ano",
    "4º Ano",
    "5º Ano",
    "6º Ano",
    "7º Ano",
    "8º Ano",
    "9º Ano",
  ];

  @override
  void initState() {
    super.initState();
    final user = Provider.of<UserModel?>(context, listen: false);
    if (user != null) {
      _currentUserId = user.uid;
      _loadUserData();
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    // Limpa os controladores quando o widget é destruído
    _nameController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Carrega os dados do utilizador do Firestore e preenche os campos
  void _loadUserData() async {
    if (_currentUserId.isEmpty) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    var userDoc = await _firestore.getUserDocument(_currentUserId);
    if (!mounted) return;

    if (userDoc.exists) {
      UserModel userData = UserModel.fromFirestore(userDoc);
      String? savedGrade = userData.gradeLevel;
      String? validGrade;

      // Valida se a série guardada ainda existe na nossa lista de opções
      if (savedGrade != null && _gradeLevels.contains(savedGrade)) {
        validGrade = savedGrade;
      } else {
        validGrade = null; // Força o 'hint' a aparecer
      }

      setState(() {
        _currentUserData = userData;
        _nameController.text = userData.name ?? '';
        _emailController.text = userData.email ?? '';
        _selectedGrade = validGrade;
        _isLoading = false;
      });
    } else {
      // Se o documento do utilizador não for encontrado
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Lança um URL (para os Termos de Uso, etc.)
  void _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível abrir o link: $url')),
        );
      }
    }
  }

  /// Mostra um pop-up para o utilizador escolher Câmera ou Galeria
  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (builder) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galeria'),
                onTap: () {
                  _pickAndUploadImage(ImageSource.gallery);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Câmera'),
                onTap: () {
                  _pickAndUploadImage(ImageSource.camera);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// Pega a imagem (câmera/galeria) e faz o upload
  Future<void> _pickAndUploadImage(ImageSource source) async {
    setState(() {
      _isLoadingPhoto = true;
    });

    try {
      final File? imageFile = await _storage.pickImage(source);
      if (imageFile == null) {
        setState(() {
          _isLoadingPhoto = false;
        });
        return;
      }

      final String newPhotoUrl = await _storage.uploadProfilePicture(
        _currentUserId,
        imageFile,
      );

      setState(() {
        _currentUserData = _currentUserData?.copyWith(avatarUrl: newPhotoUrl);
      });

      if (_currentUserData != null) {
        await _firestore.updateUser(_currentUserData!);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao enviar foto: $e')));
    } finally {
      setState(() {
        _isLoadingPhoto = false;
      });
    }
  }

  /// Salva as alterações de "Perfil" (Nome, Série)
  void _updateProfile() async {
    if (_profileFormKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      UserModel updatedUser = _currentUserData!.copyWith(
        name: _nameController.text.trim(),
        gradeLevel: _selectedGrade,
      );

      await _firestore.updateUser(updatedUser);
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _currentUserData = updatedUser; // Atualiza o estado local
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Perfil atualizado!')));
    }
  }

  /// Pede a senha do utilizador antes de uma ação de segurança
  Future<String?> _showPasswordReauthDialog() async {
    // Limpa o controlador de senha para segurança
    _currentPasswordController.clear();

    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirmação de Segurança'),
          content: TextField(
            controller: _currentPasswordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Digite sua senha atual',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(_currentPasswordController.text);
              },
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );
  }

  /// Salva o novo e-mail (requer reautenticação)
  void _updateEmail() async {
    if (!(_profileFormKey.currentState?.validate() ?? false)) return;

    final newEmail = _emailController.text.trim();
    if (newEmail == _currentUserData?.email) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Este já é o seu e-mail.')));
      return;
    }

    setState(() {
      _isLoading = true;
    });
    String? password;

    try {
      password = await _showPasswordReauthDialog();
      if (password == null || password.isEmpty) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      await _auth.reauthenticate(password);
      await _auth.updateUserEmail(newEmail);

      final updatedUser = _currentUserData!.copyWith(email: newEmail);
      await _firestore.updateUser(updatedUser);

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _currentUserData = updatedUser;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'E-mail alterado! Por favor, verifique seu novo e-mail.',
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro: ${e.message}')));
    } catch (e) {
      //...
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Altera a senha do utilizador
  void _updatePassword() async {
    if (!(_passwordFormKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _auth.reauthenticate(_currentPasswordController.text);
      await _auth.updateUserPassword(_newPasswordController.text);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Senha alterada com sucesso!')),
      );

      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro: ${e.message}')));
    } catch (e) {
      //...
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Apaga a conta do utilizador
  void _deleteAccount() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Conta'),
        content: const Text(
          'Tem certeza que deseja excluir sua conta? Esta ação é permanente e não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });
    String? password;

    try {
      password = await _showPasswordReauthDialog();
      if (password == null || password.isEmpty) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      await _auth.reauthenticate(password);

      // Apaga a foto do Storage (se existir)
      if (_currentUserData?.avatarUrl != null) {
        await _storage.deleteProfilePicture(_currentUserId);
      }

      // Apaga os dados do Firestore
      await _firestore.deleteUserData(_currentUserId);

      // Apaga a conta do Auth (isto faz o logout)
      await _auth.deleteUserAccount();

      // O Wrapper irá detetar o logout e navegar para o Login.
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro: ${e.message}')));
    } catch (e) {
      //...
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Constrói o widget principal
  @override
  Widget build(BuildContext context) {
    // Mostra um spinner enquanto os dados do utilizador carregam
    if (_isLoading && _currentUserData == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // Mostra um erro se os dados não puderem ser carregados
    if (_currentUserData == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Text(
            "Não foi possível carregar os dados do perfil. Tente fazer logout e login novamente.",
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // Estrutura principal da tela com Abas (Tabs)
    return DefaultTabController(
      length: 2, // "Perfil" e "Configurações"
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Perfil'),
              Tab(text: 'Configurações'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [_buildProfileTab(), _buildSettingsTab()],
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói o conteúdo da Aba "Perfil"
  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(32.0, 40.0, 32.0, 32.0),
      child: Form(
        key: _profileFormKey,
        child: Column(
          children: [
            // --- FOTO DE PERFIL ---
            Stack(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey.shade300,
                  backgroundImage: _currentUserData?.avatarUrl != null
                      ? NetworkImage(_currentUserData!.avatarUrl!)
                      : null,
                  child: _isLoadingPhoto
                      ? const CircularProgressIndicator()
                      : (_currentUserData?.avatarUrl == null
                            ? Icon(
                                Icons.person,
                                size: 60,
                                color: Colors.grey.shade700,
                              )
                            : null),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: IconButton(
                    icon: const Icon(Icons.camera_alt),
                    onPressed: _isLoadingPhoto ? null : _showImagePickerOptions,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // --- NOME ---
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nome Completo',
                border: OutlineInputBorder(),
              ),
              validator: (val) => val!.isEmpty ? 'Digite seu nome' : null,
            ),
            const SizedBox(height: 20),

            // --- SÉRIE ---
            DropdownButtonFormField<String>(
              initialValue: _selectedGrade,
              decoration: const InputDecoration(
                labelText: 'Sua Série',
                border: OutlineInputBorder(),
                hintText: 'Selecione sua série',
              ),
              items: _gradeLevels.map((String grade) {
                return DropdownMenuItem<String>(
                  value: grade,
                  child: Text(grade),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _selectedGrade = newValue;
                });
              },
              validator: (val) => val == null ? 'Selecione sua série' : null,
            ),
            const SizedBox(height: 30),

            // --- BOTÃO SALVAR (NOME/SÉRIE) ---
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _updateProfile,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Salvar Alterações',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
            const Divider(height: 40),

            // --- E-MAIL ---
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'E-mail',
                border: OutlineInputBorder(),
              ),
              validator: (val) => val!.isEmpty ? 'Digite seu e-mail' : null,
            ),
            const SizedBox(height: 20),

            // --- BOTÃO ALTERAR E-MAIL ---
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _isLoading ? null : _updateEmail,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Alterar E-mail',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Constrói o conteúdo da Aba "Configurações"
  Widget _buildSettingsTab() {
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(32.0, 40.0, 32.0, 32.0),
      child: Column(
        children: [
          // --- FORMULÁRIO DE ALTERAÇÃO DE SENHA ---
          Form(
            key: _passwordFormKey,
            child: Column(
              children: [
                Text(
                  'Alterar Senha',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _currentPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Senha Atual',
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) =>
                      val!.isEmpty ? 'Digite sua senha atual' : null,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _newPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Nova Senha',
                    border: OutlineInputBorder(),
                  ),
                  // Valida a nova senha (regras do Registo)
                  validator: _validateNewPassword,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirmar Nova Senha',
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) => val != _newPasswordController.text
                      ? 'As senhas não coincidem'
                      : null,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _updatePassword,
                    child: const Text('Definir Nova Senha'),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 40),

          // --- MODO ESCURO (Funcional) ---
          SwitchListTile(
            title: const Text('Modo Escuro'),
            value: themeNotifier.themeMode == ThemeMode.dark,
            onChanged: (val) {
              themeNotifier.setTheme(val ? ThemeMode.dark : ThemeMode.light);
            },
          ),

          // --- IDIOMA (Mock) ---
          ListTile(
            title: const Text('Idioma'),
            trailing: const Text('Português (BR)'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Feature ainda não implementada.'),
                ),
              );
            },
          ),

          // --- SECÇÃO "LEGAL" ---
          const Divider(height: 40),
          Text('Legal e Sobre', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 10),
          ListTile(
            title: const Text('Termos de Uso'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _launchURL(termsURL),
          ),
          ListTile(
            title: const Text('Política de Privacidade'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _launchURL(privacyURL),
          ),
          ListTile(
            title: const Text('Política de Cookies'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _launchURL(cookiesURL),
          ),
          ListTile(
            title: const Text('Gestão dos Seus Dados'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _launchURL(dataManagementURL),
          ),

          const Divider(height: 40),

          // --- EXCLUIR CONTA ---
          TextButton(
            onPressed: _isLoading ? null : _deleteAccount,
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text(
              'Excluir minha conta permanentemente',
              style: TextStyle(fontSize: 16),
            ),
          ),
          const SizedBox(height: 40),
          // --- LOGOUT ---
          TextButton(
            onPressed: () async {
              await _auth.signOut();
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.primary,
            ),
            child: const Text('Sair (Logout)', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  // Função 'helper' para validar a nova senha (igual ao ecrã de registo)
  String? _validateNewPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor, digite uma senha.';
    }
    if (value.length < 8) {
      return 'A senha deve ter no mínimo 8 caracteres.';
    }
    if (!RegExp(r'(?=.*[a-z])').hasMatch(value)) {
      return 'A senha deve conter uma letra minúscula.';
    }
    if (!RegExp(r'(?=.*[A-Z])').hasMatch(value)) {
      return 'A senha deve conter uma letra maiúscula.';
    }
    if (!RegExp(r'(?=.*\d)').hasMatch(value)) {
      return 'A senha deve conter um número.';
    }
    if (!RegExp(r'(?=.*[@$!%*?&])').hasMatch(value)) {
      return 'A senha deve conter um caractere especial (@\$!%*?&).';
    }
    return null; // Senha válida
  }
}

// Extensão 'copyWith' para o UserModel (para facilitar as atualizações)
extension UserModelCopyWith on UserModel {
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
