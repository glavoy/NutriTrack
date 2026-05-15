-- NutriTrack obvious nutrition corrections for public/default foods.
--
-- App storage model checked in lib/models/food.dart:
-- Food.scaledNutrients(quantity) multiplies each stored nutrient by the logged
-- quantity directly. Therefore rows with unit = 'g' must store nutrients per
-- 1 gram, while rows with unit = 'cup', 'slice', 'piece', etc. store nutrients
-- per 1 displayed unit.
--
-- These updates focus on values that were obviously wrong or likely
-- underfilled in the current table, mostly sodium/potassium decimal mistakes
-- and missing calcium/iron/magnesium values.

begin;

-- Very obvious sodium / potassium unit-decimal problems.
update public.foods
set sodium = 0.0100,
    updated_at = now()
where name = 'Banana'
  and unit = 'g'
  and user_id is null;

update public.foods
set sodium = 0.0100,
    updated_at = now()
where name = 'Apple'
  and unit = 'g'
  and user_id is null;

update public.foods
set sodium = 0.0600,
    updated_at = now()
where name = 'Potato (baked)'
  and unit = 'g'
  and user_id is null;

update public.foods
set sodium = 0.3600,
    updated_at = now()
where name = 'Sweet Potato (baked)'
  and unit = 'g'
  and user_id is null;

update public.foods
set sodium = 0.0700,
    magnesium = 0.2900,
    updated_at = now()
where name = 'Avocado'
  and unit = 'g'
  and user_id is null;

update public.foods
set sodium = 0.0000,
    potassium = 2.1270,
    calcium = 0.0640,
    iron = 0.0035,
    magnesium = 0.1200,
    updated_at = now()
where name = 'Red Bell Pepper'
  and unit = 'g'
  and user_id is null;

update public.foods
set sodium = 0.0000,
    potassium = 1.9730,
    calcium = 0.0670,
    iron = 0.0036,
    magnesium = 0.1000,
    updated_at = now()
where name = 'Yellow Bell Pepper'
  and unit = 'g'
  and user_id is null;

update public.foods
set sodium = 0.6900,
    potassium = 3.2000,
    calcium = 0.3300,
    iron = 0.0030,
    magnesium = 0.1200,
    updated_at = now()
where name = 'Carrot'
  and unit = 'g'
  and user_id is null;

-- Missing or heavily underfilled mineral values.
update public.foods
set calcium = 0.3600,
    iron = 0.0086,
    magnesium = 0.1300,
    sodium = 0.2800,
    updated_at = now()
where name = 'Leafy Lettuce'
  and unit = 'g'
  and user_id is null;

update public.foods
set iron = 0.0027,
    calcium = 0.1000,
    updated_at = now()
where name = 'Tomato'
  and unit = 'g'
  and user_id is null;

update public.foods
set iron = 0.0028,
    updated_at = now()
where name = 'Cucumber'
  and unit = 'g'
  and user_id is null;

update public.foods
set calcium = 1.0300,
    iron = 0.0250,
    magnesium = 0.7800,
    potassium = 2.3000,
    sodium = 3.8100,
    updated_at = now()
where name = 'Multi-grain Bread'
  and unit = 'g'
  and user_id is null;

update public.foods
set magnesium = 0.1070,
    updated_at = now()
where name = 'Greek Yogurt (plain)'
  and unit = 'g'
  and user_id is null;

update public.foods
set magnesium = 0.1100,
    updated_at = now()
where name = 'Milk 5%'
  and unit = 'g'
  and user_id is null;

update public.foods
set magnesium = 0.1100,
    updated_at = now()
where name = 'Vanilla Yogurt'
  and unit = 'g'
  and user_id is null;

update public.foods
set magnesium = 0.8000,
    updated_at = now()
where name = 'Muesli (with dried fruit)'
  and unit = 'g'
  and user_id is null;

update public.foods
set magnesium = 1.3600,
    updated_at = now()
where name = 'Muesli (without dried fruit)'
  and unit = 'g'
  and user_id is null;

update public.foods
set calcium = 0.2000,
    iron = 0.0270,
    magnesium = 0.2100,
    updated_at = now()
where name = 'Ground Beef (lean, cooked)'
  and unit = 'g'
  and user_id is null;

update public.foods
set calcium = 0.1500,
    iron = 0.0100,
    magnesium = 0.2900,
    updated_at = now()
where name = 'Chicken Breast (baked)'
  and unit = 'g'
  and user_id is null;

