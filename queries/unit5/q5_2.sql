-- 5.2A-1 Every title with its number of ratings, including titles with none.
--        Requirement: LEFT JOIN that returns all producers.
--        Finding: 15 rows. Title IDs 14 and 15 show 0 ratings.
SELECT m.movie_id,
       m.title,
       COUNT(r.rating_id) AS rating_count
FROM   movies m
LEFT JOIN ratings r ON r.movie_id = m.movie_id
GROUP BY m.movie_id, m.title
ORDER BY m.movie_id;

-- 5.2A-2 The same question with an INNER JOIN.
--        Requirement: equivalent query using INNER JOIN.
--        Finding: 13 rows. Title IDs 14 and 15 are missing.
SELECT m.movie_id,
       m.title,
       COUNT(r.rating_id) AS rating_count
FROM   movies m
INNER JOIN ratings r ON r.movie_id = m.movie_id
GROUP BY m.movie_id, m.title
ORDER BY m.movie_id;

-- 5.2A-3 How many titles does the INNER JOIN leave out?
--        Requirement: count of producers excluded by the inner join,
--        counting unique title IDs.
--        Finding: 15 with the LEFT JOIN, 13 with the INNER JOIN, so 2 are excluded.
WITH title_counts AS (
    SELECT (SELECT COUNT(DISTINCT m.movie_id)
            FROM   movies m
            LEFT JOIN ratings r ON r.movie_id = m.movie_id)  AS left_join_titles,
           (SELECT COUNT(DISTINCT m.movie_id)
            FROM   movies m
            INNER JOIN ratings r ON r.movie_id = m.movie_id) AS inner_join_titles
)
SELECT left_join_titles,
       inner_join_titles,
       left_join_titles - inner_join_titles AS excluded_titles
FROM   title_counts;

-- 5.2B-1 The LEFT JOIN from 5.2A-1 written as a RIGHT JOIN.
--        Requirement: RIGHT JOIN returning the same records.
--        Finding: 15 rows, the same as 5.2A-1.
SELECT m.movie_id,
       m.title,
       COUNT(r.rating_id) AS rating_count
FROM   ratings r
RIGHT JOIN movies m ON m.movie_id = r.movie_id
GROUP BY m.movie_id, m.title
ORDER BY m.movie_id;

-- 5.2B-2 Do the LEFT JOIN and RIGHT JOIN return the same rows?
--        Requirement: verify the results match instead of assuming it.
--        Finding: both EXCEPT checks return 0 rows, and both queries return 15 rows.
WITH left_version AS (
    SELECT m.movie_id, m.title, COUNT(r.rating_id) AS rating_count
    FROM   movies m
    LEFT JOIN ratings r ON r.movie_id = m.movie_id
    GROUP BY m.movie_id, m.title
),
right_version AS (
    SELECT m.movie_id, m.title, COUNT(r.rating_id) AS rating_count
    FROM   ratings r
    RIGHT JOIN movies m ON m.movie_id = r.movie_id
    GROUP BY m.movie_id, m.title
)
SELECT 'left minus right' AS comparison,
       (SELECT COUNT(*) FROM (SELECT * FROM left_version EXCEPT SELECT * FROM right_version) x) AS row_count
UNION ALL
SELECT 'right minus left',
       (SELECT COUNT(*) FROM (SELECT * FROM right_version EXCEPT SELECT * FROM left_version) x)
UNION ALL
SELECT 'rows in left join',  (SELECT COUNT(*) FROM left_version)
UNION ALL
SELECT 'rows in right join', (SELECT COUNT(*) FROM right_version);

-- 5.2B-3 Every title and every rating, matched or not.
--        Requirement: FULL OUTER JOIN with matched and unmatched records from both tables.
--        Finding: 202 rows. The first two are title IDs 14 and 15 with no rating.
--        No rating is missing a title.
SELECT m.movie_id,
       m.title,
       r.rating_id
FROM   movies m
FULL OUTER JOIN ratings r ON r.movie_id = m.movie_id
ORDER BY r.rating_id NULLS FIRST, m.movie_id;

-- 5.2B-4 How many rows of the FULL OUTER JOIN are matched, and how many are
--        unmatched on each side?
--        Requirement: show what the full outer join reveals.
--        Finding: 200 matched rows and 2 titles with no ratings. There are no
--        ratings without a title, so no row shows up for that case.
SELECT CASE
           WHEN r.rating_id IS NULL THEN 'title with no ratings'
           WHEN m.movie_id  IS NULL THEN 'rating with no title'
           ELSE 'matched'
       END      AS match_status,
       COUNT(*) AS row_count
FROM   movies m
FULL OUTER JOIN ratings r ON r.movie_id = m.movie_id
GROUP BY 1
ORDER BY 1;

-- 5.2C-1 Which titles have never been rated?
--        Requirement: NOT EXISTS.
--        Finding: title IDs 14 and 15.
SELECT m.movie_id,
       m.title
FROM   movies m
WHERE  NOT EXISTS (
    SELECT 1
    FROM   ratings r
    WHERE  r.movie_id = m.movie_id
)
ORDER BY m.movie_id;

-- 5.2C-2 The same question.
--        Requirement: EXCEPT.
--        Finding: title IDs 14 and 15, the same as 5.2C-1.
SELECT movie_id FROM movies
EXCEPT
SELECT movie_id FROM ratings
ORDER BY movie_id;
