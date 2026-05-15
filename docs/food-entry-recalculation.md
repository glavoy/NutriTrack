# Food Definitions and Entry Recalculation

## Current Data Model

NutriTrack keeps food definitions and logged entries separate.

`foods` is the source table for available foods. Public foods are represented by `is_default = true` and `user_id = null`. User-specific foods are represented by `is_default = false` and `user_id = auth.uid()`.

`entries` stores logged meals. Each entry keeps a snapshot of the nutrient values at the time it was added:

- `food_id`
- `food_name`
- `quantity`
- `unit`
- `calories`
- `protein`
- `carbs`
- `fat`
- other micronutrients

The `food_id` links an entry back to its food definition, but entries do not automatically recalculate when a food changes.

## Why Entries Are Snapshots

Entries should usually remain historical snapshots. If a food definition changes later, old logs should not silently change because that can rewrite a user's history unexpectedly.

During development, food definitions may contain mistakes. For that case, NutriTrack has an explicit recalculation workflow that updates entries only when the user chooses to do so.

## Food Sync Behavior

When online, `SyncService.getFoods()` fetches foods from Supabase through `SupabaseService.getFoods()` and replaces the SQLite `foods_cache`.

When offline, or when Supabase fails and SQLite has cached foods, the app uses `foods_cache`.

The home screen preloads foods on startup by reading `foodsProvider.future`. The Manage Foods screen also includes a manual refresh button that invalidates `foodsProvider`, causing the next read to fetch from Supabase and refresh SQLite cache.

## Manage Foods Behavior

New foods created in Manage Foods are written to Supabase with:

- `user_id = currentUserId`
- `is_default = false`

These are user-specific custom foods.

Standard foods are read-only in the app UI. Their values should be changed directly in Supabase or through an admin workflow. After a standard food is corrected, use Refresh Foods in Manage Foods to pull the updated definition into the app.

## Temporary Recalculation Tool

Manage Foods currently includes a temporary development button on existing food records:

`Recalculate logged entries for this food`

This button:

1. Finds all entries where `entries.food_id = foods.id`.
2. Recalculates each entry's nutrients from the current food values displayed in the form and the entry quantity.
3. Updates `food_name` and `unit` from the current food definition.
4. Requires online access and updates Supabase.
5. Updates SQLite `entries_local`.
6. Invalidates current-day entries and history providers so totals refresh.

The recalculation only touches entries linked to the selected food. It does not scan all entries or all foods.

For custom foods, the form values are saved to the `foods` table before entry recalculation runs. Standard foods are read-only in the app, so their displayed values must be refreshed from Supabase before opening the recalculation screen.

The tool intentionally requires online access. The current offline sync queue handles new entries, but not bulk updates to existing entries.

The matching entries are read from Supabase, not from SQLite fallback, so the correction either operates on the authoritative server set or fails.

Matching entries are written back to Supabase with a bulk upsert keyed by `id`, rather than updating one entry at a time.

## Recalculation Formula

For each matching entry:

```text
entry nutrient = food nutrient per unit * entry quantity
```

For example:

```text
entry.calories = food.calories * entry.quantity
entry.protein = food.protein * entry.quantity
entry.carbs = food.carbs * entry.quantity
entry.fat = food.fat * entry.quantity
```

The same pattern is applied to fiber, sugar, saturated fat, sodium, potassium, calcium, iron, magnesium, and cholesterol.

## Important Limitation

If a food's unit changes, existing entry quantities are assumed to still be meaningful in the new unit. This is correct for fixing per-unit nutrient values, but it may be wrong if the old entry quantity was entered under a different measurement system.

Example risk:

- Original food used `serving`
- Corrected food uses `g`
- Existing entries with quantity `1` will be recalculated as `1 g`, not `1 serving`

For unit changes, review affected entries carefully.

## Recommended Long-Term Design

Keep entries as snapshots by default.

For stable production behavior:

- Keep public foods read-only for normal users.
- Let users duplicate public foods into custom foods if they need variations.
- Add labels in the UI for `Standard` and `My Food`.
- Consider adding `foods.updated_at` and `foods.version`.
- Consider storing `entries.food_version` for auditability.
- Replace the temporary recalculation button with an admin-only correction workflow.

The correction workflow should continue to be explicit. Avoid recalculating all entries on every app start; that will become expensive after years of usage and can silently rewrite history.
