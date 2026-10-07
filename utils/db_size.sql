-- Total schema footprint, GiB with one decimal place.
SELECT
  n.nspname AS schema,
  ROUND(SUM(pg_total_relation_size(c.oid)) / 1024.0^3, 1) AS total_size_gib
FROM pg_class AS c
JOIN pg_namespace AS n
  ON n.oid = c.relnamespace
WHERE n.nspname IN ('public', 'firstnf', 'secondnf', 'fourthnf')
  AND c.relkind IN ('r', 'm')
GROUP BY n.nspname
ORDER BY total_size_gib DESC;

-- Table data only, GiB with one decimal place; excludes indexes.
SELECT
  n.nspname AS schema,
  ROUND(SUM(pg_table_size(c.oid)) / 1024.0^3, 1) AS table_data_gib
FROM pg_class AS c
JOIN pg_namespace AS n
  ON n.oid = c.relnamespace
WHERE n.nspname IN ('public', 'firstnf', 'secondnf', 'fourthnf')
  AND c.relkind IN ('r', 'm')
GROUP BY n.nspname
ORDER BY table_data_gib DESC;
