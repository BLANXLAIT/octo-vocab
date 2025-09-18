// ignore_for_file: public_member_api_docs
import 'package:octo_vocab/core/navigation/adaptive_scaffold.dart';
import 'package:go_router/go_router.dart';

final GoRouter appRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => const AdaptiveScaffold(),
    ),
  ],
);
