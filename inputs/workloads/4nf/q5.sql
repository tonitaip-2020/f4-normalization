--------------------------------
--------------------------------
-- Q5
-- Based on a title's identifier, find all titles, title types and title attributes.
--------------------------------
--------------------------------

--------------------------------
-- fourthnf:
--------------------------------

\set title_number random(1, 12844280)

SELECT DISTINCT
       ta.title
     , ty.type
     , tat.attribute
FROM fourthnf.title_akas ta
INNER JOIN fourthnf.title_types ty
  ON (ta.tconst = ty.tconst)
INNER JOIN fourthnf.title_attributes tat
  ON (ta.tconst = tat.tconst)
WHERE ta.tconst = ('tt' || LPAD(CAST(:title_number AS text), 7, '0'))::character varying;
