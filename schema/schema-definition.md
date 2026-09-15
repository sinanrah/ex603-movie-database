# Schema Definition

Movie theme  
relations: `users` (actor), `movies` (producer),
`ratings` (event), `genres` (catalog), `movie_genres` (junction).

## users

**Relation schema:** users(user_id, display_name, email, joined_date)

| Attribute | Domain |
|---|---|
| user_id | Whole number, positive, assigned by the database |
| display_name | Text, required |
| email | Text, required, unique |
| joined_date | Date, required |

**Primary key:** user_id

## movies

**Relation schema:** movies(movie_id, title, release_year, runtime_min, is_available)

| Attribute | Domain |
|---|---|
| movie_id | Whole number, positive, assigned by the database |
| title | Text, required |
| release_year | Whole number, 1888 to 2035 |
| runtime_min | Whole number of minutes, greater than zero, may be unknown |
| is_available | True or false, required |

**Primary key:** movie_id

## ratings

**Relation schema:** ratings(user_id, movie_id, score, rated_at)

| Attribute | Domain |
|---|---|
| user_id | Whole number, must exist in users |
| movie_id | Whole number, must exist in movies |
| score | Whole number, 1 to 10 inclusive |
| rated_at | Date and time |

**Primary key:** (user_id, movie_id) — composite

## genres

**Relation schema:** genres(genre_id, name)

| Attribute | Domain |
|---|---|
| genre_id | Whole number, positive, assigned by the database |
| name | Text, required, unique |

**Primary key:** genre_id

## movie_genres

**Relation schema:** movie_genres(movie_id, genre_id)

| Attribute | Domain |
|---|---|
| movie_id | Whole number, must exist in movies |
| genre_id | Whole number, must exist in genres |

**Primary key:** (movie_id, genre_id) — composite