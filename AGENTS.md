# Repository Guidelines

## Project Structure & Module Organization

NutriTrack is a Flutter app with a Supabase backend. Core Dart code lives in `lib/`:

- `lib/models/` contains data models such as foods, entries, and user targets.
- `lib/services/` contains Supabase, SQLite, and sync logic.
- `lib/providers/` contains Riverpod providers and action notifiers.
- `lib/screens/` and `lib/widgets/` contain UI.

Platform folders (`android/`, `ios/`, `macos/`, `linux/`, `windows/`, `web/`) are Flutter targets. Shared images and branding assets live in `assets/`. Database setup and RLS changes live in `supabase_schema.sql`. Add Flutter tests under `test/`.

## Build, Test, and Development Commands

- `flutter pub get`: install Dart and Flutter dependencies.
- `flutter run`: run the app on the selected device or simulator.
- `flutter run -d macos`: run on macOS desktop.
- `flutter test`: run unit and widget tests.
- `flutter analyze`: run static analysis from `analysis_options.yaml`.
- `dart format lib test`: format Dart source and tests.
- `flutter build macos` / `flutter build web`: create platform builds.

Run `supabase_schema.sql` manually in the Supabase SQL Editor when database policy or schema changes are required.

## Coding Style & Naming Conventions

Use standard Dart formatting: two-space indentation, trailing commas where useful, and `dart format` before committing. Use `PascalCase` for classes and widgets, `camelCase` for variables and methods, and `snake_case.dart` for file names. Keep services focused on data access/sync, providers on state orchestration, and screens/widgets on UI.

## Testing Guidelines

Use Flutter’s built-in `flutter_test` framework. Name test files with the `_test.dart` suffix, for example `test/models/food_test.dart` or `test/widgets/meal_card_test.dart`. Add focused tests for model serialization, nutrient calculations, provider behavior, and sync-sensitive client logic. Always run `flutter test` and `flutter analyze` before a pull request.

## Commit & Pull Request Guidelines

The current history uses short, direct commit messages such as `Updated .gitignore`. Keep commits concise and imperative, for example `Fix food insert permissions` or `Add food form validation`.

Pull requests should include a brief description, testing performed, and screenshots for UI changes. For Supabase changes, include the SQL script, explain whether it is destructive, and note manual dashboard steps.

## Security & Configuration Tips

Use the anon Supabase key only in client code. Never commit service-role keys, database passwords, or personal access tokens. RLS policies should protect user-specific rows with `auth.uid()` and keep shared food rows readable without granting broad write access.
