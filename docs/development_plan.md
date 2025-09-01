# Development Plan: Octo Vocab (8th Grade Latin)

## 1) Goals & Scope
- Build a cross-platform (iOS/Android/Web/Desktop) Latin vocabulary app for 8th graders.
- Core: Flashcards, Quizzes, Spaced Repetition, Progress Tracking, simple Gamification.
- MVP focuses on local content from assets; cloud sync via Firebase added later.

## 2) Tech Stack (from pubspec.yaml)
- Flutter (Material 3)
- State: Riverpod (flutter_riverpod, riverpod_annotation, riverpod_generator)
- Routing: go_router (+ builder)
- Models/Codegen: freezed, json_serializable
- Firebase (later phases): firebase_core, firebase_auth, cloud_firestore, firebase_crashlytics

## 3) Architecture & Directory Layout
lib/
- app.dart (ProviderScope + MaterialApp.router + theme)
- routing/
  - router.dart (GoRouter routes)
- core/
  - models/ (freezed + json)
    - word.dart (id, latin, english, pos, example, notes, tags)
    - word_set.dart (id, name, description, wordIds or embedded words)
    - user_progress.dart (wordId, status, ease, interval, dueDate, correct/wrong streaks)
  - srs/
    - scheduler.dart (spaced repetition scheduling, due computation)
  - services/
    - clock.dart (abstraction for time in tests)
    - diacritics.dart (normalize/compare answers)
- data/
  - sources/
    - vocab_asset_loader.dart (load JSON assets)
  - repositories/
    - vocab_repository.dart (interface)
    - local_vocab_repository.dart (assets-backed)
    - progress_repository.dart (interface)
    - local_progress_repository.dart (shared_preferences or local file)
    - firestore_* (later)
- features/
  - flashcards/ (screen, widgets, providers)
  - quiz/ (screen, widgets, providers)
  - review/ (due queue screen)
  - progress/ (dashboard, charts)
  - settings/ (theme, sound toggles)
- widgets/
  - common UI components (ProgressBar, PrimaryButton, EmptyState, etc.)

assets/
- vocab/ (JSON files, e.g., grade8_set1.json, grade8_set2.json)
- Add to pubspec.yaml under flutter: assets:

## 4) Data Model (high-level)
- Word: { id, latin, english, partOfSpeech?, exampleLatin?, exampleEnglish?, notes?, tags?: [“grade8”, “set1”] }
- WordSet: { id, name, description?, words: [Word] } or references by id
- UserProgress: { wordId, status: New|Learning|Review|Known, ease: double, intervalDays: int, dueDate: DateTime, correctStreak: int, wrongStreak: int, lastReviewed: DateTime }

## 5) Spaced Repetition Strategy
- Start simple: staged intervals (1d → 3d → 7d → 14d → 30d) with promotions/demotions based on correctness.
- Later upgrade to SM-2-like ease factor and quality response (0–5).
- Build a daily review queue: all words with dueDate <= today plus new-word quota.

## 6) Milestones & Tasks

M0 — App Skeleton (Routing + State)
- [ ] Create app.dart and router.dart with GoRouter
- [ ] Define route stubs: / (Home), /flashcards, /quiz, /review, /progress, /settings
- [ ] ProviderScope wrapper; basic theme
- [ ] Build & run on web and one mobile target

M1 — Content & Flashcards (Assets)
- [ ] Add assets/vocab/ and update pubspec assets
- [ ] Define models: word.dart, word_set.dart (freezed/json)
- [ ] Implement VocabAssetLoader and LocalVocabRepository
- [ ] Build Flashcards screen: flip, known/unknown
- [ ] Session provider (select set, current index, mark result)
- [ ] Basic Progress: total, known, learning counts

M2 — Quiz Mode
- [ ] MC questions: random distractors from same set
- [ ] Fill-in-the-blank with diacritics-insensitive compare
- [ ] Immediate feedback UI + explanations (example sentence)
- [ ] Per-mode analytics (correct%, avg time optional)

M3 — Spaced Repetition & Review
- [ ] Implement UserProgress model + LocalProgressRepository
- [ ] SRS scheduler: compute next interval/dueDate
- [ ] Daily queue generator (due + new quota)
- [ ] Review screen to work through queue across modes
- [ ] Persist progress locally

M4 — Progress & Gamification
- [ ] Streaks, badges, mastery per set
- [ ] Progress dashboard screen
- [ ] Gentle nudges/reminders (local-only; push later)

M5 — Firebase Integration (Optional Phase)
- [ ] Anonymous or email auth with firebase_auth
- [ ] Firestore repositories for vocab (optional) and progress sync
- [ ] Crashlytics initialization
- [ ] Offline support and conflict strategy

M6 — Testing, Accessibility, Polish
- [ ] Unit tests: scheduler, repositories, utils
- [ ] Widget tests: Flashcards, Quiz, Review
- [ ] Theming, large fonts, high-contrast mode
- [ ] QA across iOS/Android/Web

## 7) Testing Plan
- Unit: core/srs/scheduler.dart (interval logic), data repositories
- Widget: Flashcards flip/known-unknown flow, Quiz feedback, Review queue
- Golden tests for key widgets where useful

## 8) MVP Acceptance Criteria
- Load 1–2 Grade 8 Latin sets from assets
- Flashcards and Quiz modes functional
- Local persistence of progress
- Review queue with simple SRS
- Progress screen with counts and streak

## 9) Risks & Mitigation
- Firebase setup time: defer to M5; MVP uses local persistence
- Diacritics/orthography: normalize inputs; keep answer keys consistent
- Content quality: validate JSON, add basic lint for assets
- Cross-platform differences: test web and one mobile early (M0)

## 10) Immediate Next Actions (implementation)
- [ ] Create lib/app.dart and lib/routing/router.dart
- [ ] Stub feature screens and add to routes
- [ ] Add assets/vocab/ with seed JSON and update pubspec
- [ ] Define models with freezed/json; run build_runner
- [ ] Implement LocalVocabRepository; render Flashcards MVP
- [ ] Add LocalProgressRepository and simple SRS

References: docs/requirements.md, docs/learning_methods.md, docs/framework_choice.md, docs/ux_design.md, docs/features.md, docs/app_structure.md, docs/implementation_plan.md
