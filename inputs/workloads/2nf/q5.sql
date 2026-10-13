--------------------------------
--------------------------------
-- Q5
-- Based on a title's identifier, find all titles, title types and title attributes.
--------------------------------
--------------------------------

--------------------------------
-- secondnf:
--------------------------------

\set title_number random(1, 12844280)

SELECT DISTINCT
       ta.title
     , tya.type
     , tya.attribute
FROM secondnf.title_akas ta
INNER JOIN secondnf.title_types_attributes tya
  ON (ta.tconst = tya.tconst)
WHERE ta.tconst = ('tt' || LPAD(CAST(:title_number AS text), 7, '0'))::character varying;
