--------------------------------
--------------------------------
-- Q2
-- Based on a person's identifier, find the names of the titles the person is known for.
--------------------------------
--------------------------------

--------------------------------
-- firstnf:
--------------------------------

\set person_number random(1, 9993719)

SELECT tb.title
FROM firstnf.title_basics tb
INNER JOIN firstnf.name_professions_titles npt
  ON (tb.tconst = npt.knownfortitle)
WHERE tb.isoriginaltitle IS True
AND npt.nconst = ('nm' || LPAD(CAST(:person_number AS text), 7, '0'))::character varying;
