-- ============================================================
-- Seed default system categories (household_id = NULL)
-- These are available to all households as starting points.
-- Users can create custom categories on top of these.
-- ============================================================

INSERT INTO categories (id, household_id, name, parent_id, icon, color, is_income, sort_order) VALUES
-- ── Income ──────────────────────────────────────────────────
(gen_random_uuid(), NULL, 'Income',               NULL,  'trending-up',     '#22c55e', true,  0),
(gen_random_uuid(), NULL, 'Salary',               (SELECT id FROM categories WHERE name='Income' AND household_id IS NULL), 'briefcase', '#22c55e', true, 1),
(gen_random_uuid(), NULL, 'Freelance',            (SELECT id FROM categories WHERE name='Income' AND household_id IS NULL), 'laptop',    '#22c55e', true, 2),
(gen_random_uuid(), NULL, 'Investment Income',    (SELECT id FROM categories WHERE name='Income' AND household_id IS NULL), 'trending-up','#22c55e', true, 3),
(gen_random_uuid(), NULL, 'Other Income',         (SELECT id FROM categories WHERE name='Income' AND household_id IS NULL), 'plus',      '#22c55e', true, 4),

-- ── Housing ─────────────────────────────────────────────────
(gen_random_uuid(), NULL, 'Housing',              NULL,  'home',            '#3b82f6', false, 10),
(gen_random_uuid(), NULL, 'Rent / Mortgage',      (SELECT id FROM categories WHERE name='Housing' AND household_id IS NULL), 'home',    '#3b82f6', false, 1),
(gen_random_uuid(), NULL, 'Utilities',            (SELECT id FROM categories WHERE name='Housing' AND household_id IS NULL), 'zap',     '#3b82f6', false, 2),
(gen_random_uuid(), NULL, 'Internet / Phone',     (SELECT id FROM categories WHERE name='Housing' AND household_id IS NULL), 'wifi',    '#3b82f6', false, 3),
(gen_random_uuid(), NULL, 'Home Maintenance',     (SELECT id FROM categories WHERE name='Housing' AND household_id IS NULL), 'wrench',  '#3b82f6', false, 4),
(gen_random_uuid(), NULL, 'Home Insurance',       (SELECT id FROM categories WHERE name='Housing' AND household_id IS NULL), 'shield',  '#3b82f6', false, 5),

-- ── Food ────────────────────────────────────────────────────
(gen_random_uuid(), NULL, 'Food & Dining',        NULL,  'utensils',        '#f97316', false, 20),
(gen_random_uuid(), NULL, 'Groceries',            (SELECT id FROM categories WHERE name='Food & Dining' AND household_id IS NULL), 'shopping-cart', '#f97316', false, 1),
(gen_random_uuid(), NULL, 'Restaurants',          (SELECT id FROM categories WHERE name='Food & Dining' AND household_id IS NULL), 'utensils',      '#f97316', false, 2),
(gen_random_uuid(), NULL, 'Coffee & Drinks',      (SELECT id FROM categories WHERE name='Food & Dining' AND household_id IS NULL), 'coffee',        '#f97316', false, 3),
(gen_random_uuid(), NULL, 'Takeout & Delivery',   (SELECT id FROM categories WHERE name='Food & Dining' AND household_id IS NULL), 'package',       '#f97316', false, 4),

-- ── Transportation ───────────────────────────────────────────
(gen_random_uuid(), NULL, 'Transportation',       NULL,  'car',             '#8b5cf6', false, 30),
(gen_random_uuid(), NULL, 'Gas',                  (SELECT id FROM categories WHERE name='Transportation' AND household_id IS NULL), 'fuel',    '#8b5cf6', false, 1),
(gen_random_uuid(), NULL, 'Car Payment',          (SELECT id FROM categories WHERE name='Transportation' AND household_id IS NULL), 'car',     '#8b5cf6', false, 2),
(gen_random_uuid(), NULL, 'Car Insurance',        (SELECT id FROM categories WHERE name='Transportation' AND household_id IS NULL), 'shield',  '#8b5cf6', false, 3),
(gen_random_uuid(), NULL, 'Car Maintenance',      (SELECT id FROM categories WHERE name='Transportation' AND household_id IS NULL), 'wrench',  '#8b5cf6', false, 4),
(gen_random_uuid(), NULL, 'Public Transit',       (SELECT id FROM categories WHERE name='Transportation' AND household_id IS NULL), 'bus',     '#8b5cf6', false, 5),
(gen_random_uuid(), NULL, 'Rideshare / Parking',  (SELECT id FROM categories WHERE name='Transportation' AND household_id IS NULL), 'map-pin', '#8b5cf6', false, 6),

-- ── Health ───────────────────────────────────────────────────
(gen_random_uuid(), NULL, 'Health',               NULL,  'heart',           '#ec4899', false, 40),
(gen_random_uuid(), NULL, 'Health Insurance',     (SELECT id FROM categories WHERE name='Health' AND household_id IS NULL), 'shield', '#ec4899', false, 1),
(gen_random_uuid(), NULL, 'Doctor / Dentist',     (SELECT id FROM categories WHERE name='Health' AND household_id IS NULL), 'stethoscope', '#ec4899', false, 2),
(gen_random_uuid(), NULL, 'Prescriptions',        (SELECT id FROM categories WHERE name='Health' AND household_id IS NULL), 'pill', '#ec4899', false, 3),
(gen_random_uuid(), NULL, 'Gym & Fitness',        (SELECT id FROM categories WHERE name='Health' AND household_id IS NULL), 'dumbbell', '#ec4899', false, 4),
(gen_random_uuid(), NULL, 'Vision & Dental',      (SELECT id FROM categories WHERE name='Health' AND household_id IS NULL), 'eye', '#ec4899', false, 5),

