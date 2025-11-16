import 'package:educaai/services/auth_service.dart';
import 'package:educaai/screens/auth/register_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Tela de Login.
/// Permite que utilizadores existentes entrem na aplicação.
/// Também lida com a lógica de "Esqueceu sua senha?".
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _auth = AuthService();
  final _formKey = GlobalKey<FormState>();

  // Controladores de texto
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Estado da UI
  bool _isLoading = false;
  String _error = '';
  bool _showForgotPasswordLink = false; // Controla o link de "Esqueceu a senha"

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Tenta fazer o login do utilizador com e-mail e senha.
  void _submitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
        _error = '';
        _showForgotPasswordLink = false; // Esconde o link ao tentar de novo
      });

      try {
        await _auth.signInWithEmail(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );

        // Se o login for bem-sucedido, o Wrapper irá navegar.
        // Apenas paramos o 'loading' se a tela ainda estiver "montada".
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });
      } on FirebaseAuthException catch (e) {
        // Apanha erros específicos do Firebase
        setState(() {
          _isLoading = false;
          if (e.code == 'invalid-credential' || e.code == 'wrong-password') {
            _error = 'E-mail ou senha inválidos.';
            _showForgotPasswordLink = true; // Mostra o link de redefinição
          } else if (e.code == 'user-not-found') {
            _error = 'Nenhum utilizador encontrado com este e-mail.';
          } else {
            _error = 'Ocorreu um erro: ${e.message}';
          }
        });
      } catch (e) {
        // Apanha outros erros
        setState(() {
          _isLoading = false;
          _error = 'Ocorreu um erro inesperado.';
        });
      }
    }
  }

  /// Envia um e-mail de redefinição de senha para o e-mail no formulário.
  void _sendResetEmail() async {
    if (_emailController.text.trim().isEmpty) {
      setState(() {
        _error = 'Por favor, digite seu e-mail para redefinir a senha.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });
    try {
      await _auth.sendPasswordResetEmail(_emailController.text.trim());

      // Mostra uma SnackBar de sucesso
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('E-mail de redefinição enviado com sucesso!'),
          ),
        );
      }

      setState(() {
        _isLoading = false;
        _showForgotPasswordLink = false; // Esconde o link após o envio
        _error = '';
      });
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isLoading = false;
        if (e.code == 'user-not-found') {
          _error = 'Nenhum utilizador encontrado com este e-mail.';
        } else {
          _error = 'Erro ao enviar e-mail: ${e.message}';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'EducaAI',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      // Usa a cor primária do tema (adaptável ao Modo Escuro)
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 40),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'E-mail',
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) =>
                        val!.isEmpty ? 'Digite seu e-mail' : null,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Senha',
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) =>
                        val!.isEmpty ? 'Digite sua senha' : null,
                  ),
                  // Mostra mensagens de erro
                  if (_error.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Text(
                        _error,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  // Mostra o link de redefinição de senha (se o login falhar)
                  if (_showForgotPasswordLink)
                    Padding(
                      padding: const EdgeInsets.only(top: 10.0),
                      child: TextButton(
                        onPressed: _isLoading ? null : _sendResetEmail,
                        child: const Text(
                          'Esqueceu sua senha? Redefinir agora',
                        ),
                      ),
                    ),
                  const SizedBox(height: 30),
                  _isLoading
                      ? const CircularProgressIndicator()
                      : SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _submitForm,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text(
                              'Entrar',
                              style: TextStyle(fontSize: 18),
                            ),
                          ),
                        ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const RegisterScreen(),
                        ),
                      );
                    },
                    child: const Text('Não tem uma conta? Cadastre-se'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
