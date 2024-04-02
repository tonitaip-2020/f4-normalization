----------------------------------------------------------------------------
-- DB SIZE:
----------------------------------------------------------------------------

-- table size plus indices "etc":
SELECT pg_size_pretty (pg_total_relation_size ('public.title_basics'));

-- database size:
SELECT pg_size_pretty (pg_database_size ('imdb_base'));

-- sizes by schema:
SELECT schema_name
     , pg_size_pretty(SUM(table_size)::bigint)          AS "size pretty"
     , SUM(table_size)::bigint                          AS "size non-pretty"
	 , pg_size_pretty(SUM(table_size_with_ind)::bigint) AS "size pretty with ind"
	 , SUM(table_size_with_ind)::bigint                 AS "size non-pretty with ind"
FROM (
  SELECT pg_catalog.pg_namespace.nspname                 AS schema_name
      ,  pg_relation_size(pg_catalog.pg_class.oid)       AS table_size
	  ,  pg_total_relation_size(pg_catalog.pg_class.oid) AS table_size_with_ind
    FROM pg_catalog.pg_class
    JOIN pg_catalog.pg_namespace ON (relnamespace = pg_catalog.pg_namespace.oid)
) t
WHERE schema_name IN ('public', 'nfnf', 'firstnf', 'secondnf', 'fourthnf')
GROUP BY schema_name
ORDER BY schema_name;

-- get row counts #1:
WITH tbl AS
  (SELECT table_schema,
          TABLE_NAME
   FROM information_schema.tables
   WHERE TABLE_NAME not like 'pg_%'
     AND table_schema in ('fourthnf'))
SELECT table_schema,
       TABLE_NAME,
       (xpath('/row/c/text()', query_to_xml(format('select count(*) as c from %I.%I', table_schema, TABLE_NAME), FALSE, TRUE, '')))[1]::text::int AS rows_n
FROM tbl
ORDER BY rows_n DESC;
-- source: https://stackoverflow.com/questions/2596670/how-do-you-find-the-row-count-for-all-your-tables-in-postgres

-- get row counts #2:
select table_schema, 
       table_name, 
       (xpath('/row/cnt/text()', xml_count))[1]::text::int as row_count
from (
  select table_name, table_schema, 
         query_to_xml(format('select count(*) as cnt from %I.%I', table_schema, table_name), false, true, '') as xml_count
  from information_schema.tables
  where table_schema = 'secondnf' --<< change here for the schema you want
) t;
-- source: https://stackoverflow.com/questions/2596670/how-do-you-find-the-row-count-for-all-your-tables-in-postgres

----------------------------------------------------------------------------
-- MISC:
----------------------------------------------------------------------------

-- set statement timeout to 1666 minutes for db creation:
SET statement_timeout = 99999999; 