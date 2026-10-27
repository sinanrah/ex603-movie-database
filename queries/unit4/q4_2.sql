-- 4.2A For each title, how many ratings it has and how many were withdrawn
--      as spam, in one pass over the ratings table.
--      Asked by: the trust and safety lead, to decide which titles to open a
--      spam investigation on.
--      Requirement: CASE inside an aggregate, both totals in one result set.
--      Finding: movie_id 2 (3 of 16), 4 (1 of 6), and 3 (2 of 13) have the highest rates.
SELECT movie_id,
       COUNT(*)                                                         AS total_ratings,
       SUM(CASE WHEN withdrawn_reason = 'Spam detected' THEN 1 ELSE 0 END) AS spam_ratings,
       ROUND(100.0 * SUM(CASE WHEN withdrawn_reason = 'Spam detected' THEN 1 ELSE 0 END)
             / COUNT(*), 1)                                              AS spam_rate_pct
FROM   ratings
GROUP BY movie_id
ORDER BY spam_rate_pct DESC, total_ratings DESC;

-- 4.2B Spam totals for each region, plus a platform-wide grand total,
--      without the detail rows.
--      Asked by: the regional director, to decide whether spam needs a
--      regional response or a platform-wide one.
--      Requirement: GROUP BY ROLLUP.
--      The five rows with a region name are the regional subtotals.
--      The row labeled "All regions" is the grand total.
--      Finding: 12 of 200 ratings platform-wide (6.0%), from 2.3% in Vietnam
--      to 10.0% in India.
SELECT CASE WHEN GROUPING(device_country) = 1 THEN 'All regions'
            ELSE device_country END                               AS region,
       COUNT(*)                                                    AS total_ratings,
       SUM(CASE WHEN withdrawn_reason = 'Spam detected' THEN 1 ELSE 0 END) AS spam_ratings,
       ROUND(100.0 * SUM(CASE WHEN withdrawn_reason = 'Spam detected' THEN 1 ELSE 0 END)
             / COUNT(*), 1)                                         AS spam_rate_pct
FROM   ratings
GROUP BY ROLLUP (device_country)
ORDER BY GROUPING(device_country), device_country;

-- 4.2C What is the spam rate across high-volume titles, meaning titles with
--      more ratings than the average rated title?
--      Asked by: the trust and safety lead, to set a normal rate so a title
--      is only flagged when it is well above it.
--      Requirement: a WITH clause producing an intermediate aggregate,
--      then a second aggregation and filter on that result.
--      Finding: 8 titles have more than the average 15.4 ratings. Together they
--      have 7 spam ratings out of 145, a baseline of 4.8%.
WITH title_stats AS (
    SELECT movie_id,
           COUNT(*)                                                         AS total_ratings,
           SUM(CASE WHEN withdrawn_reason = 'Spam detected' THEN 1 ELSE 0 END) AS spam_ratings
    FROM   ratings
    GROUP BY movie_id
)
SELECT COUNT(*)                                            AS high_volume_titles,
       SUM(total_ratings)                                  AS total_ratings,
       SUM(spam_ratings)                                   AS spam_ratings,
       ROUND(100.0 * SUM(spam_ratings) / SUM(total_ratings), 1) AS baseline_spam_rate_pct
FROM   title_stats
WHERE  total_ratings > (SELECT AVG(total_ratings) FROM title_stats);
