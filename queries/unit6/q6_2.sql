-- 6.2A Are a title's scores going up or down over time? Each rating with the
--      score of the title's previous and next rating, and the change from the
--      previous one.
--      Requirement: LAG and LEAD partitioned by producer and ordered by time,
--      a delta column, and the final output filtered to one producer.
--      Title_02 is used because it had the most spam in Units 4 and 5.
--      Finding: 16 ratings. Two of the three largest drops land on withdrawn
--      ratings with the 0.5 placeholder (-2.9 on Dec 17, spam, and -2.0 on
--      Jan 27). The third (-2.5 on Jun 3) is a real published score right
--      after a 5.0. Published scores move between 2.2 and 5.0 with no steady
--      trend up or down.
WITH title_history AS (
    SELECT movie_id,
           rating_id,
           rated_at,
           rating_status,
           withdrawn_reason,
           score,
           LAG(score)  OVER (PARTITION BY movie_id ORDER BY rated_at) AS prev_score,
           LEAD(score) OVER (PARTITION BY movie_id ORDER BY rated_at) AS next_score
    FROM   ratings
)
SELECT movie_id,
       rating_id,
       rated_at,
       rating_status,
       withdrawn_reason,
       prev_score,
       score,
       next_score,
       score - prev_score AS delta
FROM   title_history
WHERE  movie_id = 2
ORDER BY rated_at;

-- 6.2B How is rating activity on the platform going over the year, in total and
--      on a recent average?
--      Requirement: running total with ROWS BETWEEN UNBOUNDED PRECEDING AND
--      CURRENT ROW, moving average with ROWS BETWEEN n PRECEDING AND CURRENT
--      ROW, and a target to compare against.
--      Target: 50 ratings per quarter. quarter_total restarts each quarter and
--      pct_of_target shows how close it gets.
--      Finding: 155 days with ratings, 200 ratings in total. The quarters end at
--      53, 48, 51, and 48 ratings, so Q1 and Q3 pass the target and Q2 and Q4
--      fall 2 short (96%).
WITH daily AS (
    SELECT rated_at::date AS rating_day,
           COUNT(*)       AS ratings
    FROM   ratings
    GROUP BY rated_at::date
)
SELECT rating_day,
       ratings,
       SUM(ratings) OVER (ORDER BY rating_day
                          ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)       AS running_total,
       SUM(ratings) OVER (PARTITION BY DATE_TRUNC('quarter', rating_day)
                          ORDER BY rating_day
                          ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)       AS quarter_total,
       ROUND(100.0 * SUM(ratings) OVER (PARTITION BY DATE_TRUNC('quarter', rating_day)
                                        ORDER BY rating_day
                                        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
             / 50, 1)                                                              AS pct_of_target,
       ROUND(AVG(ratings) OVER (ORDER BY rating_day
                                ROWS BETWEEN 6 PRECEDING AND CURRENT ROW), 2)    AS moving_avg_7
FROM   daily
ORDER BY rating_day;

-- 6.2C Which titles stopped getting ratings for a long stretch and then started
--      again?
--      Requirement: LAG comparing adjacent rows, computed in a CTE, with the
--      WHERE in the outer query keeping only the gaps.
--      A gap here is 90 days or more between two ratings of the same title.
--      Finding: 3 gaps. Title_09 has the longest, 113 days from Jan 5 to
--      Apr 28. Title_12 (107 days) and Title_05 (93 days) follow.
WITH rating_gaps AS (
    SELECT movie_id,
           LAG(rated_at) OVER (PARTITION BY movie_id ORDER BY rated_at) AS prev_rated_at,
           rated_at,
           rated_at::date
             - (LAG(rated_at) OVER (PARTITION BY movie_id ORDER BY rated_at))::date AS gap_days
    FROM   ratings
)
SELECT movie_id,
       prev_rated_at,
       rated_at,
       gap_days
FROM   rating_gaps
WHERE  gap_days >= 90
ORDER BY gap_days DESC;

-- 6.2C (check) Did Title_09 stop getting ratings, or did the platform stop
--      recording them?
--      Requirement: check whether other titles were still being rated during
--      the gap, and how long Title_09 usually goes between ratings.
--      Finding: 61 ratings for 11 other titles were recorded during Title_09's
--      113-day gap, and Title_09's median gap is 17 days.
WITH title_09_gaps AS (
    SELECT rated_at::date
             - (LAG(rated_at) OVER (ORDER BY rated_at))::date AS gap_days
    FROM   ratings
    WHERE  movie_id = 9
)
SELECT (SELECT COUNT(*)
        FROM   ratings
        WHERE  movie_id <> 9
          AND  rated_at > '2023-01-05 14:18:00'
          AND  rated_at < '2023-04-28 04:16:00')                    AS other_ratings_during_gap,
       (SELECT COUNT(DISTINCT movie_id)
        FROM   ratings
        WHERE  movie_id <> 9
          AND  rated_at > '2023-01-05 14:18:00'
          AND  rated_at < '2023-04-28 04:16:00')                    AS other_titles_during_gap,
       (SELECT PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY gap_days)
        FROM   title_09_gaps)                                       AS title_09_median_gap_days;
