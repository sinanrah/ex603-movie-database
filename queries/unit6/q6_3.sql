-- 6.3A What are the three highest ratings for each title?
--      Requirement: a ranking window function partitioned by producer, a CTE
--      that keeps rank <= 3, and FIRST_VALUE.
--      Withdrawn ratings are left out, since their 0.5 is a placeholder and not
--      a real score.
--      Ties at third place: ROW_NUMBER breaks ties by the earlier rated_at, so
--      every title shows exactly three ratings. The panel this would feed has
--      three slots, and the earliest rating has been on the title the longest,
--      so the top three do not reshuffle every time a new rating ties them.
--      score_rank (RANK) is kept next to it to show where a tie was cut.
--      Finding: 39 rows, three for each of the 13 rated titles. Several titles
--      had more than three 5.0 ratings, so their third place was decided by
--      rated_at.
WITH ranked AS (
    SELECT r.movie_id,
           m.title,
           r.rating_id,
           u.user_name,
           r.rated_at,
           r.score,
           ROW_NUMBER()  OVER (PARTITION BY r.movie_id ORDER BY r.score DESC, r.rated_at) AS score_position,
           RANK()        OVER (PARTITION BY r.movie_id ORDER BY r.score DESC)             AS score_rank,
           FIRST_VALUE(r.score) OVER (PARTITION BY r.movie_id ORDER BY r.score DESC)      AS title_best_score
    FROM   ratings r
    JOIN   movies m ON m.movie_id = r.movie_id
    JOIN   users  u ON u.user_id  = r.user_id
    WHERE  r.rating_status <> 'withdrawn'
)
SELECT movie_id,
       title,
       score_position,
       score_rank,
       rating_id,
       user_name,
       rated_at,
       score,
       title_best_score
FROM   ranked
WHERE  score_position <= 3
ORDER BY movie_id, score_position;

-- 6.3B Is the spam problem getting better or worse each month?
--      Requirement: events grouped by calendar month, LAG over the monthly
--      series, a percent change that avoids dividing by zero, and a check for
--      missing months.
--      month_gap_ok is false if the previous row is not the calendar month
--      right before, which would mean LAG compared the wrong months.
--      Finding: 12 months, none missing. The spam rate jumps around between 0%
--      and 18.2%, with no spam in Feb, Apr, Oct, and Nov. pct_change_spam_rate
--      is NULL after a month with no spam instead of dividing by zero.
WITH monthly AS (
    SELECT DATE_TRUNC('month', rated_at)::date                              AS month,
           COUNT(*)                                                         AS ratings,
           COUNT(*) FILTER (WHERE withdrawn_reason = 'Spam detected')       AS spam,
           ROUND(100.0 * COUNT(*) FILTER (WHERE withdrawn_reason = 'Spam detected')
                 / COUNT(*), 1)                                             AS spam_rate
    FROM   ratings
    GROUP BY DATE_TRUNC('month', rated_at)
),
compared AS (
    SELECT month,
           ratings,
           spam,
           spam_rate,
           LAG(month)     OVER (ORDER BY month) AS prev_month,
           LAG(ratings)   OVER (ORDER BY month) AS prev_ratings,
           LAG(spam_rate) OVER (ORDER BY month) AS prev_spam_rate
    FROM   monthly
)
SELECT month,
       ratings,
       spam,
       spam_rate,
       prev_spam_rate,
       spam_rate - prev_spam_rate                                              AS spam_rate_change,
       ROUND(100.0 * (spam_rate - prev_spam_rate) / NULLIF(prev_spam_rate, 0), 1) AS pct_change_spam_rate,
       ROUND(100.0 * (ratings - prev_ratings) / NULLIF(prev_ratings, 0), 1)       AS pct_change_ratings,
       prev_month IS NULL
         OR month = (prev_month + INTERVAL '1 month')::date                    AS month_gap_ok
FROM   compared
ORDER BY month;

-- 6.3B (missing month check) Are there any calendar months between the first and
--      last rating with no ratings at all?
--      Requirement: confirm the monthly series has no holes before trusting LAG.
--      Finding: 0 rows, so every month from January to December 2023 has ratings.
SELECT gs.month::date AS missing_month
FROM   GENERATE_SERIES(
           (SELECT DATE_TRUNC('month', MIN(rated_at)) FROM ratings),
           (SELECT DATE_TRUNC('month', MAX(rated_at)) FROM ratings),
           INTERVAL '1 month') AS gs(month)
WHERE  NOT EXISTS (
    SELECT 1
    FROM   ratings r
    WHERE  DATE_TRUNC('month', r.rated_at) = gs.month
);
