--------------------------------
--------------------------------
-- Q4
-- Based on a person's identifier, find the person's name, birthyear, deathyear, primary professions, and names of the titles the person is known for. Primary professions are not related to the titles the person is known for in the result table (such data is not available in the database).
--------------------------------
--------------------------------

--------------------------------
-- secondnf:
--------------------------------

\set person_number random(1, 9993719)

SELECT DISTINCT
       nb.primaryname
     , nb.birthyear
     , nb.deathyear
     , npt.primaryprofession
     , npt.knownfortitle
FROM secondnf.name_basics nb
LEFT OUTER JOIN secondnf.name_professions_titles npt
  ON (nb.nconst = npt.nconst)
WHERE nb.nconst = ('nm' || LPAD(CAST(:person_number AS text), 7, '0'))::character varying;
