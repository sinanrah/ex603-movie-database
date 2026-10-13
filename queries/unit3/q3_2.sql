-- 3.2a Every rating except the ones users withdrew themselves.
--      Requirement: inequality predicate on a nullable column.
--      Finding: returns 27, not the expected 193.
SELECT COUNT(*) AS kept_by_broken_filter
FROM   ratings
WHERE  withdrawn_reason <> 'User request';

-- 3.2b The rows the first query kept and excluded, next to the table total.
--      Requirement: count what the first query omitted.
--      Finding: 27 + 7 = 34, not 200. The 166 NULL rows were silently dropped.
SELECT
    (SELECT COUNT(*) FROM ratings WHERE withdrawn_reason <> 'User request') AS kept,
    (SELECT COUNT(*) FROM ratings WHERE withdrawn_reason =  'User request') AS excluded,
    (SELECT COUNT(*) FROM ratings)                                           AS table_total,
    (SELECT COUNT(*) FROM ratings WHERE withdrawn_reason IS NULL)            AS omitted;

-- 3.2c The same filter, repaired.
--      Requirement: repair with IS NULL.
--      Finding: returns 193.
SELECT COUNT(*) AS kept_by_repaired_filter
FROM   ratings
WHERE  withdrawn_reason <> 'User request'
   OR  withdrawn_reason IS NULL;

-- 3.2d Ratings with a weighted score above 5, using the alias in WHERE.
--      Requirement: alias defined in SELECT, referenced in WHERE.
--      Finding: ERROR:  column "weighted_score" does not exist
SELECT rating_id, score * weight AS weighted_score
FROM   ratings
WHERE  weighted_score > 5;

-- 3.2e Rewrite 1: repeat the expression in WHERE.
--      Requirement: correct rewrite.
--      Finding: 46 rows.
SELECT rating_id, score * weight AS weighted_score
FROM   ratings
WHERE  score * weight > 5
ORDER BY weighted_score DESC, rating_id;

-- 3.2f Rewrite 2: compute the alias in a CTE.
--      Requirement: correct rewrite with a CTE.
--      Finding: the same 46 rows.
WITH weighted AS (
    SELECT rating_id, score * weight AS weighted_score
    FROM   ratings
)
SELECT rating_id, weighted_score
FROM   weighted
WHERE  weighted_score > 5
ORDER BY weighted_score DESC, rating_id;
