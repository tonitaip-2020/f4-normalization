-- Clean title.principals.characters:
UPDATE public.title_principals
SET characters = TRANSLATE(characters, '[', '');
UPDATE public.title_principals
SET characters = TRANSLATE(characters, ']', '');
UPDATE public.title_principals
SET characters = TRANSLATE(characters, '"', '');

-- Drop the indices that are not used by the benchmark:
DROP INDEX public.title_idx;

--------------------------------------
-- nfnf (flat):
--------------------------------------
-- This is more of a curiosity and should be skipped
-- Populating this table will take several hundred GBs.
-- Other schemas some dozens of GBs each.

-- DROP TABLE IF EXISTS nfnf.title_basics;

-- CREATE TABLE nfnf.title_basics (
--   tconst             VARCHAR
-- , genres             VARCHAR
-- , ordering_aka       NUMERIC -- from title_aka
-- , title              VARCHAR
-- , titletype          VARCHAR
-- , isoriginaltitle    BOOLEAN --from title_aka
-- -- does not need "primarytitle" or "originaltitle" anymore
-- , region             VARCHAR
-- , language           VARCHAR
-- , types              VARCHAR --from title_aka
-- , attributes         VARCHAR --from title_aka
-- , isadult            BOOLEAN
-- , startyear          NUMERIC
-- , endyear            NUMERIC
-- , runtimeminutes     VARCHAR
-- , averagerating      NUMERIC --from title_ratings
-- , numvotes           NUMERIC --from title_ratings
-- , directors          VARCHAR --from title_crew
-- , writers            VARCHAR --from title_crew
-- , nconst             VARCHAR --from title_principals
-- , ordering_pri       NUMERIC --from title_principals
-- , category           VARCHAR --from title_principals
-- , job                VARCHAR --from title_principals
-- , characters         VARCHAR --from title_principals 
-- -- does not need "parentconst" anymore
-- , seasonnumber       VARCHAR --from title_episode
-- , episodenumber      VARCHAR --from title_episode
-- , primaryname        VARCHAR --from name_basics
-- , birthyear          NUMERIC --from name_basics
-- , deathyear          NUMERIC --from name_basics
-- , primaryprofessions VARCHAR --from name_basics
-- , knownfortitles     VARCHAR --from name_basics
-- );

--------------------------------------
-- firstnf:
--------------------------------------

DROP TABLE IF EXISTS firstnf.name_basics              CASCADE;
DROP TABLE IF EXISTS firstnf.title_basics             CASCADE;
DROP TABLE IF EXISTS firstnf.title_characters         CASCADE;
DROP TABLE IF EXISTS firstnf.title_genres             CASCADE;
DROP TABLE IF EXISTS firstnf.title_types_attributes   CASCADE;
DROP TABLE IF EXISTS firstnf.title_directors_writers  CASCADE;
DROP TABLE IF EXISTS firstnf.title_episodes           CASCADE;
DROP TABLE IF EXISTS firstnf.name_professions_titles  CASCADE;

CREATE TABLE firstnf.name_basics (
  nconst      VARCHAR
, tconst      VARCHAR
, ordering    NUMERIC
, category    VARCHAR
, job         VARCHAR
, primaryname VARCHAR
, birthyear   NUMERIC
, deathyear   NUMERIC
);

CREATE TABLE firstnf.title_basics (
  tconst          VARCHAR --PK
, ordering        NUMERIC --PK, from akas, required for an AK for 1NF
, title           VARCHAR
, titletype       VARCHAR
, isoriginaltitle BOOLEAN
, region          VARCHAR
, language        VARCHAR
, isadult         BOOLEAN
, startyear       NUMERIC
, endyear         NUMERIC
, runtimeminutes  VARCHAR
, averagerating   NUMERIC
, numvotes        NUMERIC
);

CREATE TABLE firstnf.title_characters (
  tconst    VARCHAR --PK
, nconst    VARCHAR --PK
, character VARCHAR
);

CREATE TABLE firstnf.title_genres (
  tconst VARCHAR --PK
, genre  VARCHAR --PK
);

CREATE TABLE firstnf.title_types_attributes (
  tconst    VARCHAR --PK
, type      VARCHAR --PK, cannot be enforced
, attribute VARCHAR --PK, cannot be enforced
);

CREATE TABLE firstnf.title_directors_writers (
  tconst   VARCHAR --PK
, director VARCHAR --PK, cannot be enforced
, writer   VARCHAR --PK, cannot be enforced
);

CREATE TABLE firstnf.title_episodes (
  tconst        VARCHAR --PK
, tconst_parent VARCHAR --The parent title to which the episode belongs to
, seasonnumber  VARCHAR
, episodenumber VARCHAR
);

CREATE TABLE firstnf.name_professions_titles (
  nconst            VARCHAR --PK
, primaryprofession VARCHAR --PK, cannot be enforced
, knownfortitle     VARCHAR --PK, cannot be enforced
);

SELECT 'Created the firstnf schema.' AS status;

--------------------------------------
-- secondnf:
--------------------------------------

DROP TABLE IF EXISTS secondnf.name_basics              CASCADE;
DROP TABLE IF EXISTS secondnf.name_professions_titles  CASCADE;
DROP TABLE IF EXISTS secondnf.title_principals         CASCADE;
DROP TABLE IF EXISTS secondnf.title_characters         CASCADE;
DROP TABLE IF EXISTS secondnf.title_basics             CASCADE;
DROP TABLE IF EXISTS secondnf.title_akas               CASCADE;
DROP TABLE IF EXISTS secondnf.title_genres             CASCADE;
DROP TABLE IF EXISTS secondnf.title_types_attributes   CASCADE;
DROP TABLE IF EXISTS secondnf.title_directors_writers  CASCADE;
DROP TABLE IF EXISTS secondnf.title_episodes           CASCADE;


