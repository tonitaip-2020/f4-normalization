--------------------------------
--------------------------------
-- Q4
-- Based on a person's identifier, find the person's name, birthyear, deathyear, primary professions, and names of the titles the person is known for. Primary professions are not related to the titles the person is known for in the result table (such data is not available in the database).
--------------------------------
--------------------------------

--------------------------------
-- public (baseline)
--------------------------------

\set person_number random(1, 9993719)

SELECT nb.primaryname
     , nb.birthyear
     , nb.deathyear
     , UNNEST(STRING_TO_ARRAY(nb.primaryprofession, ',')) AS primaryprofession
     , UNNEST(STRING_TO_ARRAY(nb.knownfortitles, ','))    AS knownfortitle
FROM public.name_basics nb
WHERE nb.nconst = ('nm' || LPAD(CAST(:person_number AS text), 7, '0'))::character varying;
