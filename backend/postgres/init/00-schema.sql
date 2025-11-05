CREATE TABLE products (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  price NUMERIC(10,2) NOT NULL,
  created_at DATE NOT NULL DEFAULT CURRENT_DATE,
  updated_at DATE NOT NULL DEFAULT CURRENT_DATE
);
INSERT INTO products (name, description, price) VALUES
  ('Widget A', 'Basic widget', 9.99),
  ('Widget B', 'Sub widget', 6.14),
  ('Widget C', 'Another', 9.99),
  ('Widget D', 'Advanced widget', 19.99),
  ('Widget e', 'Another', 3.83),
  ('Widget f', 'Another', 9.99),
  ('Widget g', 'Another', 1.00);
