-- 5.1a Who made each rating, which title was it for, and when?
--      Requirement: a join across three tables (actor, event, producer).
--      Finding: 200 rows, one per rating, from January to December 2023.
SELECT u.user_name,
       m.title,
       r.rated_at
FROM   ratings r
JOIN   users  u ON u.user_id  = r.user_id
JOIN   movies m ON m.movie_id = r.movie_id
ORDER BY r.rated_at;

-- 5.1b Which genres are title IDs 2 and 3 (the high spam titles from Unit 4) tagged with?
--      Requirement: producer to catalog through the junction table.
--      Finding: both are tagged Comedy. Title_02 is also Drama and Thriller,
--      and Title_03 is also Sci-Fi.
SELECT m.movie_id,
       m.title,
       g.genre_name
FROM   movies m
JOIN   movie_genres mg ON mg.movie_id = m.movie_id
JOIN   genres g        ON g.genre_id  = mg.genre_id
WHERE  m.movie_id IN (2, 3)
ORDER BY m.movie_id, g.genre_name;

-- 5.1c Which titles are tagged Comedy, the genre both flagged titles share?
--      Requirement: return the producers linked to one catalog tag through the junction table.
--      Finding: 5 titles (IDs 2, 3, 5, 10, 11). Title IDs 5 and 10 have no spam
--      ratings, so the genre alone does not explain the spam.
SELECT m.movie_id,
       m.title,
       g.genre_name
FROM   movies m
JOIN   movie_genres mg ON mg.movie_id = m.movie_id
JOIN   genres g        ON g.genre_id  = mg.genre_id
WHERE  g.genre_name = 'Comedy'
ORDER BY m.movie_id;

-- 5.1d How do the flagged titles compare with other titles released in the same year?
--      Requirement: self join on the producer table.
--      Finding: title IDs 2 and 3 are both 2023 releases, along with IDs 1, 4, and 5.
--      Title IDs 1 and 4 also have a spam rating, but title ID 5 has more ratings
--      than either flagged title and no spam, so activity level does not explain it.
WITH title_stats AS (
    SELECT movie_id,
           COUNT(*)                                                            AS total_ratings,
           SUM(CASE WHEN withdrawn_reason = 'Spam detected' THEN 1 ELSE 0 END) AS spam_ratings
    FROM   ratings
    GROUP BY movie_id
)
SELECT a.movie_id       AS flagged_id,
       b.movie_id       AS other_id,
       a.release_year,
       sa.total_ratings AS flagged_ratings,
       sa.spam_ratings  AS flagged_spam,
       sb.total_ratings AS other_ratings,
       sb.spam_ratings  AS other_spam
FROM   movies a
JOIN   movies b       ON b.release_year = a.release_year
                     AND b.movie_id    <> a.movie_id
JOIN   title_stats sa ON sa.movie_id = a.movie_id
JOIN   title_stats sb ON sb.movie_id = b.movie_id
WHERE  a.movie_id IN (2, 3)
ORDER BY a.movie_id, b.movie_id;
