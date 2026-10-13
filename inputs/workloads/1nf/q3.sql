--------------------------------
--------------------------------
-- Q3
-- Based on a title's identifier, find the names of each episode for each season.
--------------------------------
--------------------------------

--------------------------------
-- firstnf:
--------------------------------

\set title_number random(1, 12844280)

SELECT te.seasonnumber
     , te.episodenumber
     , tb.title
FROM firstnf.title_basics tb
INNER JOIN firstnf.title_episodes te
  ON (tb.tconst = te.tconst_parent)
WHERE tb.titletype = 'tvSeries' 
AND   tb.tconst = ('tt' || LPAD(CAST(:title_number AS text), 7, '0'))::character varying
ORDER BY te.seasonnumber  ASC
       , te.episodenumber ASC; 