CREATE TABLE secondnf.name_basics (
    nconst      VARCHAR
  , primaryname VARCHAR
  , birthyear   NUMERIC
  , deathyear   NUMERIC
);

CREATE TABLE secondnf.title_principals (
    nconst   VARCHAR
  , tconst   VARCHAR
  , ordering NUMERIC
  , category VARCHAR
  , job      VARCHAR
);

CREATE TABLE secondnf.title_basics (
    tconst         VARCHAR
  , titletype      VARCHAR
  , isadult        BOOLEAN
  , startyear      NUMERIC
  , endyear        NUMERIC
  , runtimeminutes VARCHAR
  , averagerating  NUMERIC
  , numvotes       NUMERIC
);

CREATE TABLE secondnf.title_akas (
    tconst          VARCHAR
  , ordering        NUMERIC
  , title           VARCHAR
  , isoriginaltitle BOOLEAN
  , region          VARCHAR
  , language        VARCHAR
);

CREATE TABLE secondnf.title_characters (
  tconst    VARCHAR --PK
, nconst    VARCHAR --PK
, character VARCHAR --PK
);

CREATE TABLE secondnf.title_genres (
  tconst VARCHAR --PK
, genre  VARCHAR --PK
);

CREATE TABLE secondnf.title_types_attributes (
  tconst    VARCHAR --PK
, type      VARCHAR --PK, cannot be enforced
, attribute VARCHAR --PK, cannot be enforced
);

CREATE TABLE secondnf.title_directors_writers (
  tconst   VARCHAR --PK
, director VARCHAR --PK, cannot be enforced
, writer   VARCHAR --PK, cannot be enforced
);

CREATE TABLE secondnf.title_episodes (
  tconst        VARCHAR --PK
, tconst_parent VARCHAR --The parent title to which the episode belongs to
, seasonnumber  VARCHAR
, episodenumber VARCHAR
);

CREATE TABLE secondnf.name_professions_titles (
  nconst            VARCHAR --PK
, primaryprofession VARCHAR --PK, cannot be enforced
, knownfortitle     VARCHAR --PK, cannot be enforced
);

SELECT 'Created the secondnf schema.' AS status;

--------------------------------------
-- fourthnf:
--------------------------------------

DROP TABLE IF EXISTS fourthnf.title_basics     CASCADE;
DROP TABLE IF EXISTS fourthnf.title_akas       CASCADE;
DROP TABLE IF EXISTS fourthnf.name_basics      CASCADE;
DROP TABLE IF EXISTS fourthnf.title_principals CASCADE;
DROP TABLE IF EXISTS fourthnf.title_genres     CASCADE;
DROP TABLE IF EXISTS fourthnf.title_episodes   CASCADE;
DROP TABLE IF EXISTS fourthnf.title_characters CASCADE;
DROP TABLE IF EXISTS fourthnf.name_professions CASCADE;
DROP TABLE IF EXISTS fourthnf.name_titles      CASCADE;
DROP TABLE IF EXISTS fourthnf.title_attributes CASCADE;
DROP TABLE IF EXISTS fourthnf.title_types      CASCADE;
DROP TABLE IF EXISTS fourthnf.title_writers    CASCADE;
DROP TABLE IF EXISTS fourthnf.title_directors  CASCADE;

CREATE TABLE fourthnf.name_basics (
    nconst      VARCHAR
  , primaryname VARCHAR
  , birthyear   NUMERIC
  , deathyear   NUMERIC
);

CREATE TABLE fourthnf.title_principals (
    nconst   VARCHAR
  , tconst   VARCHAR
  , ordering NUMERIC
  , category VARCHAR
  , job      VARCHAR
);

CREATE TABLE fourthnf.title_basics (
    tconst         VARCHAR
  , titletype      VARCHAR
  , isadult        BOOLEAN
  , startyear      NUMERIC
  , endyear        NUMERIC
  , runtimeminutes VARCHAR
  , averagerating  NUMERIC
  , numvotes       NUMERIC
);

CREATE TABLE fourthnf.title_akas (
    tconst          VARCHAR
  , ordering        NUMERIC
  , title           VARCHAR
  , isoriginaltitle BOOLEAN
  , region          VARCHAR
  , language        VARCHAR
);

CREATE TABLE fourthnf.title_characters (
  tconst    VARCHAR --PK
, nconst    VARCHAR --PK
, character VARCHAR --PK
);

CREATE TABLE fourthnf.title_genres (
  tconst VARCHAR --PK
, genre  VARCHAR --PK
);

CREATE TABLE fourthnf.title_episodes (
  tconst        VARCHAR --PK
, tconst_parent VARCHAR --The parent title to which the episode belongs to
, seasonnumber  VARCHAR
, episodenumber VARCHAR
);

CREATE TABLE fourthnf.title_types (
  tconst    VARCHAR --PK
, type      VARCHAR --PK
);

CREATE TABLE fourthnf.title_attributes (
  tconst    VARCHAR --PK
, attribute VARCHAR
);

CREATE TABLE fourthnf.title_directors (
  tconst   VARCHAR --PK
, director VARCHAR --PK
);

CREATE TABLE fourthnf.title_writers (
  tconst   VARCHAR --PK
, writer   VARCHAR --PK
);

CREATE TABLE fourthnf.name_professions (
  nconst            VARCHAR --PK
, primaryprofession VARCHAR --PK
);

CREATE TABLE fourthnf.name_titles (
  nconst            VARCHAR --PK
, knownfortitle     VARCHAR --PK
);

SELECT 'Created the fourthnf schema.' AS status;
