--------------------------------
-- Set pgbench variables for tconst and nconst (not in use)
--------------------------------

-- Generate a random number for min. and max. tconst:
--\set number_tconst :randint(1, 9916880)

-- Generate a random number for min. and max. nconst:
--\set number_nconst :randint(1, 9993719)

--------------------------------
--------------------------------
-- Q1
-- Based on a movies's rating, list the primary names and ratings of the best 250 movies. IMDb's TOP-250 list is based on additional data not present in the dataset.
--------------------------------
--------------------------------

--------------------------------
-- public (baseline)
--------------------------------

SELECT tb.primarytitle
     , tr.averagerating
FROM public.title_basics tb
INNER JOIN public.title_ratings tr
  ON (tb.tconst = tr.tconst)
WHERE tb.titletype = 'movie'
AND   tr.numvotes > 25000
ORDER BY tr.averagerating DESC
LIMIT 250;