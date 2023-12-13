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
