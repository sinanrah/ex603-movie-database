-- 3.3a Which users had a rating withdrawn as spam?
--      Requirement: subquery with IN.
SELECT user_id, user_name
FROM   users
WHERE  user_id IN (
    SELECT user_id
    FROM   ratings
    WHERE  withdrawn_reason = 'Spam detected'
)
ORDER BY user_id;

-- 3.3b The same question.
--      Requirement: CTE with WITH.
WITH spam_ratings AS (
    SELECT user_id
    FROM   ratings
    WHERE  withdrawn_reason = 'Spam detected'
)
SELECT DISTINCT u.user_id, u.user_name
FROM   users u
JOIN   spam_ratings s ON s.user_id = u.user_id
ORDER BY u.user_id;

-- 3.3c The same question.
--      Requirement: a third form, EXISTS.
SELECT u.user_id, u.user_name
FROM   users u
WHERE  EXISTS (
    SELECT 1
    FROM   ratings r
    WHERE  r.user_id = u.user_id
      AND  r.withdrawn_reason = 'Spam detected'
)
ORDER BY u.user_id;

-- 3.3d Do the three forms return the same rows?
--      Requirement: show the rows match, not just the counts.
--      Finding: every EXCEPT returns 0 rows, and each form returns 10 users.
WITH f1 AS (
    SELECT user_id, user_name FROM users
    WHERE  user_id IN (SELECT user_id FROM ratings
                       WHERE withdrawn_reason = 'Spam detected')
),
f2 AS (
    SELECT DISTINCT u.user_id, u.user_name
    FROM   users u
    JOIN  (SELECT user_id FROM ratings
           WHERE withdrawn_reason = 'Spam detected') s ON s.user_id = u.user_id
),
f3 AS (
    SELECT u.user_id, u.user_name FROM users u
    WHERE  EXISTS (SELECT 1 FROM ratings r
                   WHERE r.user_id = u.user_id
                     AND r.withdrawn_reason = 'Spam detected')
)
SELECT 'form 1 minus form 2' AS comparison, (SELECT COUNT(*) FROM (SELECT * FROM f1 EXCEPT SELECT * FROM f2) x) AS rows_different
UNION ALL SELECT 'form 2 minus form 1', (SELECT COUNT(*) FROM (SELECT * FROM f2 EXCEPT SELECT * FROM f1) x)
UNION ALL SELECT 'form 1 minus form 3', (SELECT COUNT(*) FROM (SELECT * FROM f1 EXCEPT SELECT * FROM f3) x)
UNION ALL SELECT 'form 3 minus form 1', (SELECT COUNT(*) FROM (SELECT * FROM f3 EXCEPT SELECT * FROM f1) x)
UNION ALL SELECT 'rows in each form',   (SELECT COUNT(*) FROM f1);

-- Not equivalent when there are duplicates: without DISTINCT in 3.3b, users
-- with two spam ratings (User_01 and User_21) appear twice, giving 12 rows.
