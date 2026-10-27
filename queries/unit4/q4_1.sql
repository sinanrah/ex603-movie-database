-- 4.1a Platform-wide summary of the rating score: how many ratings, the total,
--      average, lowest and highest score, and how many distinct users rated.
--      Asked by: the leadership team, to decide whether the platform numbers
--      can be trusted before they are used for payout decisions.
--      Requirement: COUNT, SUM, AVG, MIN, MAX, and COUNT(DISTINCT) over the event table.
--      Finding: 200 ratings from 30 users, average 2.85, scores from 0.5 to 5.0.
SELECT COUNT(*)                AS total_ratings,
       SUM(score)              AS total_score,
       ROUND(AVG(score), 2)    AS avg_score,
       MIN(score)              AS min_score,
       MAX(score)              AS max_score,
       COUNT(DISTINCT user_id) AS distinct_users
FROM   ratings;

-- 4.1a (check) Where does the minimum score come from?
--      Asked by: the Trust and Data team, to decide whether withdrawn ratings
--      should be left out of score averages.
--      Requirement: follow up on a suspicious minimum.
--      Finding: all 34 withdrawn ratings have exactly 0.5, a placeholder score.
--      Published ratings alone average 3.32.
SELECT rating_status,
       COUNT(*)             AS ratings,
       MIN(score)           AS min_score,
       MAX(score)           AS max_score,
       ROUND(AVG(score), 2) AS avg_score
FROM   ratings
GROUP BY rating_status
ORDER BY rating_status;

-- 4.1b How many ratings does each title have, and what is its average score?
--      Most-rated title first.
--      Asked by: the trust and safety lead, to decide which titles have enough
--      activity to review first.
--      Requirement: GROUP BY with COUNT and AVG, sorted by event count.
--      Finding: 13 of the 15 titles have ratings, from 21 (movie_id 6) down to 6 (movie_id 4).
--      movie_id 14 and 15 have none, so they do not appear.
SELECT movie_id,
       COUNT(*)             AS rating_count,
       ROUND(AVG(score), 2) AS avg_score
FROM   ratings
GROUP BY movie_id
ORDER BY rating_count DESC, movie_id;

-- 4.1c Which titles have enough ratings for their spam rate to mean anything?
--      Threshold: at least 10 ratings, so one spam rating moves a title's rate
--      by no more than 10 percentage points.
--      Asked by: the trust and safety lead, to decide which titles' spam rates
--      are reliable enough to act on.
--      Requirement: HAVING on an aggregate.
--      Finding: 12 titles qualify. Only movie_id 4 (6 ratings) is left out.
--      movie_id 2 (18.8%) and movie_id 3 (15.4%) stand out.
SELECT movie_id,
       COUNT(*)                                                    AS rating_count,
       COUNT(CASE WHEN withdrawn_reason = 'Spam detected' THEN 1 END) AS spam_count,
       ROUND(100.0 * COUNT(CASE WHEN withdrawn_reason = 'Spam detected' THEN 1 END)
             / COUNT(*), 1)                                         AS spam_rate_pct
FROM   ratings
GROUP BY movie_id
HAVING COUNT(*) >= 10
ORDER BY rating_count DESC, movie_id;

-- 4.1d How do ratings break down by region and status? Region is the country
--      the rating was made from. One row per region and status combination.
--      Asked by: the regional director, to decide whether any region needs
--      its own review of withdrawn ratings.
--      Requirement: GROUP BY two dimensions, including region.
--      Finding: India has the most withdrawn ratings (11 of 40). Withdrawn
--      ratings average 0.50 in every region.
SELECT device_country       AS region,
       rating_status,
       COUNT(*)             AS rating_count,
       ROUND(AVG(score), 2) AS avg_score
FROM   ratings
GROUP BY device_country, rating_status
ORDER BY device_country, rating_status;
