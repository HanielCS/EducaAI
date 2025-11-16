import 'package:educaai/config/terms_content.dart';
import 'package:educaai/services/auth_service.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final AuthService _auth = AuthService();
  final _formKey = GlobalKey<FormState>();

  // Controladores de texto
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  // Estado do formulário
  String? _selectedGrade;
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
  bool _isLoading = false;
  String _error = '';
  bool _termsAccepted = false; // Estado da checkbox

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  /// Tenta lançar um URL externo no navegador (para os Termos/Privacidade).
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

  /// Valida a senha de acordo com as regras de segurança (8+, A, a, 1, @).
  String? _validatePassword(String? value) {
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

  /// Tenta submeter o formulário de registo.
  void _submitForm() async {
    // Valida o formulário E a checkbox de termos
    if (!(_formKey.currentState?.validate() ?? false)) {
      return; // Se o formulário (incluindo a checkbox) for inválido, para.
    }

    if (_selectedGrade == null) {
      setState(() {
        _error = 'Por favor, selecione sua série.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      dynamic result = await _auth.registerWithEmail(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _nameController.text.trim(),
        _selectedGrade!,
      );

      if (!mounted) return;

      if (result == null) {
        setState(() {
          _error = 'Ocorreu um erro. Verifique se o e-mail já está em uso.';
          _isLoading = false;
        });
      } else {
        // Sucesso, fecha o ecrã de registo
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Ocorreu um erro: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Criar Conta')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nome Completo',
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) => val!.isEmpty ? 'Digite seu nome' : null,
                ),
                const SizedBox(height: 20),
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
                  validator: (val) =>
                      val == null ? 'Selecione sua série' : null,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'E-mail',
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) => val!.isEmpty ? 'Digite seu e-mail' : null,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Senha',
                    border: OutlineInputBorder(),
                  ),
                  validator: _validatePassword,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                ),
                const SizedBox(height: 20),

                // Checkbox dos Termos de Uso e Privacidade
                FormField<bool>(
                  builder: (state) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CheckboxListTile(
                          title: RichText(
                            text: TextSpan(
                              style: Theme.of(context).textTheme.bodyMedium,
                              children: [
                                TextSpan(text: '$termsCheckboxText '),
                                TextSpan(
                                  text: termsLinkText,
                                  style: const TextStyle(
                                    color: Colors.blue,
                                    decoration: TextDecoration.underline,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () => _launchURL(termsURL),
                                ),
                                const TextSpan(text: ' e a '),
                                TextSpan(
                                  text: privacyLinkText,
                                  style: const TextStyle(
                                    color: Colors.blue,
                                    decoration: TextDecoration.underline,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () => _launchURL(privacyURL),
                                ),
                              ],
                            ),
                          ),
                          value: _termsAccepted,
                          onChanged: (value) {
                            setState(() {
                              _termsAccepted = value ?? false;
                              state.didChange(value);
                            });
                          },
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                        ),
                        // Mostra o erro da checkbox
                        if (state.errorText != null)
                          Padding(
                            padding: const EdgeInsets.only(left: 12.0),
                            child: Text(
                              state.errorText!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                  validator: (value) {
                    // Este validador é chamado quando _formKey.currentState.validate()
                    // é executado no _submitForm
                    if (_termsAccepted == false) {
                      return 'Você deve aceitar os termos para continuar.';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),
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
                            'Cadastrar',
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                if (_error.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Text(
                      _error,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
