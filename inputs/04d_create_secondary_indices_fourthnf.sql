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
