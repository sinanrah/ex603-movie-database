# Integrity Constraints

## Primary keys

- `users(user_id)`
- `movies(movie_id)`
- `ratings(user_id, movie_id)` - composite, so the same user cannot rate the
  same film twice
- `genres(genre_id)`
- `movie_genres(movie_id, genre_id)` - composite, so the same genre cannot be
  attached twice to one film

## UNIQUE

- `users.email` - the account identifier, so two accounts cannot share one.
- `genres.name` - prevents the same category existing as two rows, which would
  split films across them and make genre queries incomplete.

## NOT NULL

Every attribute is required except `movies.runtime_min`. Runtime is the only unknown in this schema because a film can be added to the catalogue before its
runtime is confirmed, and NULL is the correct way to record that we do not know this
yet. Everything else is required, because a rating with no score is meaningless

## CHECK

- `ratings.score BETWEEN 1 AND 10` - the rating scale.
- `movies.release_year BETWEEN 1888 AND 2035` - 1888 is the year of the earliest
  surviving film, so nothing can be older. The upper bound is loose
  because films are catalogued before they are released.
- `movies.runtime_min > 0` - a film cannot have zero or negative length.

## Foreign keys and ON DELETE

| Foreign key | References | ON DELETE | Justification |
|---|---|---|---|
| ratings.user_id | users(user_id) | CASCADE | A rating is one person's opinion. Once the account is gone there is nobody for the opinion to belong to, so it should go too. |
| ratings.movie_id | movies(movie_id) | RESTRICT | Deleting one film would delete every rating of it, written by many other users, and that data cannot be recovered. The `is_available` flag exists so a title can be taken out of the catalogue without being deleted. |
| movie_genres.movie_id | movies(movie_id) | CASCADE | A junction row only records that a pairing exists. If the film is gone, the row points at nothing. |
| movie_genres.genre_id | genres(genre_id) | RESTRICT | Deleting a genre still attached to films would remove that category from all of them |