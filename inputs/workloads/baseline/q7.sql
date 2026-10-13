--------------------------------
--------------------------------
-- Q7
-- Based on a title's identifier, find the title's primary title, release year, runtime, genres, rating, and names of directors and actors as well as the names of the actors' characters.
--------------------------------
--------------------------------

--------------------------------
-- public (baseline)
--------------------------------

\set title_number random(1, 12844280)

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
FROM public.title_basics AS tb
LEFT OUTER JOIN public.title_ratings AS tr
  ON tr.tconst = tb.tconst
LEFT OUTER JOIN public.title_principals AS tp_a
  ON tp_a.tconst = tb.tconst
 AND tp_a.category IN ('actor', 'actress')
LEFT OUTER JOIN public.name_basics AS nb_a
  ON nb_a.nconst = tp_a.nconst
LEFT OUTER JOIN public.title_principals AS tp_d
  ON tp_d.tconst = tb.tconst
 AND tp_d.category = 'director'
LEFT OUTER JOIN public.name_basics AS nb_d
  ON nb_d.nconst = tp_d.nconst
LEFT OUTER JOIN public.title_principals AS tp_w
  ON tp_w.tconst = tb.tconst
 AND tp_w.category = 'writer'
LEFT OUTER JOIN public.name_basics AS nb_w
  ON nb_w.nconst = tp_w.nconst
WHERE tb.tconst = (
  'tt' || LPAD(CAST(:title_number AS text), 7, '0')
)::character varying;

