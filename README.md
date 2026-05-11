# Nutrition Tracker

A cross-platform nutrition tracking app built with Flutter and Supabase.

## Features

- 📱 Works on Android, iOS, Windows, macOS, Linux, and Web
- ☁️ Real-time sync across devices via Supabase
- 📴 Offline support with local SQLite caching
- 🍎 Quick-add library with 35+ whole foods
- 📊 Daily progress tracking with visual progress bars
- 📈 30-day history with calorie charts
- 🎯 Customizable daily nutrient targets
- 🔐 Secure authentication

## Setup Instructions

### 1. Create Supabase Project

1. Go to [supabase.com](https://supabase.com) and create a free account
2. Click "New Project"
3. Choose a name (e.g., "nutrition-tracker")
4. Set a database password (save this!)
5. Select a region close to you
6. Click "Create new project"

### 2. Run Database Schema

1. In your Supabase dashboard, go to **SQL Editor**
2. Click "New query"
3. Copy the entire contents of `supabase_schema.sql` and paste it
4. Click "Run" (or Ctrl/Cmd + Enter)
5. You should see "Success" - the schema creates:
   - `foods` table (with 35+ default foods)
   - `entries` table (your daily logs)
   - `user_targets` table (your goals)
   - Row Level Security policies
   - Auto-creation of user targets on signup

### 3. Get Supabase Credentials

1. Go to **Project Settings** (gear icon)
2. Click **API** in the sidebar
3. Copy these values:
   - **Project URL** (looks like `https://xxxxx.supabase.co`)
   - **anon/public key** (starts with `eyJ...`)

### 4. Configure Flutter App

1. Open `lib/main.dart`
2. Replace the placeholder values:

```dart
const supabaseUrl = 'https://YOUR-PROJECT-ID.supabase.co';
const supabaseAnonKey = 'eyJ...YOUR-ANON-KEY...';
```

### 5. Run the App

```bash
# Get dependencies
flutter pub get

# Run on your device/emulator
flutter run

# Or build for specific platform
flutter build apk          # Android
flutter build ios          # iOS
flutter build windows      # Windows
flutter build macos        # macOS
flutter build web          # Web
```

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/
│   ├── food.dart            # Food model
│   ├── entry.dart           # Daily log entry model
│   └── user_targets.dart    # Daily targets model
├── services/
│   ├── supabase_service.dart  # Supabase API calls
│   ├── local_database.dart    # SQLite for offline
│   └── sync_service.dart      # Offline-first sync logic
├── providers/
│   └── providers.dart       # Riverpod state management
├── screens/
│   ├── auth_screen.dart     # Login/signup
│   ├── home_screen.dart     # Main daily view
│   ├── history_screen.dart  # History & charts
│   └── settings_screen.dart # Settings & targets
└── widgets/
    ├── daily_progress_card.dart
    ├── meal_card.dart
    └── quick_add_sheet.dart
```

## Adding Custom Foods

Foods can be added two ways:

1. **In the app**: Use the "Custom" tab when adding food
2. **Via Supabase**: Add directly to the `foods` table:

```sql
INSERT INTO foods (user_id, name, unit, default_qty, calories, protein, carbs, fat, ...)
VALUES ('your-user-uuid', 'My Food', 'serving', 1, 100, 10, 20, 5, ...);
```

## Default Daily Targets

Configured for a 56-year-old male at 70kg:

| Nutrient | Target |
|----------|--------|
| Calories | 2,100 kcal |
| Protein | 63g |
| Carbs | 275g |
| Fat | 70g |
| Fiber | 34g |
| Sugar (max) | 36g |
| Sodium (max) | 2,300mg |

Targets can be customized in Settings > Edit All Targets.

## Offline Support

The app works offline:
- Foods library is cached locally
- Entries are saved to SQLite when offline
- Automatic sync when connection is restored
- Visual indicator when data is pending sync

## Security

- Row Level Security (RLS) ensures users only see their own data
- Passwords are hashed by Supabase Auth
- API key is "anon" level - safe for client apps
- All database queries are filtered by authenticated user ID

## Troubleshooting

**"Invalid API key"**
- Double-check your `supabaseAnonKey` in `main.dart`

**"Permission denied" errors**
- Make sure you ran the full SQL schema (includes RLS policies)

**Foods not showing**
- Check that the default foods INSERT ran successfully
- Look in Supabase Table Editor > foods

**Sync not working**
- Check your internet connection
- Pull down to refresh on home screen

## License

MIT
