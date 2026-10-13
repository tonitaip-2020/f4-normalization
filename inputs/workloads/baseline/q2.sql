--------------------------------
--------------------------------
-- Q2
-- Based on a person's identifier, find the names of the titles the person is known for.
--------------------------------
--------------------------------

--------------------------------
-- public (baseline)
--------------------------------

\set person_number random(1, 9993719)

WITH kft AS (
  SELECT UNNEST(STRING_TO_ARRAY(nb.knownfortitles, ',')) AS title
  FROM public.name_basics nb
  WHERE nb.nconst = ('nm' || LPAD(CAST(:person_number AS text), 7, '0'))::character varying
)
SELECT tb.primarytitle
FROM public.title_basics tb
INNER JOIN kft
  ON (kft.title = tb.tconst);
