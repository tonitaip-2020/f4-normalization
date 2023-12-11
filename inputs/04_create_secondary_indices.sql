-- Create secondary indices for all tables in all schemas.

--------------------------------------
-- public (baseline):
--------------------------------------

CREATE INDEX title_basics_titletype_idx      ON public.title_basics     (titletype);
CREATE INDEX title_ratings_averagerating_idx ON public.title_ratings    (numvotes, averagerating DESC);
CREATE INDEX title_principals_category_idx   ON public.title_principals (category);
CREATE INDEX title_principals_tconst_idx     ON public.title_principals (tconst);
CREATE INDEX title_episode_parenttconst_idx  ON public.title_episode    (parenttconst);

SELECT 'Created secondary indices for the baseline schema.' AS status;

--------------------------------------
-- firstnf:
--------------------------------------

CREATE INDEX title_basics_isoriginaltitle_idx          ON firstnf.title_basics            (isoriginaltitle);
CREATE INDEX title_basics_titletype_averagerating_idx  ON firstnf.title_basics            (titletype, numvotes, averagerating DESC);
CREATE INDEX title_directors_writers_director_idx      ON firstnf.title_directors_writers (director);
CREATE INDEX name_basics_tconst_idx                    ON firstnf.name_basics             (tconst);
CREATE INDEX name_professions_titles_knownfortitle_idx ON firstnf.name_professions_titles (knownfortitle);
CREATE INDEX title_characters_tconst_idx               ON firstnf.title_characters        (tconst);

SELECT 'Created secondary indices for the firstnf schema.' AS status;

--------------------------------------
-- secondnf:
--------------------------------------

CREATE INDEX title_basics_titletype_averagerating_idx  ON secondnf.title_basics            (titletype, numvotes, averagerating DESC);
CREATE INDEX title_akas_isoriginaltitle_idx            ON secondnf.title_akas              (isoriginaltitle);
CREATE INDEX title_characters_tconst_idx               ON secondnf.title_characters        (tconst);
CREATE INDEX title_principals_tconst_idx               ON secondnf.title_principals        (tconst);
CREATE INDEX title_directors_writers_director_idx      ON secondnf.title_directors_writers (director);
CREATE INDEX title_directors_writers_writer_idx        ON secondnf.title_directors_writers (writer);
CREATE INDEX name_professions_titles_knownfortitle_idx ON secondnf.name_professions_titles (knownfortitle);

SELECT 'Created secondary indices for the secondnf schema.' AS status;

--------------------------------------
-- fourthnf:
--------------------------------------

CREATE INDEX title_basics_titletype_averagerating_idx  ON fourthnf.title_basics     (titletype, numvotes, averagerating DESC);
CREATE INDEX title_akas_isoriginaltitle_idx            ON fourthnf.title_akas       (isoriginaltitle);
CREATE INDEX title_characters_tconst_idx               ON fourthnf.title_characters (tconst);
CREATE INDEX title_principals_tconst_idx               ON fourthnf.title_principals (tconst);
CREATE INDEX title_directors_director_idx              ON fourthnf.title_directors  (director);
CREATE INDEX title_writers_writer_idx                  ON fourthnf.title_writers    (writer);
CREATE INDEX name_titles_knownfortitle_idx             ON fourthnf.name_titles      (knownfortitle);

SELECT 'Created secondary indices for the fourthnf schema.' AS status;