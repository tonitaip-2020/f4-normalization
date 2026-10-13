--------------------------------
--------------------------------
-- Q5
-- Based on a title's identifier, find all titles, title types and title attributes.
--------------------------------
--------------------------------

--------------------------------
-- public (baseline)
--------------------------------

\set title_number random(1, 12844280)

SELECT ta.title
     , UNNEST(STRING_TO_ARRAY(ta.types, ','))      AS type
     , UNNEST(STRING_TO_ARRAY(ta.attributes, ',')) AS attribute
FROM public.title_akas ta
WHERE ta.titleid = ('tt' || LPAD(CAST(:title_number AS text), 7, '0'))::character varying;
