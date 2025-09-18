import 'package:octo_vocab/core/language/language_registry.dart';
import 'package:octo_vocab/core/language/plugins/latin_plugin.dart';
import 'package:octo_vocab/core/language/plugins/spanish_plugin.dart';

// ignore_for_file: public_member_api_docs

/// Initialize all language plugins
void initializeLanguagePlugins() {
  final registry = LanguageRegistry.instance;
  
  // Register language plugins
  registry.register(LatinPlugin());
  registry.register(SpanishPlugin());
  
  print('DEBUG: Language plugins initialized successfully');
}