update public.foods
set calcium = 0.0600,
    iron = 0.0240,
    magnesium = 0.2400,
    updated_at = now()
where name = 'Beef Fillet (baked)'
  and unit = 'g'
  and user_id is null;

update public.foods
set calcium = 0.1400,
    iron = 0.0069,
    magnesium = 0.3400,
    updated_at = now()
where name = 'Tilapia (baked)'
  and unit = 'g'
  and user_id is null;

update public.foods
set calcium = 0.1800,
    iron = 0.0081,
    magnesium = 0.3500,
    updated_at = now()
where name = 'French Fries (Deep Fried)'
  and unit = 'g'
  and user_id is null;

update public.foods
set calcium = 0.1500,
    iron = 0.0035,
    magnesium = 0.1300,
    updated_at = now()
where name = 'Ketchup'
  and unit = 'g'
  and user_id is null;

update public.foods
set calcium = 0.0200,
    iron = 0.0000,
    magnesium = 0.0300,
    updated_at = now()
where name = 'Coffee (Black)'
  and unit = 'g'
  and user_id is null;

update public.foods
set calcium = 0.1200,
    iron = 0.0110,
    magnesium = 0.2200,
    updated_at = now()
where name = 'Chicken Drumstick (baked)'
  and unit = 'g'
  and user_id is null;

update public.foods
set calcium = 0.1200,
    iron = 0.0110,
    magnesium = 0.2200,
    updated_at = now()
where name = 'Chicken Drumstick (fried)'
  and unit = 'g'
  and user_id is null;

update public.foods
set calcium = 0.9000,
    iron = 0.0230,
    magnesium = 1.6800,
    updated_at = now()
where name = 'Peanuts (roasted)'
  and unit = 'g'
  and user_id is null;

update public.foods
set calcium = 0.1600,
    iron = 0.0027,
    magnesium = 0.2100,
    updated_at = now()
where name = 'Roasted Cassava'
  and unit = 'g'
  and user_id is null;

update public.foods
set calcium = 0.1900,
    iron = 0.0090,
    magnesium = 0.2500,
    updated_at = now()
where name = 'Pork (Roasted)'
  and unit = 'g'
  and user_id is null;

update public.foods
set calcium = 0.2000,
    iron = 0.0040,
    magnesium = 0.1200,
    updated_at = now()
where name = 'Roasted Vegetables (Mixed)'
  and unit = 'g'
  and user_id is null;

update public.foods
set calcium = 1.5000,
    iron = 0.0150,
    magnesium = 0.3500,
    updated_at = now()
where name = 'Greens (Kale/Sukuma)'
  and unit = 'g'
  and user_id is null;

update public.foods
set calcium = 0.2000,
    iron = 0.0030,
    magnesium = 0.1000,
    updated_at = now()
where name = 'Mushroom Sauce'
  and unit = 'g'
  and user_id is null;

update public.foods
set calcium = 0.2000,
    iron = 0.0030,
    magnesium = 0.1800,
    updated_at = now()
where name = 'Mashed Potatoes'
  and unit = 'g'
  and user_id is null;

-- Quick review query after running the updates.
select name,
       unit,
       sodium,
       potassium,
       calcium,
       iron,
       magnesium,
       updated_at
from public.foods
where user_id is null
  and name in (
    'Banana',
    'Apple',
    'Potato (baked)',
    'Sweet Potato (baked)',
    'Avocado',
    'Red Bell Pepper',
    'Yellow Bell Pepper',
    'Carrot',
    'Leafy Lettuce',
    'Tomato',
    'Cucumber',
    'Multi-grain Bread',
    'Greek Yogurt (plain)',
    'Milk 5%',
    'Vanilla Yogurt',
    'Muesli (with dried fruit)',
    'Muesli (without dried fruit)',
    'Ground Beef (lean, cooked)',
    'Chicken Breast (baked)',
    'Beef Fillet (baked)',
    'Tilapia (baked)',
    'French Fries (Deep Fried)',
    'Ketchup',
    'Coffee (Black)',
    'Chicken Drumstick (baked)',
    'Chicken Drumstick (fried)',
    'Peanuts (roasted)',
    'Roasted Cassava',
    'Pork (Roasted)',
    'Roasted Vegetables (Mixed)',
    'Greens (Kale/Sukuma)',
    'Mushroom Sauce',
    'Mashed Potatoes'
  )
order by name;

commit;
