// ignore_for_file: public_member_api_docs
import 'package:flutter/material.dart';
import 'package:flutter_saas_template/core/language/language.dart';
import 'package:flutter_saas_template/features/flashcards/flashcards_screen.dart'
    as f;
import 'package:flutter_saas_template/features/progress/progress_screen.dart'
    as p;
import 'package:flutter_saas_template/features/quiz/quiz_screen.dart' as q;
import 'package:flutter_saas_template/features/review/review_screen.dart' as r;
import 'package:go_router/go_router.dart';

final GoRouter appRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/flashcards',
      name: 'flashcards',
      builder: (context, state) => const f.FlashcardsScreen(),
    ),
    GoRoute(
      path: '/quiz',
      name: 'quiz',
      builder: (context, state) => const q.QuizScreen(),
    ),
    GoRoute(
      path: '/review',
      name: 'review',
      builder: (context, state) => const r.ReviewScreen(),
    ),
    GoRoute(
      path: '/progress',
      name: 'progress',
      builder: (context, state) => const p.ProgressScreen(),
    ),
    GoRoute(
      path: '/settings',
      name: 'settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _go(BuildContext context, String path) => context.go(path);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Octo Vocab'),
        actions: const [LanguageSwitcherAction(), SizedBox(width: 8)],
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.style),
            title: const Text('Flashcards'),
            onTap: () => _go(context, '/flashcards'),
          ),
          ListTile(
            leading: const Icon(Icons.quiz),
            title: const Text('Quiz'),
            onTap: () => _go(context, '/quiz'),
          ),
          ListTile(
            leading: const Icon(Icons.refresh),
            title: const Text('Review'),
            onTap: () => _go(context, '/review'),
          ),
          ListTile(
            leading: const Icon(Icons.insights),
            title: const Text('Progress'),
            onTap: () => _go(context, '/progress'),
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () => _go(context, '/settings'),
          ),
        ],
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _SimpleScaffold(title: 'Settings');
  }
}

class _SimpleScaffold extends StatelessWidget {
  const _SimpleScaffold({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text('$title Screen')),
    );
  }
}
