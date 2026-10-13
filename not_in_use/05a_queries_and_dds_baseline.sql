--------------------------------
-- Set pgbench variables for tconst and nconst (not in use)
--------------------------------

-- Generate a random number for min. and max. tconst:
--\set number_tconst :randint(1, 9916880)

-- Generate a random number for min. and max. nconst:
--\set number_nconst :randint(1, 9993719)

--------------------------------
--------------------------------
-- Q1
-- Based on a movies's rating, list the primary names and ratings of the best 250 movies. IMDb's TOP-250 list is based on additional data not present in the dataset.
--------------------------------
--------------------------------

--------------------------------
-- public (baseline)
--------------------------------

SELECT tb.primarytitle
     , tr.averagerating
FROM public.title_basics tb
INNER JOIN public.title_ratings tr
  ON (tb.tconst = tr.tconst)
WHERE tb.titletype = 'movie'
AND   tr.numvotes > 25000
ORDER BY tr.averagerating DESC
LIMIT 250;

--------------------------------
--------------------------------
-- Q2
-- Based on a person's identifier, find the names of the titles the person is known for.
--------------------------------
--------------------------------

--------------------------------
-- public (baseline)
--------------------------------

WITH kft AS (
  SELECT UNNEST(STRING_TO_ARRAY(nb.knownfortitles, ',')) AS title
  FROM public.name_basics nb
  WHERE nb.nconst = (SELECT 'nm' || LPAD((FLOOR(RANDOM()*(9993719 - 1 + 1)) + 1)::text, 7, '0') AS nconst_random)
)
SELECT tb.primarytitle
FROM public.title_basics tb
INNER JOIN kft
  ON (kft.title = tb.tconst);

--------------------------------
--------------------------------
-- Q3
-- Based on a title's identifier, find the names of each episode for each season.
--------------------------------
--------------------------------

--------------------------------
-- public (baseline)
--------------------------------

SELECT te.seasonnumber
     , te.episodenumber
     , tb.primarytitle
FROM public.title_basics tb
INNER JOIN public.title_episode te
  ON (tb.tconst = te.parenttconst)
WHERE tb.titletype = 'tvSeries'
AND   tb.tconst = (SELECT 'tt' || LPAD((FLOOR(RANDOM()*(9916880 - 1 + 1)) + 1)::text, 7, '0') AS tconst_random)
ORDER BY te.seasonnumber  ASC
       , te.episodenumber ASC;

--------------------------------
--------------------------------
-- Q4
-- Based on a person's identifier, find the person's name, birthyear, deathyear, primary professions, and names of the titles the person is known for. Primary professions are not related to the titles the person is known for in the result table (such data is not available in the database).
--------------------------------
--------------------------------

--------------------------------
-- public (baseline)
--------------------------------

SELECT nb.primaryname
     , nb.birthyear
     , nb.deathyear
     , UNNEST(STRING_TO_ARRAY(nb.primaryprofession, ',')) AS primaryprofession
     , UNNEST(STRING_TO_ARRAY(nb.knownfortitles, ','))    AS knownfortitle
FROM public.name_basics nb
WHERE nb.nconst = (SELECT 'nm' || LPAD((FLOOR(RANDOM()*(9993719 - 1 + 1)) + 1)::text, 7, '0') AS nconst_random);


--------------------------------
--------------------------------
-- Q5
-- Based on a title's identifier, find all titles, title types and title attributes.
--------------------------------
--------------------------------

--------------------------------
-- public (baseline)
--------------------------------

SELECT ta.title
     , UNNEST(STRING_TO_ARRAY(ta.types, ','))      AS type
     , UNNEST(STRING_TO_ARRAY(ta.attributes, ',')) AS attribute
FROM public.title_akas ta
WHERE ta.titleid = (SELECT 'tt' || LPAD((FLOOR(RANDOM()*(9916880 - 1 + 1)) + 1)::text, 7, '0') AS tconst_random);

--------------------------------
--------------------------------
-- Q6
-- Based on a title's identifier, find the names, birthyears, categories and jobs of all people who worked on the title, and the title's startyear. Sort the results according to birthyear, descending.
--------------------------------
--------------------------------

--------------------------------
-- public (baseline)
--------------------------------

SELECT nb.primaryname
     , nb.birthyear
     , tp.category
     , tp.job
     , tb.startyear
FROM public.title_principals tp
INNER JOIN public.name_basics nb
  ON (tp.nconst = nb.nconst)
INNER JOIN public.title_basics tb
  ON (tp.tconst = tb.tconst)
WHERE tp.tconst = (SELECT 'tt' || LPAD((FLOOR(RANDOM()*(9916880 - 1 + 1)) + 1)::text, 7, '0') AS tconst_random)
ORDER BY nb.birthyear DESC;

--------------------------------
--------------------------------
-- Q7
-- Based on a title's identifier, find the title's primary title, release year, runtime, genres, rating, and names of directors and actors as well as the names of the actors' characters.
--------------------------------
--------------------------------

--------------------------------
-- public (baseline)
--------------------------------

SELECT DISTINCT
       tb.primarytitle
     , tb.startyear
     , tb.runtimeminutes
     , tb.genres
     , tr.averagerating
     , nb_d.primaryname AS "director name"
     , nb_w.primaryname AS "writer name"
     , nb_a.primaryname AS "actor name"
     , tp_a.characters  AS "character names"
FROM  public.title_basics tb
LEFT OUTER JOIN public.title_ratings tr
  ON (tb.tconst = tr.tconst)
LEFT OUTER JOIN public.title_principals tp_a
  ON (tb.tconst = tp_a.tconst)
LEFT OUTER JOIN public.name_basics nb_a
  ON (tp_a.nconst = nb_a.nconst AND tp_a.category IN ('actor', 'actress'))
LEFT OUTER JOIN public.title_principals tp_d
  ON (tb.tconst = tp_d.tconst)
LEFT OUTER JOIN public.name_basics nb_d
  ON (tp_d.nconst = nb_d.nconst AND tp_d.category = 'director')
LEFT OUTER JOIN public.title_principals tp_w
  ON (tb.tconst = tp_w.tconst)
LEFT OUTER JOIN public.name_basics nb_w
  ON (tp_w.nconst = nb_w.nconst AND tp_w.category = 'writer')
WHERE tb.tconst = (SELECT 'tt' || LPAD((FLOOR(RANDOM()*(9916880 - 1 + 1)) + 1)::text, 7, '0') AS tconst_random);

