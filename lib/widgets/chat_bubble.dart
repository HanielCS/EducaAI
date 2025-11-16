import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:markdown/markdown.dart' as md;

/// Widget de bolha de chat com suporte a Markdown e LaTeX ($...$ e $$...$$)
class ChatBubble extends StatelessWidget {
  final String text;
  final bool isUser;

  const ChatBubble({super.key, required this.text, required this.isUser});

  @override
  Widget build(BuildContext context) {
    // Deteta o tema para cores adaptáveis
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color aiBubbleColor = isDarkMode
        ? Colors.grey.shade800
        : Colors.grey.shade200;
    final Color aiTextColor = isDarkMode ? Colors.white : Colors.black87;

    // Define o estilo de texto adaptável
    final textStyle = TextStyle(
      color: isUser ? Colors.white : aiTextColor,
      fontSize: 16,
    );

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(14.0),
              decoration: BoxDecoration(
                color: isUser
                    ? Theme.of(context).colorScheme.primary
                    : aiBubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 0),
                  bottomRight: Radius.circular(isUser ? 0 : 20),
                ),
              ),
              child: MarkdownBody(
                data: text,
                selectable: true,
                extensionSet: md.ExtensionSet(
                  [
                    ...md.ExtensionSet.gitHubWeb.blockSyntaxes,
                    BlockLatexSyntax(), // blocos $$...$$
                  ],
                  [
                    ...md.ExtensionSet.gitHubWeb.inlineSyntaxes,
                    InlineLatexSyntax(), // inline $...$
                  ],
                ),
                builders: {'latex': LatexElementBuilder()},
                styleSheet: MarkdownStyleSheet(
                  p: textStyle,
                  code: textStyle, // Estilo do LaTeX
                  pPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ----------------------------------------------------------------------
/// SUPORTE A LATEX INLINE  -> $ ... $
/// ----------------------------------------------------------------------
class InlineLatexSyntax extends md.InlineSyntax {
  InlineLatexSyntax() : super(r'\$(.+?)\$');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final latexText = match.group(1)!;
    parser.addNode(md.Element.text('latex', latexText));
    return true;
  }
}

/// ----------------------------------------------------------------------
/// SUPORTE A LATEX EM BLOCO -> $$ ... $$
/// ----------------------------------------------------------------------
class BlockLatexSyntax extends md.BlockSyntax {
  final _pattern = RegExp(r'^\$\$(.+?)\$\$$', dotAll: true);

  @override
  RegExp get pattern => _pattern;

  @override
  md.Node? parse(md.BlockParser parser) {
    final match = pattern.firstMatch(parser.current.content);
    if (match == null) return null;

    final latexText = match.group(1)!.trim();
    parser.advance();
    return md.Element.text('latex', latexText);
  }
}

/// ----------------------------------------------------------------------
/// RENDERIZAÇÃO DO LATEX DETECTADO
/// ----------------------------------------------------------------------
class LatexElementBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final latex = element.textContent.trim();

    final isBlock = latex.contains('\n') || latex.length > 30;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: isBlock ? 8 : 2),
      child: Math.tex(
        latex,
        mathStyle: isBlock ? MathStyle.display : MathStyle.text,
        textStyle: preferredStyle, // Usa o estilo adaptável
      ),
    );
  }
}
