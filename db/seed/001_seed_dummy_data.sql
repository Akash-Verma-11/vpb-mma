-- Dummy catalog data for v1 (confirmed decision — swap for real inventory later,
-- no schema change needed). Safe to re-run: uses ON CONFLICT DO NOTHING.

INSERT INTO categories (category_id, name, type) VALUES
    ('11111111-1111-1111-1111-111111111101', 'Fiction',          'book'),
    ('11111111-1111-1111-1111-111111111102', 'Non-Fiction',      'book'),
    ('11111111-1111-1111-1111-111111111103', 'Children''s Books','book'),
    ('11111111-1111-1111-1111-111111111104', 'Notebooks',        'stationery'),
    ('11111111-1111-1111-1111-111111111105', 'Pens & Pencils',   'stationery')
ON CONFLICT (category_id) DO NOTHING;

INSERT INTO products (product_id, category_id, name, author, sku, price) VALUES
    ('22222222-2222-2222-2222-222222222201', '11111111-1111-1111-1111-111111111101', 'The Silent Patient',        'Alex Michaelides', 'BOOK-FIC-001', 399.00),
    ('22222222-2222-2222-2222-222222222202', '11111111-1111-1111-1111-111111111101', 'Atomic Habits',             'James Clear',       'BOOK-FIC-002', 499.00),
    ('22222222-2222-2222-2222-222222222203', '11111111-1111-1111-1111-111111111102', 'Sapiens',                   'Yuval Noah Harari', 'BOOK-NF-001',  599.00),
    ('22222222-2222-2222-2222-222222222204', '11111111-1111-1111-1111-111111111102', 'Deep Work',                 'Cal Newport',       'BOOK-NF-002',  449.00),
    ('22222222-2222-2222-2222-222222222205', '11111111-1111-1111-1111-111111111103', 'The Very Hungry Caterpillar','Eric Carle',       'BOOK-CH-001',  249.00),
    ('22222222-2222-2222-2222-222222222206', '11111111-1111-1111-1111-111111111104', 'A5 Ruled Notebook (200 pages)', NULL,            'STAT-NB-001',  120.00),
    ('22222222-2222-2222-2222-222222222207', '11111111-1111-1111-1111-111111111104', 'A4 Spiral Notebook',        NULL,                'STAT-NB-002',  150.00),
    ('22222222-2222-2222-2222-222222222208', '11111111-1111-1111-1111-111111111105', 'Gel Pen Set (Pack of 10)',  NULL,                'STAT-PEN-001', 180.00),
    ('22222222-2222-2222-2222-222222222209', '11111111-1111-1111-1111-111111111105', 'Wooden Pencil Box (12pc)',  NULL,                'STAT-PEN-002', 90.00),
    ('22222222-2222-2222-2222-222222222210', '11111111-1111-1111-1111-111111111105', 'Highlighter Set (5 colors)',NULL,                'STAT-PEN-003', 140.00)
ON CONFLICT (product_id) DO NOTHING;

-- Initial stock via the movements ledger (trigger populates stock_levels automatically)
INSERT INTO stock_movements (product_id, movement_type, quantity, note) VALUES
    ('22222222-2222-2222-2222-222222222201', 'purchase', 50, 'Initial seed stock'),
    ('22222222-2222-2222-2222-222222222202', 'purchase', 40, 'Initial seed stock'),
    ('22222222-2222-2222-2222-222222222203', 'purchase', 35, 'Initial seed stock'),
    ('22222222-2222-2222-2222-222222222204', 'purchase', 30, 'Initial seed stock'),
    ('22222222-2222-2222-2222-222222222205', 'purchase', 60, 'Initial seed stock'),
    ('22222222-2222-2222-2222-222222222206', 'purchase', 100,'Initial seed stock'),
    ('22222222-2222-2222-2222-222222222207', 'purchase', 100,'Initial seed stock'),
    ('22222222-2222-2222-2222-222222222208', 'purchase', 80, 'Initial seed stock'),
    ('22222222-2222-2222-2222-222222222209', 'purchase', 70, 'Initial seed stock'),
    ('22222222-2222-2222-2222-222222222210', 'purchase', 90, 'Initial seed stock');
