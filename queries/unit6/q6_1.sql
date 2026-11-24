-- 6.1a Is a rating unusual for its own title? Every rating, shown next to its
--      title's average score.
--      Requirement: AVG(...) OVER (PARTITION BY ...) that keeps every row.
--      The average leaves out withdrawn ratings, since they all carry the 0.5
--      placeholder score found in Unit 4.
--      Finding: 200 rows, one per rating. Every withdrawn rating sits at least
--      2.26 below its title's average. Among the rest, rating 123 (0.8 on
--      Title_08) is the furthest below, 2.61 under its title's 3.41 average.
SELECT r.rating_id,
       r.movie_id,
       r.rated_at,
       r.rating_status,
       r.score,
       ROUND(AVG(r.score) FILTER (WHERE r.rating_status <> 'withdrawn')
                 OVER (PARTITION BY r.movie_id), 2)                          AS title_avg_score,
       ROUND(r.score - AVG(r.score) FILTER (WHERE r.rating_status <> 'withdrawn')
                           OVER (PARTITION BY r.movie_id), 2)                AS diff_from_title_avg
FROM   ratings r
ORDER BY r.movie_id, r.rated_at;

-- 6.1a (GROUP BY version) The same title averages with GROUP BY.
--      Requirement: compare row counts with the window version.
--      Finding: 13 rows, one per rated title. The individual ratings are gone,
--      so there is no way to tell which ratings are far from their title's average.
SELECT movie_id,
       COUNT(*)                                                           AS ratings,
       ROUND(AVG(score) FILTER (WHERE rating_status <> 'withdrawn'), 2)   AS title_avg_score
FROM   ratings
GROUP BY movie_id
ORDER BY movie_id;

-- 6.1b How would a "most rated titles" leaderboard order the titles, and what
--      happens when two titles have the same number of ratings?
--      Requirement: ROW_NUMBER, RANK, and DENSE_RANK side by side, showing a tie.
--      LEFT JOIN so the two titles with no ratings still appear.
--      Finding: 15 titles. Title IDs 5 and 7 tie at 18 ratings, 2 and 11 at 16,
--      1 and 13 at 11, and 14 and 15 at 0. ROW_NUMBER splits each tie by
--      movie_id, RANK gives both the same place and skips the next, and
--      DENSE_RANK gives both the same place without skipping.
WITH title_counts AS (
    SELECT m.movie_id,
           m.title,
           COUNT(r.rating_id) AS ratings
    FROM   movies m
    LEFT JOIN ratings r ON r.movie_id = m.movie_id
    GROUP BY m.movie_id, m.title
)
SELECT movie_id,
       title,
       ratings,
       ROW_NUMBER() OVER (ORDER BY ratings DESC, movie_id) AS row_number,
       RANK()       OVER (ORDER BY ratings DESC)           AS rank,
       DENSE_RANK() OVER (ORDER BY ratings DESC)           AS dense_rank
FROM   title_counts
ORDER BY ratings DESC, movie_id;

-- 6.1c Which titles fall in the top, upper middle, lower middle, and bottom
--      quarter by number of ratings?
--      Requirement: NTILE(4) by number of events.
--      Finding: 15 titles split 4, 4, 4, 3. Title IDs 5 and 7 both have 18
--      ratings, but 5 lands in band 1 and 7 in band 2, because NTILE splits by
--      row count and only the movie_id tie-break decides which one is first.
WITH title_counts AS (
    SELECT m.movie_id,
           m.title,
           COUNT(r.rating_id) AS ratings
    FROM   movies m
    LEFT JOIN ratings r ON r.movie_id = m.movie_id
    GROUP BY m.movie_id, m.title
)
SELECT movie_id,
       title,
       ratings,
       NTILE(4) OVER (ORDER BY ratings DESC, movie_id) AS band
FROM   title_counts
ORDER BY ratings DESC, movie_id;
