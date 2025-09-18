// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:octo_vocab/core/theme/dynamic_theme.dart';
import 'package:octo_vocab/routing/router.dart';

class OctoVocabApp extends ConsumerWidget {
  const OctoVocabApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(dynamicThemeProvider);

    return MaterialApp.router(
      title: 'Octo Vocab',
      theme: theme,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
