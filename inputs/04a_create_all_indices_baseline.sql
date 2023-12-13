-- Create secondary indices and ensure the initial script has created primary indices:

--------------------------------------
-- public (baseline):
--------------------------------------

ALTER TABLE public.name_basics  DROP CONSTRAINT name_basics_pk  CASCADE;
ALTER TABLE public.title_basics DROP CONSTRAINT title_basics_pk CASCADE;

CREATE INDEX name_basics_idx      ON public.name_basics (nconst);
CREATE INDEX title_basics_idx     ON public.title_basics (tconst);
CREATE INDEX title_ratings_idx    ON public.title_ratings (tconst);
CREATE INDEX title_crew_idx       ON public.title_crew (tconst);
CREATE INDEX title_akas_idx       ON public.title_akas (titleid, ordering);
CREATE INDEX title_episode_idx    ON public.title_episode (tconst, seasonnumber, episodenumber);
CREATE INDEX title_principals_idx ON public.title_principals (tconst, nconst, ordering);

SELECT 'Created primary indices for the baseline schema.' AS status;

CREATE INDEX title_basics_titletype_idx      ON public.title_basics     (titletype);
CREATE INDEX title_ratings_averagerating_idx ON public.title_ratings    (numvotes, averagerating DESC);
CREATE INDEX title_principals_category_idx   ON public.title_principals (category);
CREATE INDEX title_principals_tconst_idx     ON public.title_principals (tconst);
CREATE INDEX title_episode_parenttconst_idx  ON public.title_episode    (parenttconst);

SELECT 'Created secondary indices for the baseline schema.' AS status;
