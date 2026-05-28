-- SQL for extracting 1% from the IMDb schema.
-- run with psql -U imdb -d imdb_original -f create_small.sql
DROP SCHEMA IF EXISTS imdb_1pct;
CREATE SCHEMA imdb_1pct;

-- Root sample: about 1% of titles.
-- BERNOULLI is row-level; SYSTEM is faster but block-level.

SELECT 'Creating table seed_titles.' AS status;
CREATE TEMP TABLE seed_titles AS
SELECT tconst
FROM public.title_basics TABLESAMPLE BERNOULLI (1) REPEATABLE (42);

-- Add parent series for sampled episodes, recursively just in case.
SELECT 'Creating table keep_titles.' AS status;
CREATE TEMP TABLE keep_titles AS
WITH RECURSIVE kt(tconst) AS (
    SELECT tconst
    FROM seed_titles

    UNION

    SELECT e.parenttconst
    FROM public.title_episode e
    JOIN kt ON kt.tconst = e.tconst
    WHERE e.parenttconst IS NOT NULL
)
SELECT DISTINCT kt.tconst
FROM kt
JOIN public.title_basics b ON b.tconst = kt.tconst;

SELECT 'Creating index on keep_titles.' AS status;
CREATE UNIQUE INDEX ON keep_titles(tconst);
ANALYZE keep_titles;

SELECT 'Creating table keep_names.' AS status;
CREATE TEMP TABLE keep_names AS
WITH title_people AS (
    -- Normalized-ish person references.
    SELECT p.nconst
    FROM public.title_principals p
    JOIN keep_titles kt ON kt.tconst = p.tconst
    WHERE p.nconst IS NOT NULL

    UNION

    -- Denormalized comma-separated directors/writers in title_crew.
    SELECT s.nconst
    FROM public.title_crew c
    JOIN keep_titles kt ON kt.tconst = c.tconst
    CROSS JOIN LATERAL regexp_split_to_table(
        concat_ws(',', c.directors, c.writers),
        ','
    ) AS s(nconst)
    WHERE s.nconst <> ''
)
SELECT DISTINCT tp.nconst
FROM title_people tp
JOIN public.name_basics n ON n.nconst = tp.nconst;

SELECT 'Creating index on keep_names.' AS status;
CREATE UNIQUE INDEX ON keep_names(nconst);
ANALYZE keep_names;

SELECT 'Creating index on keep_names.' AS status;
CREATE TABLE imdb_1pct.title_basics AS
SELECT b.*
FROM public.title_basics b
JOIN keep_titles kt ON kt.tconst = b.tconst;

SELECT 'Materializing the smaller database.' AS status;
CREATE TABLE imdb_1pct.title_akas AS
SELECT a.*
FROM public.title_akas a
JOIN keep_titles kt ON kt.tconst = a.titleid;

CREATE TABLE imdb_1pct.title_ratings AS
SELECT r.*
FROM public.title_ratings r
JOIN keep_titles kt ON kt.tconst = r.tconst;

CREATE TABLE imdb_1pct.title_episode AS
SELECT e.*
FROM public.title_episode e
JOIN keep_titles child  ON child.tconst = e.tconst
JOIN keep_titles parent ON parent.tconst = e.parenttconst;

CREATE TABLE imdb_1pct.title_principals AS
SELECT p.*
FROM public.title_principals p
JOIN keep_titles kt ON kt.tconst = p.tconst
JOIN keep_names kn ON kn.nconst = p.nconst;

CREATE TABLE imdb_1pct.title_crew AS
SELECT c.*
FROM public.title_crew c
JOIN keep_titles kt ON kt.tconst = c.tconst;

SELECT 'Checking size:' AS status;
SELECT pg_size_pretty(
    sum(pg_total_relation_size((quote_ident(schemaname) || '.' || quote_ident(tablename))::regclass))
) AS total_size
FROM pg_tables
WHERE schemaname = 'imdb_1pct';

SELECT 'Checking main orphan cases:' AS status;
-- Principal rows whose person is missing.
SELECT count(*) AS missing_principal_names
FROM imdb_1pct.title_principals p
LEFT JOIN imdb_1pct.name_basics n ON n.nconst = p.nconst
WHERE n.nconst IS NULL;

-- Principal rows whose title is missing.
SELECT count(*) AS missing_principal_titles
FROM imdb_1pct.title_principals p
LEFT JOIN imdb_1pct.title_basics b ON b.tconst = p.tconst
WHERE b.tconst IS NULL;

-- Episodes whose parent title is missing.
SELECT count(*) AS missing_episode_parents
FROM imdb_1pct.title_episode e
LEFT JOIN imdb_1pct.title_basics b ON b.tconst = e.parenttconst
WHERE b.tconst IS NULL;

-- Names with no surviving principal row.
-- This ignores title_crew arrays; include those too if you care.
SELECT count(*) AS names_without_principal
FROM imdb_1pct.name_basics n
WHERE NOT EXISTS (
    SELECT 1
    FROM imdb_1pct.title_principals p
    WHERE p.nconst = n.nconst
);
