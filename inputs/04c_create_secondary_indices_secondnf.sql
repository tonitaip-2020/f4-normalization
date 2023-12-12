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
