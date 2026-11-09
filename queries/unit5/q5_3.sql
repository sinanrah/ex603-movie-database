-- 5.3A-1 Every possible pairing of a genre and a title.
--        Requirement: CROSS JOIN between two small tables.
--        Finding: 75 rows, one for each genre and title pair.
SELECT g.genre_name,
       m.title
FROM   genres g
CROSS JOIN movies m
ORDER BY g.genre_name, m.title;

-- 5.3A-2 Does the CROSS JOIN row count equal the two table counts multiplied?
--        Requirement: count each source table and the CROSS JOIN result.
--        Finding: 5 genres x 15 titles = 75, which matches the CROSS JOIN count.
SELECT (SELECT COUNT(*) FROM genres)                         AS genre_rows,
       (SELECT COUNT(*) FROM movies)                         AS movie_rows,
       (SELECT COUNT(*) FROM genres)
     * (SELECT COUNT(*) FROM movies)                         AS expected_rows,
       (SELECT COUNT(*) FROM genres g CROSS JOIN movies m)   AS cross_join_rows;

-- 5.3B How does PostgreSQL plan to run the three-table join from 5.1a?
--      Requirement: EXPLAIN on the three-table join.
--      Finding: a Hash Join and a Nested Loop. ratings is scanned in full and
--      hash joined to users, then each movie is looked up through the movies
--      primary key index, with Memoize caching repeated lookups.
EXPLAIN
SELECT u.user_name,
       m.title,
       r.rated_at
FROM   ratings r
JOIN   users  u ON u.user_id  = r.user_id
JOIN   movies m ON m.movie_id = r.movie_id
ORDER BY r.rated_at;
