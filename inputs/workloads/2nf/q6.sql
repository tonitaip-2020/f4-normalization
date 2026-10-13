--------------------------------
--------------------------------
-- Q6
-- Based on a title's identifier, find the names, birthyears, categories and jobs of all people who worked on the title, and the title's startyear. Sort the results according to birthyear, descending.
--------------------------------
--------------------------------

--------------------------------
-- secondnf:
--------------------------------

\set title_number random(1, 12844280)

SELECT nb.primaryname
     , nb.birthyear
     , tp.category
     , tp.job
     , tb.startyear
FROM secondnf.title_basics tb
INNER JOIN secondnf.title_principals tp
  ON (tb.tconst = tp.tconst)
INNER JOIN secondnf.name_basics nb
  ON (tp.nconst = nb.nconst)
WHERE tb.tconst = ('tt' || LPAD(CAST(:title_number AS text), 7, '0'))::character varying
ORDER BY nb.birthyear DESC;
