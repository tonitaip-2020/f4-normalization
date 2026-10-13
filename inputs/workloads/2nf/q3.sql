--------------------------------
--------------------------------
-- Q3
-- Based on a title's identifier, find the names of each episode for each season.
--------------------------------
--------------------------------

--------------------------------
-- secondnf:
--------------------------------

\set title_number random(1, 12844280)

SELECT te.seasonnumber
     , te.episodenumber
     , ta.title
FROM secondnf.title_akas ta
INNER JOIN secondnf.title_basics tb
  ON (ta.tconst = tb.tconst)
INNER JOIN secondnf.title_episodes te
  ON (tb.tconst = te.tconst_parent)
WHERE tb.titletype = 'tvSeries'
AND   tb.tconst = ('tt' || LPAD(CAST(:title_number AS text), 7, '0'))::character varying
ORDER BY te.seasonnumber  ASC
       , te.episodenumber ASC;
