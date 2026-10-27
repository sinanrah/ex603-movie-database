# EX603 Project: Movie Database

**Name:** Sinan Rahman  
**Chosen theme:** Movie / TV

This is a a relational database for a large-scale application where users rate movies and movies are classified by genre.

## Domain:  

The platform holds a catalogue of films and television titles and a population of registered users. The system has a catalogue of titles, and users who watch them and record what they thought. A user browses the catalogue, rates a title from
1 to 10, and can filter what they see by genre. The value of the platform comes
from aggregation where a large number of ratings could describe a film well enough to recommend it to someone else.

The design is driven by the questions the platform has to answer. What is the
average score for a given title, and how many ratings is that average based on?
Which titles in a genre rate highest? What has a particular user rated, and how
recently? Which titles are currently available? Each of those questions shaped
either an attribute or a constraint in the schema.

## Schema:

![Entity Relationship Diagram](schema/erd.png)

The full DDL is in [schema/schema.sql](schema/schema.sql). Seven tables:

| Table | Role / construct | What it holds |
|---|---|---|
| `users` | actor | Registered users |
| `movies` | producer | Films and TV series in the catalogue |
| `ratings` | event | One user's 1–10 score for one movie |
| `genres` | catalog | Genre categories |
| `movie_genres` | junction | Which genres each movie is tagged with |
| `movie_languages` | multivalued attribute | The languages a movie is available in |
| `episodes` | weak entity | Episodes of a series, keyed by series + season + episode number |

Design decisions to notice:
- `ratings` uses the composite key `(user_id, movie_id)`, so a user can only rate a movie once.
- `movies.remake_of_id` is a recursive foreign key linking a remake to its original (`ON DELETE SET NULL`).
- `movies.release_decade` is a derived attribute generated from `release_year`. Average score is computed at query time.
- Deleting a user cascades to their ratings, but deleting a movie that has ratings is restricted. Titles are hidden with `is_available` instead.
- CHECK constraints bound the score (1–10), release year, runtimes, episode numbers, and `content_type`.

Attribute definitions: [schema/schema-definition.md](schema/schema-definition.md)
Constraints and justifications: [schema/constraints.md](schema/constraints.md)
Modelling justification and reflection: [analysis/unit1.md](analysis/unit1.md)
DDL constraints table and CHECK reasoning: [analysis/unit2.md](analysis/unit2.md)

## Query catalogue:

### Unit 4

| Query | Business question |
|---|---|
| [4.1a](queries/unit4/q4_1.sql) | What are the count, total, average, minimum, and maximum score across all ratings, and how many users rated? |
| [4.1a check](queries/unit4/q4_1.sql) | Where does the minimum score come from? |
| [4.1b](queries/unit4/q4_1.sql) | How many ratings does each title have, and what is its average score? |
| [4.1c](queries/unit4/q4_1.sql) | Which titles have enough ratings for their spam rate to mean anything? |
| [4.1d](queries/unit4/q4_1.sql) | How do ratings break down by region and status? |
| [4.2A](queries/unit4/q4_2.sql) | For each title, how many ratings are there and how many were spam? |
| [4.2B](queries/unit4/q4_2.sql) | What is the spam rate for each region and for the whole platform? |
| [4.2C](queries/unit4/q4_2.sql) | What is the normal spam rate for a high-volume title? |

## Technical highlights:

## What I would do differently:

## Video presentation:

## How to run:

```
createdb ex603_movies
psql -d ex603_movies -f schema/schema.sql
```

The queries in `/queries` run against the course's provided Movie/TV dataset (`movies.sql`), loaded into its own database:

```
createdb ex603_data
psql -d ex603_data -f movies.sql
psql -d ex603_data -f queries/unit4/q4_1.sql
```

## AI Usage 
Assistance with Markdown formatting, mermaid.live ERD formatting, insight for deciding domains like movie release year,
insight into other approaches designers could make, specifically about my primary key.
