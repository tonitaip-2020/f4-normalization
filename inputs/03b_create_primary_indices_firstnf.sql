-- Create primary indices for all tables

--------------------------------------
-- nfnf:
--------------------------------------

-- This can take several hours, should be skipped:
-- CREATE INDEX title_basics_idx ON nfnf.title_basics (tconst);

--SELECT 'Created primary indices for the nfnf schema.' AS status;

--------------------------------------
-- firstnf:
--------------------------------------

CREATE INDEX title_basics_idx     ON firstnf.title_basics (tconst);
CREATE INDEX title_genres_idx     ON firstnf.title_genres (tconst);
CREATE INDEX title_characters_idx ON firstnf.title_characters (nconst);
CREATE INDEX title_episodes_idx   ON firstnf.title_episodes (tconst_parent);
CREATE INDEX name_basics_idx      ON firstnf.name_basics (nconst);

CREATE INDEX title_types_attributes_idx  ON firstnf.title_types_attributes (tconst);
CREATE INDEX title_directors_writers_idx ON firstnf.title_directors_writers (tconst);
CREATE INDEX name_professions_titles_idx ON firstnf.name_professions_titles (nconst);

SELECT 'Created primary indices for the firstnf schema.' AS status;
