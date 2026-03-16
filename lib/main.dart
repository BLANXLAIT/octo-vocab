import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:octo_vocab/app.dart';
import 'package:octo_vocab/core/language/plugin_initializer.dart';
import 'package:octo_vocab/core/providers/storage_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();

  // Initialize language plugins before running the app
  initializeLanguagePlugins();

  runApp(
    ProviderScope(
      overrides: [
        // Override the SharedPreferences provider with actual instance
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const OctoVocabApp(),
    ),
  );
}
