--------------------------------
--------------------------------
-- Q2
-- Based on a person's identifier, find the names of the titles the person is known for.
--------------------------------
--------------------------------

--------------------------------
-- secondnf:
--------------------------------

\set person_number random(1, 9993719)

SELECT ta.title
FROM secondnf.title_akas ta
INNER JOIN secondnf.name_professions_titles npt
  ON (ta.tconst = npt.knownfortitle)
WHERE ta.isoriginaltitle IS True
AND npt.nconst = ('nm' || LPAD(CAST(:person_number AS text), 7, '0'))::character varying;
