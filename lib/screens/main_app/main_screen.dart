import 'package:educaai/screens/main_app/home_screen.dart';
import 'package:educaai/screens/main_app/conversation_history_screen.dart';
import 'package:educaai/screens/main_app/profile_screen.dart';
import 'package:flutter/material.dart';

/// O widget "casca" (shell) principal que gere a navegação
/// por Abas (Tabs) e por Swipe (Deslizar) após o login.
/// Contém a [HomeScreen], [ConversationHistoryScreen] e [ProfileScreen].
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _pageController = PageController();

    // Sincroniza o PageView (swipe) com a TabBar (clique na aba)
    _pageController.addListener(() {
      if (_pageController.page!.round() != _tabController.index) {
        _tabController.animateTo(_pageController.page!.round());
      }
    });

    // Sincroniza a TabBar (clique na aba) com o PageView (swipe)
    _tabController.addListener(() {
      if (_tabController.index != _pageController.page!.round()) {
        _pageController.animateToPage(
          _tabController.index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.ease,
        );
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'EducaAI',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        automaticallyImplyLeading: false, // Remove a seta "voltar"
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.home), text: 'Início'),
            Tab(icon: Icon(Icons.forum), text: 'Conversas'),
            Tab(icon: Icon(Icons.person), text: 'Perfil'),
          ],
        ),
      ),
      // O PageView permite a navegação por swipe (deslizar)
      body: PageView(
        controller: _pageController,
        children: [
          // Página 1: Início (com os módulos)
          HomeScreen(pageController: _pageController),
          // Página 2: Histórico de Conversas
          const ConversationHistoryScreen(),
          // Página 3: Perfil/Configurações
          const ProfileScreen(),
        ],
      ),
    );
  }
}
