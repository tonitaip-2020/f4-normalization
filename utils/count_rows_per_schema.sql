SELECT
  n.nspname AS schema,
  SUM(
    (
      xpath(
        '/table/row/row_count/text()',
        query_to_xml(
          format(
            'SELECT count(*) AS row_count FROM %I.%I',
            n.nspname,
            c.relname
          ),
          false,
          false,
          ''
        )
      )
    )[1]::text::bigint
  ) AS row_count
FROM pg_class AS c
JOIN pg_namespace AS n
  ON n.oid = c.relnamespace
WHERE n.nspname IN ('public', 'firstnf', 'secondnf', 'fourthnf')
  AND c.relkind = 'r'
GROUP BY n.nspname
ORDER BY row_count DESC;
