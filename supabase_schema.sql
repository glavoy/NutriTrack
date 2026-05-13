-- NutriTrack foods permissions and RLS cleanup.
--
-- This script is tailored to the current database shape:
-- - foods already exists
-- - id is uuid with gen_random_uuid()
-- - user_id already references auth.users(id)
-- - is_default already exists
--
-- Desired model:
-- - Current foods: convert all existing rows to standard public foods.
-- - Standard foods: is_default = true, user_id = null, readable by everyone.
-- - Future custom foods: is_default = false, user_id = auth.uid(), readable and
--   manageable only by that user.
--
-- This is non-destructive: it does not delete foods or entries.

begin;

-- The current 42501 on addFood is most likely caused by the app calling
-- insert(...).select().single(): authenticated needs SELECT as well as INSERT.
grant select on public.foods to anon, authenticated;
grant insert, update, delete on public.foods to authenticated;
grant select on public.entries to authenticated;
grant insert, update, delete on public.entries to authenticated;
grant select on public.user_targets to authenticated;
grant insert, update, delete on public.user_targets to authenticated;

-- Keep unauthenticated clients read-only.
revoke insert, update, delete, truncate on public.foods from anon;
revoke insert, update, delete, truncate on public.entries from anon;
revoke insert, update, delete, truncate on public.user_targets from anon;

-- You asked to make every food currently in the table public. Future foods
-- added through the app will still be user-specific because the app inserts
-- user_id = auth.uid() and is_default = false.
update public.foods
set user_id = null,
    is_default = true;

-- Milk 5% should calculate by gram. The nutrition values below are per 1 g,
-- with default_qty set to 25 g for quick add.
update public.foods
set unit = 'g',
    default_qty = 25,
    increment_by = 5,
    calories = 0.77,
    fat = 0.05,
    saturated_fat = 0.032,
    carbs = 0.048,
    fiber = 0,
    sugar = 0.048,
    protein = 0.033,
    sodium = 0.42,
    potassium = 1.50,
    calcium = 1.20,
    iron = 0.0002,
    magnesium = 0.11,
    cholesterol = 0.18
where name = 'Milk 5%';

-- These existing gram-based rows had per-100g values in at least some fields.
-- The app stores per-1g values for unit = 'g'. Explicit values keep the script
-- safe to rerun.
update public.foods
set calories = 3.40,
    fat = 0.042,
    saturated_fat = 0.019,
    carbs = 0.665,
    fiber = 0.085,
    sugar = 0.145,
    protein = 0.085,
    sodium = 0.20,
    potassium = 4.00,
    calcium = 0.65,
    iron = 0.031,
    magnesium = 0.80,
    cholesterol = 0
where name = 'Muesli (with dried fruit)';

update public.foods
set calories = 3.78,
    fat = 0.12,
    saturated_fat = 0.014,
    carbs = 0.60,
    fiber = 0.095,
    sugar = 0.124,
    protein = 0.108,
    sodium = 0.20,
    potassium = 4.43,
    calcium = 0.65,
    iron = 0.039,
    magnesium = 1.36,
    cholesterol = 0
where name = 'Muesli (without dried fruit)';

update public.foods
set calories = 1.00
where name = 'Vanilla Yogurt';

update public.foods
set calories = 3.12,
    fat = 0.1473,
    saturated_fat = 0.021,
    carbs = 0.4144,
    fiber = 0.038,
    sugar = 0.005,
    protein = 0.0343,
    sodium = 2.10,
    potassium = 5.79,
    calcium = 0.18,
    iron = 0.0081,
    magnesium = 0.35,
    cholesterol = 0
where name = 'French Fries (Deep Fried)';

update public.foods
set calories = 1.01,
    fat = 0.001,
    saturated_fat = 0.0001,
    carbs = 0.274,
    fiber = 0.003,
    sugar = 0.22,
    protein = 0.0104,
    sodium = 9.07,
    potassium = 2.81,
    calcium = 0.15,
    iron = 0.0035,
    magnesium = 0.13,
    cholesterol = 0
where name = 'Ketchup';

alter table public.foods enable row level security;

-- Remove the overlapping existing policies so the behavior is unambiguous.
drop policy if exists "Manage Own Foods" on public.foods;
drop policy if exists "Public Read Default Foods" on public.foods;
drop policy if exists "Read Own Foods" on public.foods;
drop policy if exists "Users can delete their own foods" on public.foods;
drop policy if exists "Users can insert their own foods" on public.foods;
drop policy if exists "Users can update their own foods" on public.foods;
drop policy if exists "Users can view default foods and their own foods" on public.foods;
drop policy if exists "Read standard and own custom foods" on public.foods;
drop policy if exists "Read shared and own foods" on public.foods;
drop policy if exists "Create own custom foods" on public.foods;
drop policy if exists "Update own custom foods" on public.foods;
drop policy if exists "Delete own custom foods" on public.foods;

create policy "Read standard and own custom foods"
on public.foods
for select
using (
  is_default = true
  or user_id = auth.uid()
);

create policy "Create own custom foods"
on public.foods
for insert
to authenticated
with check (
  user_id = auth.uid()
  and is_default = false
);

create policy "Update own custom foods"
on public.foods
for update
to authenticated
using (
  user_id = auth.uid()
  and is_default = false
)
with check (
  user_id = auth.uid()
  and is_default = false
);

create policy "Delete own custom foods"
on public.foods
for delete
to authenticated
using (
  user_id = auth.uid()
  and is_default = false
);

commit;
