# Unit 2 — From Diagram to Database

## What changed from Unit 1

Writing the DDL made me add a few things the Unit 1 design didn't have. The ERD has been updated to match.

- `movies.remake_of_id` — a recursive foreign key. In Unit 1 I said a remake can share its title with the original, but nothing actually linked the two. Now a remake points to the movie it remakes.
- `movies.content_type` — `'film'` or `'series'`, since the catalogue holds both films and TV titles.
- `movies.release_decade` — a derived attribute (see below).
- `movie_languages` — a new table for a multivalued attribute. A movie can be available in more than one language, and one column can only hold one value.
- `episodes` — a new weak entity. An episode only makes sense as part of its series, so it's identified by `(movie_id, season_number, episode_number)` instead of its own id.

I kept `ratings.score` as `INTEGER` instead of `NUMERIC(3,2)`, since my scale is whole numbers 1 to 10 and `NUMERIC(3,2)` can't store 10.

## Derived attribute

`release_decade` is stored with `GENERATED ALWAYS AS ((release_year / 10) * 10) STORED`. I chose to store it because browsing by decade is a filter users would run constantly. Since the database generates it itself, it can never go out of sync with `release_year`, so storing it doesn't bring the usual synchronization problem. A movie's average score is different. It changes every time someone rates the movie, so I compute it at query time with `AVG(score)` and don't store it.

## Constraints table

| Foreign key | ON DELETE | Reason |
|---|---|---|
| `ratings.user_id` → `users` | CASCADE | A rating is one user's opinion, so it goes when the user's account goes. |
| `ratings.movie_id` → `movies` | RESTRICT | Deleting a movie would wipe out ratings written by many other users. |
| `movie_genres.movie_id` → `movies` | CASCADE | A genre tag on a movie that no longer exists points at nothing. |
| `movie_genres.genre_id` → `genres` | RESTRICT | A genre still tagged on movies is still in use. |
| `movies.remake_of_id` → `movies` | SET NULL | A remake is still its own movie after the original is deleted. |
| `movie_languages.movie_id` → `movies` | CASCADE | Languages are an attribute of the movie and mean nothing without it. |
| `episodes.movie_id` → `movies` | CASCADE | An episode is a weak entity and can't exist without its series. |

### ON DELETE choices

**Deleting a user (CASCADE on ratings).** This happens when someone closes their account. The only rows affected are that person's own ratings. With RESTRICT, a user who had rated even one movie could never delete their account, and they'd be stuck on the platform because of their own data. SET NULL isn't possible here, since `user_id` is part of the primary key.

**Deleting a movie (RESTRICT on ratings).** This would happen if the platform removed a title. The people affected are every user who rated it, who have nothing to do with the deletion. With CASCADE, one admin action would silently delete all of their ratings, and there's no way to get them back. That's why `movies` has `is_available`: the title can be hidden from the catalogue while its ratings stay.

**Deleting a movie (CASCADE on movie_genres, movie_languages, episodes).** RESTRICT on ratings means this can only happen to a movie nobody has rated, like one added by mistake. When that happens, its genre tags, languages, and episodes only describe that movie. With RESTRICT on these as well, the admin would have to delete them by hand one table at a time before removing the movie, and forgetting one would block the delete. For `episodes` specifically, CASCADE is what a weak entity needs.

**Deleting a genre (RESTRICT on movie_genres).** This would happen if the platform cleaned up its genre list. The affected movies are every movie tagged with it. With CASCADE, deleting "Horror" would quietly untag every horror movie, and genre filtering would stop finding them. RESTRICT forces the movies to be re-tagged first.

**Deleting an original movie (SET NULL on remake_of_id).** This only happens if the original has no ratings, because of the RESTRICT above. The remake still has its own title, year, and ratings, so it should keep existing and just lose the link. With CASCADE, deleting the original would also delete every remake of it, along with its ratings if RESTRICT didn't stop it. With RESTRICT, an original could never be deleted as long as any remake existed.

## CHECK constraints

| Constraint | Invalid state it blocks | How it could happen otherwise |
|---|---|---|
| `chk_ratings_score` | A score outside 1–10 | A bug in the app or a direct API call sends 0, 11, or a negative number, which would skew the averages. |
| `chk_movies_release_year` | A year before 1888 or after 2035 | A typo like `199` or `20015` when adding a movie. |
| `chk_movies_runtime` | A runtime of zero or less | A placeholder like `0` entered instead of leaving it NULL when the runtime isn't known yet. |
| `chk_movies_content_type` | A type other than `'film'` or `'series'` | Inconsistent spellings like `'Series'`, `'tv'`, or `'movie'`, which would make filtering by type miss rows. |
| `chk_movies_not_own_remake` | A movie listed as a remake of itself | Picking the wrong row when setting `remake_of_id`, which would create a loop. I used `IS DISTINCT FROM` so a NULL (not a remake) still passes. |
| `chk_episodes_season` / `chk_episodes_number` | Season or episode number of 0 or less | Starting the count at 0, or a typo. Numbering starts at 1. |
| `chk_episodes_runtime` | An episode runtime of zero or less | Same as the movie runtime check. |

The alternative for all of these would be checking in the application. I put them in the schema because each rule is about the value in a single row, so the database can check it directly. That way it applies no matter which part of the app, or which script, does the insert.
