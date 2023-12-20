--------------------------------------
-- nfnf (flat):
--------------------------------------
-- This is more of a curiosity and should be skipped
-- Populating this table will take several hundred GBs.

DROP TABLE IF EXISTS nfnf.title_basics;

CREATE TABLE nfnf.title_basics (
  tconst             VARCHAR
, genres             VARCHAR
, ordering_aka       NUMERIC -- from title_aka
, title              VARCHAR
, titletype          VARCHAR
, isoriginaltitle    BOOLEAN --from title_aka
-- does not need "primarytitle" or "originaltitle" anymore
, region             VARCHAR
, language           VARCHAR
, types              VARCHAR --from title_aka
, attributes         VARCHAR --from title_aka
, isadult            BOOLEAN
, startyear          NUMERIC
, endyear            NUMERIC
, runtimeminutes     VARCHAR
, averagerating      NUMERIC --from title_ratings
, numvotes           NUMERIC --from title_ratings
, directors          VARCHAR --from title_crew
, writers            VARCHAR --from title_crew
, nconst             VARCHAR --from title_principals
, ordering_pri       NUMERIC --from title_principals
, category           VARCHAR --from title_principals
, job                VARCHAR --from title_principals
, characters         VARCHAR --from title_principals 
-- does not need "parentconst" anymore
, seasonnumber       VARCHAR --from title_episode
, episodenumber      VARCHAR --from title_episode
, primaryname        VARCHAR --from name_basics
, birthyear          NUMERIC --from name_basics
, deathyear          NUMERIC --from name_basics
, primaryprofessions VARCHAR --from name_basics
, knownfortitles     VARCHAR --from name_basics
);


--------------------------------------
-- nfnf (flat):
--------------------------------------

-- This schema is more of a curiosity, should be skipped.
-- This will take several hours and several hundred GBs to complete, so before execution, do
-- => SET statement_timeout 99999999;

