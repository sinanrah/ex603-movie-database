-- 3.1a Available movies released after 2015, newest first, first ten.
--      Requirement: SELECT, WHERE, ORDER BY, LIMIT.
--      Finding: only 7 movies qualify, all from 2016 to 2023.
SELECT movie_id, title, release_year
FROM   movies
WHERE  is_available = TRUE
  AND  release_year > 2015
ORDER BY release_year DESC, title
LIMIT 10;

-- 3.1b Which rating statuses appear in the data?
--      Requirement: DISTINCT.
--      Finding: 3 statuses, not 2. Besides published and withdrawn there is flagged.
SELECT DISTINCT rating_status
FROM   ratings
ORDER BY rating_status;

-- 3.1c Ratings with a score between 1.0 and 2.5.
--      Requirement: numeric range with BETWEEN.
--      Finding: 55 of the 200 ratings.
SELECT rating_id, movie_id, score
FROM   ratings
WHERE  score BETWEEN 1.0 AND 2.5
ORDER BY score, rating_id;

-- 3.1d Ratings made from the US or the UK.
--      Requirement: list of values with IN.
--      Finding: 78 ratings.
SELECT rating_id, user_id, device_country
FROM   ratings
WHERE  device_country IN ('US', 'UK')
ORDER BY device_country, rating_id;

-- 3.1e Movies whose title starts with "Title_1".
--      Requirement: LIKE.
--      Finding: 6 movies, Title_10 to Title_15.
SELECT movie_id, title
FROM   movies
WHERE  title LIKE 'Title_1%'
ORDER BY title;

-- 3.1f Ratings with no withdrawal reason recorded.
--      Requirement: IS NULL.
--      Finding: 166 of the 200 ratings. Only withdrawn ratings have a reason.
SELECT rating_id, rating_status, withdrawn_reason
FROM   ratings
WHERE  withdrawn_reason IS NULL
ORDER BY rating_id;

-- 3.1g Every rating's withdrawal reason, with missing ones labeled.
--      Requirement: COALESCE.
--      Finding: 166 show "No reason provided"; 12 of the rest are "Spam detected".
SELECT rating_id,
       rating_status,
       COALESCE(withdrawn_reason, 'No reason provided') AS withdrawn_reason
FROM   ratings
ORDER BY rating_id;

-- 3.1h Published ratings in plain language: weighted score for payouts,
--      watch time in hours, score category, and time of day.
--      Requirement: computed columns and CASE.
--      Finding: each rating gets a readable category and time of day.
SELECT rating_id,
       user_id,
       score,
       score * weight                 AS weighted_score,
       ROUND(watch_minutes / 60.0, 2) AS watch_hours,
       CASE
           WHEN score >= 4.0 THEN 'Loved it'
           WHEN score >= 2.5 THEN 'Mixed'
           ELSE 'Disliked'
       END                            AS score_category,
       CASE
           WHEN EXTRACT(HOUR FROM rated_at) < 6  THEN 'Overnight'
           WHEN EXTRACT(HOUR FROM rated_at) < 12 THEN 'Morning'
           WHEN EXTRACT(HOUR FROM rated_at) < 18 THEN 'Afternoon'
           ELSE 'Evening'
       END                            AS time_of_day
FROM   ratings
WHERE  rating_status = 'published'
ORDER BY rating_id
LIMIT 20;
