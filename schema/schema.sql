-- =================================================================
-- EX 603 Assignment 2 — schema.sql
-- Theme: Movie / TV
-- Author: Sinan Rahman
-- Target: PostgreSQL 14+
-- Task 2.1: creates the whole schema. Runs top to bottom on an
-- empty database, and can be run again because of the reset block.
-- =================================================================

-- Creation order (a table goes after every table it references):
--   1. users           references nothing
--   2. genres          references nothing
--   3. movies          references only itself (remake_of_id)
--   4. ratings         references users, movies
--   5. movie_genres    references movies, genres
--   6. movie_languages references movies
--   7. episodes        references movies

-- Reset. Reverse creation order, so no dependency blocks a drop.
DROP TABLE IF EXISTS episodes        CASCADE;
DROP TABLE IF EXISTS movie_languages CASCADE;
DROP TABLE IF EXISTS movie_genres    CASCADE;
DROP TABLE IF EXISTS ratings         CASCADE;
DROP TABLE IF EXISTS movies          CASCADE;
DROP TABLE IF EXISTS genres          CASCADE;
DROP TABLE IF EXISTS users           CASCADE;


-- ----------------------------------------------------------------
-- 1. users (actor) — first, it references nothing.
-- ----------------------------------------------------------------
CREATE TABLE users (
    user_id      INTEGER GENERATED ALWAYS AS IDENTITY,
    display_name VARCHAR(50)  NOT NULL,
    email        VARCHAR(254) NOT NULL,
    joined_date  DATE         NOT NULL DEFAULT CURRENT_DATE,
    CONSTRAINT pk_users PRIMARY KEY (user_id),
    CONSTRAINT uq_users_email UNIQUE (email)
);


-- ----------------------------------------------------------------
-- 2. genres (catalog) — references nothing, so it can go early.
-- ----------------------------------------------------------------
CREATE TABLE genres (
    genre_id INTEGER GENERATED ALWAYS AS IDENTITY,
    name     VARCHAR(40) NOT NULL,
    CONSTRAINT pk_genres PRIMARY KEY (genre_id),
    CONSTRAINT uq_genres_name UNIQUE (name)
);


-- ----------------------------------------------------------------
-- 3. movies (producer) — only references itself, so it can be
--    created once users and genres exist.
--    Recursive FK: remake_of_id points to the original movie.
--    Derived attribute: release_decade is generated from release_year.
-- ----------------------------------------------------------------
CREATE TABLE movies (
    movie_id       INTEGER GENERATED ALWAYS AS IDENTITY,
    title          VARCHAR(200) NOT NULL,
    content_type   VARCHAR(10)  NOT NULL DEFAULT 'film',
    release_year   INTEGER      NOT NULL,
    release_decade INTEGER GENERATED ALWAYS AS ((release_year / 10) * 10) STORED,
    runtime_min    INTEGER,
    is_available   BOOLEAN      NOT NULL DEFAULT TRUE,
    remake_of_id   INTEGER,
    CONSTRAINT pk_movies PRIMARY KEY (movie_id),
    CONSTRAINT fk_movies_remake_of
        FOREIGN KEY (remake_of_id) REFERENCES movies (movie_id)
        ON DELETE SET NULL,
    CONSTRAINT chk_movies_content_type CHECK (content_type IN ('film', 'series')),
    CONSTRAINT chk_movies_release_year CHECK (release_year BETWEEN 1888 AND 2035),
    CONSTRAINT chk_movies_runtime      CHECK (runtime_min > 0),
    CONSTRAINT chk_movies_not_own_remake CHECK (remake_of_id IS DISTINCT FROM movie_id)
);


-- ----------------------------------------------------------------
-- 4. ratings (event) — needs users and movies to exist first.
--    Composite PK: one rating per user per movie.
-- ----------------------------------------------------------------
CREATE TABLE ratings (
    user_id  INTEGER   NOT NULL,
    movie_id INTEGER   NOT NULL,
    score    INTEGER   NOT NULL,
    rated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_ratings PRIMARY KEY (user_id, movie_id),
    CONSTRAINT fk_ratings_user
        FOREIGN KEY (user_id) REFERENCES users (user_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_ratings_movie
        FOREIGN KEY (movie_id) REFERENCES movies (movie_id)
        ON DELETE RESTRICT,
    CONSTRAINT chk_ratings_score CHECK (score BETWEEN 1 AND 10)
);


-- ----------------------------------------------------------------
-- 5. movie_genres (junction) — needs movies and genres first.
--    Composite PK over the two foreign keys.
-- ----------------------------------------------------------------
CREATE TABLE movie_genres (
    movie_id INTEGER NOT NULL,
    genre_id INTEGER NOT NULL,
    CONSTRAINT pk_movie_genres PRIMARY KEY (movie_id, genre_id),
    CONSTRAINT fk_movie_genres_movie
        FOREIGN KEY (movie_id) REFERENCES movies (movie_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_movie_genres_genre
        FOREIGN KEY (genre_id) REFERENCES genres (genre_id)
        ON DELETE RESTRICT
);


-- ----------------------------------------------------------------
-- 6. movie_languages — needs movies first.
--    Multivalued attribute: a movie can be available in many
--    languages, so each language gets its own row.
-- ----------------------------------------------------------------
CREATE TABLE movie_languages (
    movie_id INTEGER     NOT NULL,
    language VARCHAR(40) NOT NULL,
    CONSTRAINT pk_movie_languages PRIMARY KEY (movie_id, language),
    CONSTRAINT fk_movie_languages_movie
        FOREIGN KEY (movie_id) REFERENCES movies (movie_id)
        ON DELETE CASCADE
);


-- ----------------------------------------------------------------
-- 7. episodes — needs movies first.
--    Weak entity: an episode is identified by its series plus its
--    season and episode number (owner's key + discriminator).
-- ----------------------------------------------------------------
CREATE TABLE episodes (
    movie_id       INTEGER      NOT NULL,
    season_number  INTEGER      NOT NULL,
    episode_number INTEGER      NOT NULL,
    title          VARCHAR(200) NOT NULL,
    runtime_min    INTEGER,
    CONSTRAINT pk_episodes PRIMARY KEY (movie_id, season_number, episode_number),
    CONSTRAINT fk_episodes_movie
        FOREIGN KEY (movie_id) REFERENCES movies (movie_id)
        ON DELETE CASCADE,
    CONSTRAINT chk_episodes_season  CHECK (season_number > 0),
    CONSTRAINT chk_episodes_number  CHECK (episode_number > 0),
    CONSTRAINT chk_episodes_runtime CHECK (runtime_min > 0)
);
