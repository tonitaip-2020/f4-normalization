--------------------------------
--------------------------------
-- Q7
-- Based on a title's identifier, find the title's primary title, release year, runtime, genres, rating, and names of directors and actors as well as the names of the actors' characters.
--------------------------------
--------------------------------

--------------------------------
-- firstnf:
--------------------------------

\set title_number random(1, 12844280)

SELECT DISTINCT
       tb.title
     , tb.startyear
     , tb.runtimeminutes
     , tg.genre
     , tb.averagerating
     , nb_d.primaryname AS "director name"
     , nb_w.primaryname AS "writer name"
     , nb_a.primaryname AS "actor name"
     , tc.character     AS "character name"
FROM firstnf.title_basics AS tb
LEFT OUTER JOIN firstnf.title_genres AS tg
  ON tg.tconst = tb.tconst
LEFT OUTER JOIN firstnf.title_characters AS tc
  ON tc.tconst = tb.tconst
LEFT OUTER JOIN firstnf.name_basics AS nb_a
  ON nb_a.nconst = tc.nconst
 AND nb_a.tconst = tc.tconst
LEFT OUTER JOIN firstnf.title_directors_writers AS tdw
  ON tdw.tconst = tb.tconst
LEFT OUTER JOIN firstnf.name_basics AS nb_d
  ON nb_d.nconst = tdw.director
 AND nb_d.tconst = tdw.tconst
LEFT OUTER JOIN firstnf.name_basics AS nb_w
  ON nb_w.nconst = tdw.writer
 AND nb_w.tconst = tdw.tconst
WHERE tb.isoriginaltitle IS TRUE
  AND tb.tconst = (
    'tt' || LPAD(CAST(:title_number AS text), 7, '0')
  )::character varying;
