--------------------------------
--------------------------------
-- Q3
-- Based on a title's identifier, find the names of each episode for each season.
--------------------------------
--------------------------------

--------------------------------
-- public (baseline)
--------------------------------

\set title_number random(1, 12844280)

SELECT te.seasonnumber
     , te.episodenumber
     , tb.primarytitle
FROM public.title_basics tb
INNER JOIN public.title_episode te
  ON (tb.tconst = te.parenttconst)
WHERE tb.titletype = 'tvSeries'
AND   tb.tconst = ('tt' || LPAD(CAST(:title_number AS text), 7, '0'))::character varying
ORDER BY te.seasonnumber  ASC
       , te.episodenumber ASC;
