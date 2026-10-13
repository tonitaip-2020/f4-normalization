--------------------------------
--------------------------------
-- Q7
-- Based on a title's identifier, find the title's primary title, release year, runtime, genres, rating, and names of directors and actors as well as the names of the actors' characters.
--------------------------------
--------------------------------

--------------------------------
-- fourthnf:
--------------------------------

\set title_number random(1, 12844280)

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
FROM fourthnf.title_basics AS tb
LEFT OUTER JOIN fourthnf.title_genres AS tg
  ON tg.tconst = tb.tconst
LEFT OUTER JOIN fourthnf.title_akas AS ta
  ON ta.tconst = tb.tconst
 AND ta.isoriginaltitle IS TRUE
LEFT OUTER JOIN fourthnf.title_characters AS tc
  ON tc.tconst = tb.tconst
LEFT OUTER JOIN fourthnf.name_basics AS nb_a
  ON nb_a.nconst = tc.nconst
LEFT OUTER JOIN fourthnf.title_directors AS td
  ON td.tconst = tb.tconst
LEFT OUTER JOIN fourthnf.name_basics AS nb_d
  ON nb_d.nconst = td.director
LEFT OUTER JOIN fourthnf.title_writers AS tw
  ON tw.tconst = tb.tconst
LEFT OUTER JOIN fourthnf.name_basics AS nb_w
  ON nb_w.nconst = tw.writer
WHERE tb.tconst = (
  'tt' || LPAD(CAST(:title_number AS text), 7, '0')
)::character varying;
