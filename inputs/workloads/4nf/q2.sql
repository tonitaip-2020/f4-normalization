--------------------------------
--------------------------------
-- Q2
-- Based on a person's identifier, find the names of the titles the person is known for.
--------------------------------
--------------------------------

--------------------------------
-- fourthnf:
--------------------------------

\set person_number random(1, 9993719)

SELECT ta.title
FROM fourthnf.title_akas ta
INNER JOIN fourthnf.name_titles nt
  ON (ta.tconst = nt.knownfortitle)
WHERE ta.isoriginaltitle IS True
AND nt.nconst = ('nm' || LPAD(CAST(:person_number AS text), 7, '0'))::character varying;
