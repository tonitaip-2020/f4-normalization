-- Create primary indices for all tables in all schemas.

--------------------------------------
-- nfnf:
--------------------------------------

-- This can take several hours
CREATE INDEX title_basics_idx ON nfnf.title_basics (tconst);

SELECT 'Created primary indices for the nfnf schema.' AS status;

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

--------------------------------------
-- secondnf:
--------------------------------------

CREATE INDEX title_basics_idx     ON secondnf.title_basics (tconst);
CREATE INDEX title_akas_idx       ON secondnf.title_akas (tconst);
CREATE INDEX name_basics_idx      ON secondnf.name_basics (nconst);
CREATE INDEX title_principals_idx ON secondnf.title_principals (nconst);
CREATE INDEX title_genres_idx     ON secondnf.title_genres (tconst);
CREATE INDEX title_episodes_idx   ON secondnf.title_episodes (tconst_parent);
CREATE INDEX title_characters_idx ON secondnf.title_characters (nconst);

CREATE INDEX title_types_attributes_idx  ON secondnf.title_types_attributes (tconst);
CREATE INDEX title_directors_writers_idx ON secondnf.title_directors_writers (tconst);
CREATE INDEX name_professions_titles_idx ON secondnf.name_professions_titles (nconst);

SELECT 'Created primary indices for the secondnf schema.' AS status;

--------------------------------------
-- fourthnf:
--------------------------------------

CREATE INDEX title_types_idx      ON fourthnf.title_types (tconst);
CREATE INDEX title_attributes_idx ON fourthnf.title_attributes (tconst);
CREATE INDEX title_basics_idx     ON fourthnf.title_basics (tconst);
CREATE INDEX title_akas_idx       ON fourthnf.title_akas (tconst);
CREATE INDEX title_principals_idx ON fourthnf.title_principals (nconst);
CREATE INDEX title_genres_idx     ON fourthnf.title_genres (tconst);
CREATE INDEX title_episodes_idx   ON fourthnf.title_episodes (tconst_parent);
CREATE INDEX title_directors_idx  ON fourthnf.title_directors (tconst);
CREATE INDEX title_writers_idx    ON fourthnf.title_writers (tconst);
CREATE INDEX title_characters_idx ON fourthnf.title_characters (nconst);
CREATE INDEX name_basics_idx      ON fourthnf.name_basics (nconst);
CREATE INDEX name_professions_idx ON fourthnf.name_professions (nconst);
CREATE INDEX name_titles_idx      ON fourthnf.name_titles (nconst);

SELECT 'Created primary indices for the fourthnf schema.' AS status;
