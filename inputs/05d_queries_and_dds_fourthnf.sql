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
-- fourthnf:
--------------------------------

SELECT ta.title
     , tb.averagerating
FROM fourthnf.title_akas ta
INNER JOIN fourthnf.title_basics tb
  ON (ta.tconst = tb.tconst)
WHERE tb.titletype = 'movie'
AND   ta.isoriginaltitle IS True
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
-- fourthnf:
--------------------------------

SELECT ta.title
FROM fourthnf.title_akas ta
INNER JOIN fourthnf.name_titles nt
  ON (ta.tconst = nt.knownfortitle)
WHERE ta.isoriginaltitle IS True
AND nt.nconst = (SELECT 'nm' || LPAD((FLOOR(RANDOM()*(9993719 - 1 + 1)) + 1)::text, 7, '0') AS nconst_random);

--------------------------------
--------------------------------
-- Q3
-- Based on a title's identifier, find the names of each episode for each season.
--------------------------------
--------------------------------

--------------------------------
-- fourthnf:
--------------------------------

SELECT te.seasonnumber
     , te.episodenumber
	 , ta.title
FROM fourthnf.title_akas ta
INNER JOIN fourthnf.title_basics tb
  ON (ta.tconst = tb.tconst)
INNER JOIN fourthnf.title_episodes te
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
-- fourthnf:
--------------------------------

SELECT DISTINCT
       nb.primaryname
     , nb.birthyear
	 , nb.deathyear
	 , np.primaryprofession
	 , nt.knownfortitle
FROM fourthnf.name_basics nb
LEFT OUTER JOIN fourthnf.name_professions np
  ON (nb.nconst = np.nconst)
LEFT OUTER JOIN fourthnf.name_titles nt
  ON (nb.nconst = nt.nconst)
WHERE nb.nconst = (SELECT 'nm' || LPAD((FLOOR(RANDOM()*(9993719 - 1 + 1)) + 1)::text, 7, '0') AS nconst_random);

--------------------------------
--------------------------------
-- Q5
-- Based on a title's identifier, find all titles, title types and title attributes.
--------------------------------
--------------------------------

--------------------------------
-- fourthnf:
--------------------------------

SELECT DISTINCT
       ta.title
     , ty.type
	 , tat.attribute
FROM fourthnf.title_akas ta
INNER JOIN fourthnf.title_types ty
  ON (ta.tconst = ty.tconst)
INNER JOIN fourthnf.title_attributes tat
  ON (ta.tconst = tat.tconst)
WHERE ta.tconst = (SELECT 'tt' || LPAD((FLOOR(RANDOM()*(9916880 - 1 + 1)) + 1)::text, 7, '0') AS tconst_random);

--------------------------------
--------------------------------
-- Q6
-- Based on a title's identifier, find the names, birthyears, categories and jobs of all people who worked on the title, and the title's startyear. Sort the results according to birthyear, descending.
--------------------------------
--------------------------------

--------------------------------
-- fourthnf:
--------------------------------

SELECT nb.primaryname
     , nb.birthyear
	 , tp.category
	 , tp.job
	 , tb.startyear
FROM fourthnf.title_basics tb
INNER JOIN fourthnf.title_principals tp
  ON (tb.tconst = tp.tconst)
INNER JOIN fourthnf.name_basics nb
  ON (tp.nconst = nb.nconst)
WHERE tb.tconst = (SELECT 'tt' || LPAD((FLOOR(RANDOM()*(9916880 - 1 + 1)) + 1)::text, 7, '0') AS tconst_random)
ORDER BY nb.birthyear DESC;

--------------------------------
--------------------------------
-- Q7
-- Based on a title's identifier, find the title's primary title, release year, runtime, genres, rating, and names of directors and actors as well as the names of the actors' characters.
--------------------------------
--------------------------------

--------------------------------
-- fourthnf:
--------------------------------

SELECT DISTINCT
       ta.title
     , tb.startyear
	 , tb.runtimeminutes
     , tg.genre
	 , tb.averagerating
	 , nb_d.primaryname AS "director name"
	 , nb_w.primaryname AS "writer name"
	 , nb_a.primaryname AS "actor name"
	 , tc.character     AS "character name"
FROM fourthnf.title_basics tb
LEFT OUTER JOIN fourthnf.title_genres tg
  ON (tb.tconst = tg.tconst)
LEFT OUTER JOIN fourthnf.title_akas ta
  ON (tb.tconst = ta.tconst AND ta.isoriginaltitle IS True)
LEFT OUTER JOIN fourthnf.title_characters tc
  ON (tb.tconst = tc.tconst)
LEFT OUTER JOIN fourthnf.name_basics nb_a
  ON (tc.nconst = nb_a.nconst)
LEFT OUTER JOIN fourthnf.title_directors td
  ON (tb.tconst = td.tconst)
LEFT OUTER JOIN fourthnf.name_basics nb_d
  ON (td.director = nb_d.nconst)
LEFT OUTER JOIN fourthnf.title_writers tw
  ON (tb.tconst = tw.tconst)
LEFT OUTER JOIN fourthnf.name_basics nb_w
  ON (tw.writer = nb_w.nconst)
WHERE tb.tconst = (SELECT 'tt' || LPAD((FLOOR(RANDOM()*(9916880 - 1 + 1)) + 1)::text, 7, '0') AS tconst_random);