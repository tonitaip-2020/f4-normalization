--------------------------------
--------------------------------
-- Q6
-- Based on a title's identifier, find the names, birthyears, categories and jobs of all people who worked on the title, and the title's startyear. Sort the results according to birthyear, descending.
--------------------------------
--------------------------------

--------------------------------
-- firstnf:
--------------------------------

\set title_number random(1, 12844280)

SELECT nb.primaryname
     , nb.birthyear
     , nb.category
     , nb.job
     , tb.startyear
FROM firstnf.title_basics tb
INNER JOIN firstnf.name_basics nb
  ON (tb.tconst = nb.tconst)
WHERE tb.tconst = ('tt' || LPAD(CAST(:title_number AS text), 7, '0'))::character varying
ORDER BY nb.birthyear DESC;
