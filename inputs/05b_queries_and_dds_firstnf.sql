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
-- firstnf:
--------------------------------

SELECT tb.title
     , tb.averagerating
FROM  firstnf.title_basics tb
WHERE tb.titletype = 'movie'
AND   tb.isoriginaltitle IS True
AND   tb.numvotes > 25000
ORDER BY tb.averagerating DESC
LIMIT 250;

--------------------------------
--------------------------------
-- Q2
-- Based on a person's identifier, find the names of the titles the person is known for.
--------------------------------
--------------------------------

--------------------------------
-- firstnf:
--------------------------------

SELECT tb.title
FROM firstnf.title_basics tb
INNER JOIN firstnf.name_professions_titles npt
  ON (tb.tconst = npt.knownfortitle)
WHERE tb.isoriginaltitle IS True
AND npt.nconst = (SELECT 'nm' || LPAD((FLOOR(RANDOM()*(9993719 - 1 + 1)) + 1)::text, 7, '0') AS nconst_random);

--------------------------------
--------------------------------
-- Q3
-- Based on a title's identifier, find the names of each episode for each season.
--------------------------------
--------------------------------

--------------------------------
-- firstnf:
--------------------------------

SELECT te.seasonnumber
     , te.episodenumber
     , tb.title
FROM firstnf.title_basics tb
INNER JOIN firstnf.title_episodes te
  ON (tb.tconst = te.tconst_parent)
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
-- firstnf:
--------------------------------

SELECT DISTINCT
       nb.primaryname
     , nb.birthyear
     , nb.deathyear
     , npt.primaryprofession
     , npt.knownfortitle
FROM firstnf.name_basics nb
LEFT OUTER JOIN firstnf.name_professions_titles npt
  ON (nb.nconst = npt.nconst)
WHERE nb.nconst = (SELECT 'nm' || LPAD((FLOOR(RANDOM()*(9993719 - 1 + 1)) + 1)::text, 7, '0') AS nconst_random);

--------------------------------
--------------------------------
-- Q5
-- Based on a title's identifier, find all titles, title types and title attributes.
--------------------------------
--------------------------------

--------------------------------
-- firstnf:
--------------------------------

SELECT DISTINCT
       tb.title
     , tya.type
     , tya.attribute
FROM firstnf.title_basics tb
INNER JOIN firstnf.title_types_attributes tya
  ON (tb.tconst = tya.tconst)
WHERE tb.tconst = (SELECT 'tt' || LPAD((FLOOR(RANDOM()*(9916880 - 1 + 1)) + 1)::text, 7, '0') AS tconst_random);

--------------------------------
--------------------------------
-- Q6
-- Based on a title's identifier, find the names, birthyears, categories and jobs of all people who worked on the title, and the title's startyear. Sort the results according to birthyear, descending.
--------------------------------
--------------------------------

--------------------------------
-- firstnf:
--------------------------------

SELECT nb.primaryname
     , nb.birthyear
     , nb.category
     , nb.job
     , tb.startyear
FROM firstnf.title_basics tb
INNER JOIN firstnf.name_basics nb
  ON (tb.tconst = nb.tconst)
WHERE tb.tconst = (SELECT 'tt' || LPAD((FLOOR(RANDOM()*(9916880 - 1 + 1)) + 1)::text, 7, '0') AS tconst_random)
ORDER BY nb.birthyear DESC;

--------------------------------
--------------------------------
-- Q7
-- Based on a title's identifier, find the title's primary title, release year, runtime, genres, rating, and names of directors and actors as well as the names of the actors' characters.
--------------------------------
--------------------------------

--------------------------------
-- firstnf:
--------------------------------

SELECT DISTINCT 
       tb.title
     , tb.startyear
     , tb.runtimeminutes
     , tg.genre
     , tb.averagerating
     , nb_d.primaryname AS "director name"
     , nb_w.primaryname AS "writer name"
     , nb_a.primaryname AS "actor name"
     , tc.character    AS "character name"
FROM   firstnf.title_basics tb
LEFT OUTER JOIN firstnf.title_genres tg
  ON (tb.tconst = tg.tconst)
LEFT OUTER JOIN firstnf.title_characters tc
  ON (tb.tconst = tc.tconst)
LEFT OUTER JOIN firstnf.name_basics nb_a
  ON (tc.nconst = nb_a.nconst)
LEFT OUTER JOIN firstnf.title_directors_writers tdw
  ON (tb.tconst = tdw.tconst)
LEFT OUTER JOIN firstnf.name_basics nb_d
  ON (tdw.director = nb_d.nconst)
LEFT OUTER JOIN firstnf.name_basics nb_w
  ON (tdw.writer = nb_w.nconst)
WHERE tb.isoriginaltitle IS True
AND   tb.tconst = (SELECT 'tt' || LPAD((FLOOR(RANDOM()*(9916880 - 1 + 1)) + 1)::text, 7, '0') AS tconst_random);
