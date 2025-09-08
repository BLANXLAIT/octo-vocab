import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_saas_template/app.dart';
import 'package:flutter_saas_template/core/language/plugin_initializer.dart';

void main() {
  // Initialize language plugins before running the app
  initializeLanguagePlugins();
  
  runApp(const ProviderScope(child: OctoVocabApp()));
}
