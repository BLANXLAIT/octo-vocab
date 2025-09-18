import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:octo_vocab/app.dart';
import 'package:octo_vocab/core/language/plugin_initializer.dart';

void main() {
  // Initialize language plugins before running the app
  initializeLanguagePlugins();
  
  runApp(const ProviderScope(child: OctoVocabApp()));
}
