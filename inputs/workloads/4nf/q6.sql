--------------------------------
--------------------------------
-- Q6
-- Based on a title's identifier, find the names, birthyears, categories and jobs of all people who worked on the title, and the title's startyear. Sort the results according to birthyear, descending.
--------------------------------
--------------------------------

--------------------------------
-- fourthnf:
--------------------------------

\set title_number random(1, 12844280)

SELECT nb.primaryname
     , nb.birthyear
     , tp.category
     , tp.job
     , tb.startyear
FROM fourthnf.title_basics tb
INNER JOIN fourthnf.title_principals tp
  ON (tb.tconst = tp.tconst)
INNER JOIN fourthnf.name_basics nb
  ON (tp.nconst = nb.nconst)
WHERE tb.tconst = ('tt' || LPAD(CAST(:title_number AS text), 7, '0'))::character varying
ORDER BY nb.birthyear DESC;
