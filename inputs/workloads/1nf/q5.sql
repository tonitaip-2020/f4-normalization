--------------------------------
--------------------------------
-- Q5
-- Based on a title's identifier, find all titles, title types and title attributes.
--------------------------------
--------------------------------

--------------------------------
-- firstnf:
--------------------------------

\set title_number random(1, 12844280)

SELECT DISTINCT
       tb.title
     , tya.type
     , tya.attribute
FROM firstnf.title_basics tb
INNER JOIN firstnf.title_types_attributes tya
  ON (tb.tconst = tya.tconst)
WHERE tb.tconst = ('tt' || LPAD(CAST(:title_number AS text), 7, '0'))::character varying;