-- ── Personal ─────────────────────────────────────────────────
(gen_random_uuid(), NULL, 'Personal',             NULL,  'user',            '#06b6d4', false, 50),
(gen_random_uuid(), NULL, 'Clothing',             (SELECT id FROM categories WHERE name='Personal' AND household_id IS NULL), 'shirt', '#06b6d4', false, 1),
(gen_random_uuid(), NULL, 'Personal Care',        (SELECT id FROM categories WHERE name='Personal' AND household_id IS NULL), 'scissors', '#06b6d4', false, 2),
(gen_random_uuid(), NULL, 'Subscriptions',        (SELECT id FROM categories WHERE name='Personal' AND household_id IS NULL), 'repeat', '#06b6d4', false, 3),
(gen_random_uuid(), NULL, 'Entertainment',        (SELECT id FROM categories WHERE name='Personal' AND household_id IS NULL), 'film', '#06b6d4', false, 4),
(gen_random_uuid(), NULL, 'Books & Education',    (SELECT id FROM categories WHERE name='Personal' AND household_id IS NULL), 'book', '#06b6d4', false, 5),
(gen_random_uuid(), NULL, 'Hobbies',              (SELECT id FROM categories WHERE name='Personal' AND household_id IS NULL), 'star', '#06b6d4', false, 6),

-- ── Kids ─────────────────────────────────────────────────────
(gen_random_uuid(), NULL, 'Kids',                 NULL,  'baby',            '#f59e0b', false, 60),
(gen_random_uuid(), NULL, 'Childcare',            (SELECT id FROM categories WHERE name='Kids' AND household_id IS NULL), 'baby',   '#f59e0b', false, 1),
(gen_random_uuid(), NULL, 'School & Supplies',    (SELECT id FROM categories WHERE name='Kids' AND household_id IS NULL), 'backpack','#f59e0b', false, 2),
(gen_random_uuid(), NULL, 'Activities & Sports',  (SELECT id FROM categories WHERE name='Kids' AND household_id IS NULL), 'trophy', '#f59e0b', false, 3),
(gen_random_uuid(), NULL, 'Allowance',            (SELECT id FROM categories WHERE name='Kids' AND household_id IS NULL), 'coins',  '#f59e0b', false, 4),

-- ── Savings & Investments ────────────────────────────────────
(gen_random_uuid(), NULL, 'Savings & Investments',NULL,  'piggy-bank',      '#10b981', false, 70),
(gen_random_uuid(), NULL, 'Emergency Fund',       (SELECT id FROM categories WHERE name='Savings & Investments' AND household_id IS NULL), 'shield', '#10b981', false, 1),
(gen_random_uuid(), NULL, '401k / Retirement',    (SELECT id FROM categories WHERE name='Savings & Investments' AND household_id IS NULL), 'clock',  '#10b981', false, 2),
(gen_random_uuid(), NULL, 'Brokerage',            (SELECT id FROM categories WHERE name='Savings & Investments' AND household_id IS NULL), 'trending-up','#10b981', false, 3),
(gen_random_uuid(), NULL, 'HSA Contribution',     (SELECT id FROM categories WHERE name='Savings & Investments' AND household_id IS NULL), 'heart',  '#10b981', false, 4),
(gen_random_uuid(), NULL, '529 / College Savings',(SELECT id FROM categories WHERE name='Savings & Investments' AND household_id IS NULL), 'graduation-cap','#10b981', false, 5),

-- ── Debt ─────────────────────────────────────────────────────
(gen_random_uuid(), NULL, 'Debt',                 NULL,  'credit-card',     '#ef4444', false, 80),
(gen_random_uuid(), NULL, 'Credit Card Payment',  (SELECT id FROM categories WHERE name='Debt' AND household_id IS NULL), 'credit-card', '#ef4444', false, 1),
(gen_random_uuid(), NULL, 'Student Loan',         (SELECT id FROM categories WHERE name='Debt' AND household_id IS NULL), 'book',        '#ef4444', false, 2),
(gen_random_uuid(), NULL, 'Personal Loan',        (SELECT id FROM categories WHERE name='Debt' AND household_id IS NULL), 'dollar-sign', '#ef4444', false, 3),

-- ── Gifts & Donations ────────────────────────────────────────
(gen_random_uuid(), NULL, 'Gifts & Donations',    NULL,  'gift',            '#a855f7', false, 90),
(gen_random_uuid(), NULL, 'Gifts',                (SELECT id FROM categories WHERE name='Gifts & Donations' AND household_id IS NULL), 'gift',  '#a855f7', false, 1),
(gen_random_uuid(), NULL, 'Charitable Donations', (SELECT id FROM categories WHERE name='Gifts & Donations' AND household_id IS NULL), 'heart', '#a855f7', false, 2),

-- ── Other ────────────────────────────────────────────────────
(gen_random_uuid(), NULL, 'Taxes',                NULL,  'file-text',       '#6b7280', false, 100),
(gen_random_uuid(), NULL, 'Business',             NULL,  'briefcase',       '#6b7280', false, 110),
(gen_random_uuid(), NULL, 'Transfer',             NULL,  'arrow-right-left','#6b7280', false, 120),
(gen_random_uuid(), NULL, 'Uncategorized',        NULL,  'circle',          '#6b7280', false, 999);
