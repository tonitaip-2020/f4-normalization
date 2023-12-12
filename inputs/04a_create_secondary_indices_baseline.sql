-- Create secondary indices:

--------------------------------------
-- public (baseline):
--------------------------------------

CREATE INDEX title_basics_titletype_idx      ON public.title_basics     (titletype);
CREATE INDEX title_ratings_averagerating_idx ON public.title_ratings    (numvotes, averagerating DESC);
CREATE INDEX title_principals_category_idx   ON public.title_principals (category);
CREATE INDEX title_principals_tconst_idx     ON public.title_principals (tconst);
CREATE INDEX title_episode_parenttconst_idx  ON public.title_episode    (parenttconst);

SELECT 'Created secondary indices for the baseline schema.' AS status;
