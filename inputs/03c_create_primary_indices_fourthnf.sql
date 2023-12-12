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
