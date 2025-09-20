CREATE TABLE products (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  price NUMERIC(10,2) NOT NULL
);
INSERT INTO products (name, description, price) VALUES
  ('Widget A', 'Basic widget', 9.99),
  ('Widget C', 'Sub widget', 9.99),
  ('Widget D', 'Another', 9.99),
  ('Widget B', 'Advanced widget', 19.99);
