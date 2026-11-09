# Unit 5: Joins

## Task 5.1

The three-table join could be used for a rating history page for the trust and safety team. Each row would show the user's name, the title they rated, and when they rated it, so a reviewer can see who rated what without looking up IDs in three tables. It would also make patterns like one user rating several titles in a short time easy to spot.

The junction table matters because a title can have several genres and a genre can belong to many titles. movie_genres stores each title and genre pairing as its own row, so finding which titles are tagged Comedy is a simple join. Without it, genres would have to be stored as a list in a column on movies (like "Comedy, Drama, Thriller"), and finding every Comedy title would mean searching text. Nothing would stop a misspelled or nonexistent genre from being stored either.

From the queries, title IDs 2 and 3 share the Comedy tag, but title IDs 5 and 10 are also Comedy and have no spam ratings. Both flagged titles are 2023 releases, and title ID 5 is too, with more ratings than either and no spam. Neither the genre nor the activity level explains their spam on its own.

## Task 5.2

Part A: The LEFT JOIN returns 15 titles and the INNER JOIN returns 13, so the INNER JOIN excludes 2 titles, title IDs 14 and 15. They are missing because neither has any ratings, and an INNER JOIN only returns a title when it has at least one matching row in ratings.

Part B: The RIGHT JOIN returns the same 15 rows as the LEFT JOIN, and both EXCEPT checks return 0 rows. A FULL OUTER JOIN shows unmatched rows from both sides at once. A LEFT JOIN from movies would only show titles with no ratings, and a LEFT JOIN from ratings would only show ratings with no title. Here the full outer join shows the 2 titles with no ratings and confirms there are no ratings without a title, since the foreign key on ratings.movie_id prevents that.

Part C: NOT EXISTS checks each title for a matching rating and keeps the ones with none, so it can return any column from movies. EXCEPT takes all title IDs and removes the ones that appear in ratings, so both sides have to return the same columns. Both return title IDs 14 and 15.

The producers excluded by the inner join are title IDs 14 and 15.

A producer with no events means no user has ever rated the title. The data shows that both titles are marked available and were added to the catalogue in early 2022, before the first rating in January 2023. Neither has a genre tag, so a user who browses by genre would not find them. That could explain it, but title ID 13 also has no genre tag and still has 11 ratings. Other possible explanations are that the titles are hard to find in search, are not promoted, or are not interesting to users. The data does not show which one is true.

A report built on an inner join only lists titles that have ratings. Leadership would see 13 titles and could assume that is the whole catalogue. The 2 titles with no activity disappear without any error, the same kind of silent drop as the Unit 3 dashboard filter.

Leadership would want to find titles that were never active because they are in the catalogue but have never been used, and they never show up in an activity report, so nobody would notice them. They may point to a listing problem, or they may be titles that are not worth keeping.

Based on this, leadership could have the catalogue team check whether title IDs 14 and 15 show up in search and genre browsing, add genre tags, and then decide whether to promote or remove them if they still get no ratings.

## Task 5.3

Part A: genres has 5 rows and movies has 15, and the CROSS JOIN returns 75, which is 5 x 15.

A Cartesian product could be useful for recommendations. Pairing every user with every title and removing the pairs that already have a rating leaves the titles each user has not rated yet. A Cartesian product usually means an error when it comes from a join that is missing its ON condition. Joining ratings to movies without one returns 3,000 rows (200 x 15) instead of 200, and every count or average built on it would be wrong.

Part B: This is the plan PostgreSQL returned for the three-table join from 5.1a.

```
Sort  (cost=35.98..36.48 rows=200 width=524)
  Sort Key: r.rated_at
  ->  Nested Loop  (cost=12.40..28.34 rows=200 width=524)
        ->  Hash Join  (cost=12.25..17.80 rows=200 width=270)
              Hash Cond: (r.user_id = u.user_id)
              ->  Seq Scan on ratings r  (cost=0.00..5.00 rows=200 width=16)
              ->  Hash  (cost=11.00..11.00 rows=100 width=262)
                    ->  Seq Scan on users u  (cost=0.00..11.00 rows=100 width=262)
        ->  Memoize  (cost=0.15..0.41 rows=1 width=262)
              Cache Key: r.movie_id
              Cache Mode: logical
              ->  Index Scan using movies_pkey on movies m  (cost=0.14..0.40 rows=1 width=262)
                    Index Cond: (movie_id = r.movie_id)
```

PostgreSQL chose two join algorithms. A Hash Join joins ratings to users on user_id, and a Nested Loop joins that result to movies. For each rating, the Nested Loop looks up the matching movie with an Index Scan on movies_pkey, and Memoize caches each movie it already looked up.

In the plan, ratings is read with a Seq Scan because there is no WHERE clause, so every rating is needed. users is read with a Seq Scan and loaded into a Hash node, and the join condition is equality (Hash Cond), which a hash join needs. For movies, the Index Cond shows each lookup uses the primary key index, and rows=1 shows each lookup is expected to return one movie. The Cache Key is r.movie_id, so ratings for the same title reuse the cached row instead of looking it up again. Since 200 ratings only point to 13 titles, most lookups come from the cache. The estimate for ratings (200 rows) matches the real count, but the estimate for users (100 rows) does not match the real 30, which suggests the statistics for users had not been updated.

The part most likely to become less efficient as the data grows is the Seq Scan on ratings and the Sort on rated_at, since ratings is the table that grows and this query reads and sorts every row each time. The Nested Loop could also get worse. With millions of ratings spread across many titles, fewer lookups would come from the cache, and doing one index lookup per rating would cost more than hashing movies once.

Understanding the join algorithms is useful because the plan shows whether a slow query is slow because of the data size, a missing index, or out-of-date statistics. Knowing what each algorithm needs makes it clear what to change, like adding an index or running ANALYZE, instead of guessing.

Another algorithm could be more appropriate if movies grew large or the ratings pointed to many different titles. Then a Hash Join on movies, like the one used for users, would likely be cheaper than one index lookup per rating. Updating the statistics with ANALYZE could also change the plan, since the planner's choice depends on its row estimates. If both sides were already sorted on the join column, for example through indexes on both, a Merge Join could be chosen.

## Reflection

PostgreSQL picks a join algorithm based on how many rows it expects from each table, whether there is an index on the join column, and how many rows it expects to match. Right now every table is small and the query reads all of ratings, so it hashes users and looks up each movie through the primary key index.

If ratings grew to millions of rows while users and movies stayed fairly small, a Hash Join would make sense for both joins, because the smaller tables would still fit in a hash table and the full scan of ratings cannot be avoided. The cost would mostly come from reading and sorting all of ratings. If users grew large enough that its hash table no longer fit in memory, the hash join would have to spill to disk and slow down.

Indexes and filters would change the plan more. If the query were limited to one title, an index on ratings.movie_id would let PostgreSQL find only that title's ratings, and a Nested Loop with index lookups would be cheaper than scanning every rating. Since the number of matching records would be small, looking each one up would beat building a hash table. If both inputs came from indexes on the join column, they would already be sorted, and a Merge Join could scan them side by side without a hash build.
