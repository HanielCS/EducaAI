import 'package:educaai/models/message_model.dart';
import 'package:flutter_gemini/flutter_gemini.dart';

/// Gere a comunicação com a API do Google Gemini.
class GeminiService {
  final gemini = Gemini.instance;

  /// Gera uma resposta da IA baseada no histórico, contexto, e perfil do utilizador.
  Future<String> generateResponse(
    String systemContext,
    List<MessageModel> messageHistory,
    String newPrompt,
    String? gradeLevel,
    String? aiPersonality,
    String? knowledgeLevel,
  ) async {
    try {
      List<Content> historyForGemini = [];

      // Define valores padrão para os novos campos (caso sejam nulos)
      final String userGrade = gradeLevel ?? "ensino fundamental (geral)";
      final String personality = aiPersonality ?? "Amigável";
      final String level = knowledgeLevel ?? "Iniciante";

      // Esta é a instrução principal que o Gemini vai seguir,
      // incorporando a BNCC, a Série, a Personalidade e o Nível.
      final String masterPrompt =
          """
**MISSÃO:** Você é o EducaAI, um tutor de IA para alunos do ensino fundamental no Brasil.

**REGRA PRINCIPAL (OBRIGATÓRIO):** Suas respostas DEVEM ser estritamente baseadas e alinhadas com a **Base Nacional Comum Curricular (BNCC)** do Brasil.

**PÚBLICO-ALVO (OBRIGATÓRIO):**
* **Série/Ano:** Você DEVE adaptar a complexidade da sua resposta para um aluno do: **$userGrade**.
* **Nível de Conhecimento:** O aluno auto-avaliou-se como: **$level**. Ajuste a profundidade da sua resposta de acordo.

**PERSONALIDADE (OBRIGATÓRIO):**
* Você DEVE adotar o seguinte tom de voz e personalidade: **$personality**. (Ex: "Amigável" = use emojis, linguagem casual; "Professor" = seja mais formal; "Divertido" = use piadas leves).

**FOCO ATUAL (MATÉRIA):** $systemContext

**FORMATO:** Responda em português do Brasil, de forma clara e pedagógica. Use formatação Markdown (como **negrito**) e LaTeX (como \$f(x) = a^x\$) quando apropriado.
""";

      String promptParaEnviar;

      if (messageHistory.isEmpty) {
        // Se for a primeira mensagem do chat, envia o Super Prompt
        // completo junto com a pergunta.
        promptParaEnviar =
            """
$masterPrompt

---

**PERGUNTA DO ALUNO:**
$newPrompt
""";
      } else {
        // Se for uma continuação, o Gemini já tem o contexto.
        // Envia apenas a nova pergunta.
        promptParaEnviar = newPrompt;

        // E adiciona o histórico anterior
        historyForGemini.addAll(
          messageHistory.map((msg) {
            return Content(
              role: msg.sender == "user" ? "user" : "model",
              parts: [Part.text(msg.text)],
            );
          }).toList(),
        );
      }

      // Adiciona o prompt final (seja ele o 'master' ou o simples)
      historyForGemini.add(
        Content(role: "user", parts: [Part.text(promptParaEnviar)]),
      );

      final response = await gemini.chat(historyForGemini);

      return response?.output ?? "Desculpe, não consegui processar isso.";
    } catch (e) {
      // ignore: avoid_print
      print("Erro no Gemini Service: $e");
      return "Ocorreu um erro ao conectar com a IA.";
    }
  }
}
