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