Populate nfnf.title_basics:
WITH 
  cte_nb_unnest AS (
  SELECT nconst
       , primaryname
	   , birthyear
	   , deathyear
	   , UNNEST(STRING_TO_ARRAY(primaryprofession, ',')) AS primaryprofession
	   , UNNEST(STRING_TO_ARRAY(knownfortitles, ',')) AS knownfortitle
  FROM public.name_basics
)
, cte_tp_unnest AS (
  SELECT tconst
       , ordering AS ordering_pri
	   , nconst
	   , category
	   , job
	   , UNNEST(STRING_TO_ARRAY(characters, ',')) AS character
  FROM public.title_principals
)
, cte_nb_and_tp AS (
  SELECT tp.tconst
       , tp.ordering_pri
	   , tp.nconst
	   , tp.category
	   , tp.job
	   , tp.character
	   , nb.primaryname
	   , nb.birthyear
	   , nb.deathyear
	   , nb.primaryprofession
	   , nb.knownfortitle
  FROM cte_nb_unnest nb
  FULL OUTER JOIN cte_tp_unnest tp ON (nb.nconst = tp.nconst)
)
, cte_tb_unnest AS (
  SELECT tconst
       , titletype
	   , isadult
	   , startyear
	   , endyear
	   , runtimeminutes
	   , UNNEST(STRING_TO_ARRAY(genres, ',')) AS genre
  FROM public.title_basics
)
, cte_4 AS (
  SELECT tb.titletype
       , tb.isadult
	   , tb.startyear
	   , tb.endyear
	   , tb.runtimeminutes
	   , tb.genre
	   , tb.tconst -- Changed, keep this one
	   , nbtp.ordering_pri
	   , nbtp.nconst
	   , nbtp.category
	   , nbtp.job
	   , nbtp.character
	   , nbtp.primaryname
	   , nbtp.birthyear
	   , nbtp.deathyear
	   , nbtp.primaryprofession
	   , nbtp.knownfortitle
  FROM cte_tb_unnest tb
  FULL OUTER JOIN cte_nb_and_tp AS nbtp ON (tb.tconst = nbtp.tconst)
)
, cte_tc_unnest AS (
  SELECT tconst
       , UNNEST(STRING_TO_ARRAY(directors, ',')) AS director
	   , UNNEST(STRING_TO_ARRAY(writers, ',')) AS writer
  FROM public.title_crew
)
, cte_5 AS (
  SELECT cte_4.titletype
       , cte_4.tconst
       , cte_4.isadult
	   , cte_4.startyear
	   , cte_4.endyear
	   , cte_4.runtimeminutes
	   , cte_4.genre
	   , cte_4.ordering_pri
	   , cte_4.nconst
	   , cte_4.category
	   , cte_4.job
	   , cte_4.character
	   , cte_4.primaryname
	   , cte_4.birthyear
	   , cte_4.deathyear
	   , cte_4.primaryprofession
	   , cte_4.knownfortitle
	   , tc.director
	   , tc.writer
  FROM cte_4
  FULL OUTER JOIN cte_tc_unnest tc ON (cte_4.tconst = tc.tconst)
)
, cte_6 AS (
  SELECT cte_5.titletype
       , cte_5.tconst
       , cte_5.isadult
	   , cte_5.startyear
	   , cte_5.endyear
	   , cte_5.runtimeminutes
	   , cte_5.genre
	   , cte_5.ordering_pri
	   , cte_5.nconst
	   , cte_5.category
	   , cte_5.job
	   , cte_5.character
	   , cte_5.primaryname
	   , cte_5.birthyear
	   , cte_5.deathyear
	   , cte_5.primaryprofession
	   , cte_5.knownfortitle
	   , cte_5.director
	   , cte_5.writer
	   , tr.averagerating
	   , tr.numvotes
  FROM public.title_ratings tr
  FULL OUTER JOIN cte_5 ON (cte_5.tconst = tr.tconst)
)
, cte_ta_unnest AS (
  SELECT titleid
       , ordering AS ordering_aka
	   , title
	   , region
	   , language
	   , UNNEST(STRING_TO_ARRAY(types, ',')) AS type
	   , UNNEST(STRING_TO_ARRAY(attributes, ',')) AS attribute
	   , isoriginaltitle
  FROM public.title_akas
)
, cte_7 AS (
  SELECT cte_6.titletype
       , cte_6.tconst
       , cte_6.isadult
	   , cte_6.startyear
	   , cte_6.endyear
	   , cte_6.runtimeminutes
	   , cte_6.genre
	   , cte_6.ordering_pri
	   , cte_6.nconst
	   , cte_6.category
	   , cte_6.job
	   , cte_6.character
	   , cte_6.primaryname
	   , cte_6.birthyear
	   , cte_6.deathyear
	   , cte_6.primaryprofession
	   , cte_6.knownfortitle
	   , cte_6.director
	   , cte_6.writer
	   , cte_6.averagerating
	   , cte_6.numvotes
	   , ta.titleid
	   , ta.ordering_aka
	   , ta.title
	   , ta.region
	   , ta.language
	   , ta.type
	   , ta.attribute
	   , ta.isoriginaltitle
  FROM cte_6
  FULL OUTER JOIN cte_ta_unnest ta ON (cte_6.tconst = ta.titleid)
)
, cte_8 AS (
  SELECT cte_7.tconst
	   , cte_7.genre
	   , cte_7.ordering_aka
	   , cte_7.title
	   , cte_7.titletype
	   , cte_7.isoriginaltitle
	   , cte_7.region
	   , cte_7.language
	   , cte_7.type
	   , cte_7.attribute
	   , cte_7.isadult
	   , cte_7.startyear
	   , cte_7.endyear
	   , cte_7.runtimeminutes
	   , cte_7.averagerating
	   , cte_7.numvotes	   
	   , cte_7.director
	   , cte_7.writer	   
	   , cte_7.nconst
	   , cte_7.ordering_pri
	   , cte_7.category
	   , cte_7.job
	   , cte_7.character
	   , te.seasonnumber
	   , te.episodenumber
	   , cte_7.primaryname
	   , cte_7.birthyear
	   , cte_7.deathyear
	   , cte_7.primaryprofession
	   , cte_7.knownfortitle
	   --, cte_7.titleid this is for joining title_akas and cte_7
  FROM public.title_episode te
  FULL OUTER JOIN cte_7 ON (cte_7.tconst = te.parenttconst)
)
INSERT INTO nfnf.title_basics
SELECT * FROM cte_8;

SELECT 'Populated the nfnf schema.' AS status;

