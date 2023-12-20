--------------------------------------
-- firstnf:
--------------------------------------

-- Populate firstnf.name_basics
WITH
  cte_1 AS (
  SELECT nb.nconst
       , tp.tconst
	   , tp.ordering
	   , tp.category
	   , tp.job
	   , nb.primaryname
	   , nb.birthyear
	   , nb.deathyear
  FROM public.title_principals tp
  FULL OUTER JOIN public.name_basics nb ON (tp.nconst = nb.nconst)
)
INSERT INTO firstnf.name_basics
SELECT * FROM cte_1;

-- Populate firstnf.title_basics
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
, cte_2 AS (
  SELECT cte_1.tconst
  	   , ta.ordering
	   , ta.title
       , cte_1.titletype
	   , ta.isoriginaltitle
	   , ta.region
	   , ta.language
	   , cte_1.isadult
	   , cte_1.startyear
	   , cte_1.endyear
	   , cte_1.runtimeminutes
	   , cte_1.averagerating
	   , cte_1.numvotes
  FROM public.title_akas ta
  FULL OUTER JOIN cte_1 ON (cte_1.tconst = ta.titleid)
)
INSERT INTO firstnf.title_basics
SELECT * FROM cte_2;

-- Populate firstnf.title_characters
WITH cte_1 AS (
  SELECT tp.tconst
       , tp.nconst
	   , UNNEST(STRING_TO_ARRAY(tp.characters, ',')) AS character
  FROM public.title_principals tp
)
INSERT INTO firstnf.title_characters
SELECT * FROM cte_1;

-- Populate firstnf.title_genres
WITH cte_1 AS (
  SELECT tb.tconst
       , UNNEST(STRING_TO_ARRAY(tb.genres, ',')) AS genre
  FROM public.title_basics tb
)
INSERT INTO firstnf.title_genres
SELECT * FROM cte_1;

-- Populate firstnf.title_types_attributes
WITH
  cte_1 AS (
  SELECT ta.titleid AS tconst
	   , UNNEST(STRING_TO_ARRAY(types, ',')) AS type
	   , UNNEST(STRING_TO_ARRAY(attributes, ',')) AS attribute
  FROM public.title_akas ta
)
INSERT INTO firstnf.title_types_attributes
SELECT * FROM cte_1;

-- Populate firstnf.title_directors_writers
WITH
  cte_1 AS (
  SELECT tc.tconst
       , UNNEST(STRING_TO_ARRAY(directors, ',')) AS director
	   , UNNEST(STRING_TO_ARRAY(writers, ',')) AS writer
  FROM public.title_crew tc
)
INSERT INTO firstnf.title_directors_writers
SELECT * FROM cte_1;

-- Populate firstnf.title_episodes
WITH
  cte_1 AS (
  SELECT te.tconst
       , te.parenttconst
       , te.seasonnumber
	   , te.episodenumber
  FROM public.title_episode te
)
INSERT INTO firstnf.title_episodes
SELECT * FROM cte_1;

-- Populate firstnf.name_professions_titles
WITH
  cte_1 AS (
  SELECT nb.nconst
	   , UNNEST(STRING_TO_ARRAY(primaryprofession, ',')) AS primaryprofession
	   , UNNEST(STRING_TO_ARRAY(knownfortitles, ',')) AS knownfortitle
  FROM public.name_basics nb
)
INSERT INTO firstnf.name_professions_titles
SELECT * FROM cte_1;

SELECT 'Populated the firstnf schema.' AS status;
