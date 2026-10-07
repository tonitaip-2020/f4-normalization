-- Total schema footprint: table data, indexes, TOAST data, free-space maps, etc.
SELECT
  n.nspname AS schema,
  SUM(pg_total_relation_size(c.oid)) AS bytes,
  pg_size_pretty(SUM(pg_total_relation_size(c.oid))) AS total_size
FROM pg_class AS c
JOIN pg_namespace AS n
  ON n.oid = c.relnamespace
WHERE n.nspname IN ('public', 'firstnf', 'secondnf', 'fourthnf')
  AND c.relkind IN ('r', 'm')
GROUP BY n.nspname
ORDER BY bytes DESC;

-- Table data only: heap, TOAST data, free-space maps, and visibility maps;
-- excludes all indexes.
SELECT
  n.nspname AS schema,
  SUM(pg_table_size(c.oid)) AS bytes,
  pg_size_pretty(SUM(pg_table_size(c.oid))) AS table_data_size
FROM pg_class AS c
JOIN pg_namespace AS n
  ON n.oid = c.relnamespace
WHERE n.nspname IN ('public', 'firstnf', 'secondnf', 'fourthnf')
  AND c.relkind IN ('r', 'm')
GROUP BY n.nspname
ORDER BY bytes DESC;
