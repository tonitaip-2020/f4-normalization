--------------------------------------
-- secondnf:
--------------------------------------

-- Populate secondnf.name_basics
WITH
  cte_1 AS (
  SELECT nb.nconst
       , nb.primaryname
	   , nb.birthyear
	   , nb.deathyear
  FROM public.name_basics nb
)
INSERT INTO secondnf.name_basics
SELECT * FROM cte_1;

-- Populate secondnf.title_principals
WITH
  cte_1 AS (
  SELECT tp.nconst
       , tp.tconst
	   , tp.ordering
	   , tp.category
	   , tp.job
  FROM public.title_principals tp
  LEFT OUTER JOIN public.title_basics tb ON (tp.tconst = tb.tconst)
)
INSERT INTO secondnf.title_principals
SELECT * FROM cte_1;

-- Populate secondnf.title_basics
WITH
  cte_1 AS (
  SELECT tb.tconst
       , tb.titletype
	   , tb.isadult
	   , tb.startyear
	   , tb.endyear
	   , tb.runtimeminutes
	   , tr.averagerating
	   , tr.numvotes
  FROM public.title_basics tb
  FULL OUTER JOIN public.title_ratings tr ON (tb.tconst = tr.tconst)
)
INSERT INTO secondnf.title_basics
SELECT * FROM cte_1;

-- Populate secondnf.title_akas
WITH
  cte_1 AS (
  SELECT ta.titleid
       , ta.ordering
	   , ta.title
	   , ta.isoriginaltitle
	   , ta.region
	   , ta.language
  FROM public.title_akas ta
)
INSERT INTO secondnf.title_akas
SELECT * FROM cte_1;

-- Populate secondnf.title_characters
WITH cte_1 AS (
  SELECT tp.tconst
       , tp.nconst
	   , UNNEST(STRING_TO_ARRAY(tp.characters, ',')) AS character
  FROM public.title_principals tp
)
INSERT INTO secondnf.title_characters
SELECT * FROM cte_1;

-- Populate secondnf.title_genres
WITH cte_1 AS (
  SELECT tb.tconst
       , UNNEST(STRING_TO_ARRAY(tb.genres, ',')) AS genre
  FROM public.title_basics tb
)
INSERT INTO secondnf.title_genres
SELECT * FROM cte_1;

-- Populate secondnf.title_types_attributes
WITH
  cte_1 AS (
  SELECT ta.titleid AS tconst
	   , UNNEST(STRING_TO_ARRAY(types, ',')) AS type
	   , UNNEST(STRING_TO_ARRAY(attributes, ',')) AS attribute
  FROM public.title_akas ta
)
INSERT INTO secondnf.title_types_attributes
SELECT * FROM cte_1;

-- Populate secondnf.title_directors_writers
WITH
  cte_1 AS (
  SELECT tc.tconst
       , UNNEST(STRING_TO_ARRAY(directors, ',')) AS director
	   , UNNEST(STRING_TO_ARRAY(writers, ',')) AS writer
  FROM public.title_crew tc
)
INSERT INTO secondnf.title_directors_writers
SELECT * FROM cte_1;

-- Populate secondnf.title_episodes
WITH
  cte_1 AS (
  SELECT te.tconst
       , te.parenttconst
       , te.seasonnumber
	   , te.episodenumber
  FROM public.title_episode te
)
INSERT INTO secondnf.title_episodes
SELECT * FROM cte_1;

-- Populate secondnf.name_professions_titles
WITH
  cte_1 AS (
  SELECT nb.nconst
	   , UNNEST(STRING_TO_ARRAY(primaryprofession, ',')) AS primaryprofession
	   , UNNEST(STRING_TO_ARRAY(knownfortitles, ',')) AS knownfortitle
  FROM public.name_basics nb
)
INSERT INTO secondnf.name_professions_titles
SELECT * FROM cte_1;

SELECT 'Populated the secondnf schema.' AS status;
