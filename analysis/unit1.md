# Unit 1 — Modelling Justification and Reflection

## Modelling Justification

### Choice of primary keys

Three of the five relations use a surrogate key: `users`, `movies`, and
`genres`. In each case there is an attribute that looks like it could serve as
the key, and in each case it fails. A display name is not unique. Titles are not
unique either, because there can be more than one movies of the same name and a 
remake shares its title with the original film. Email is unique, but a user can 
change it, and a primary key that changes has to beupdated in every row that 
references it. A surrogate key has no meaning outsidethe database, and that is 
what makes it safe.

The other two relations use composite keys made of their foreign keys. In
`ratings`, the pair `(user_id, movie_id)` is what a rating actually is: this
person's score for this film. In `movie_genres`, the pair is the entire content
of the row. Adding a separate id column to either would not have removed the
need for a rule preventing duplicates, so it would have been an extra column
that achieved nothing.

### ON DELETE behaviours

The four foreign keys do not all behave the same way, and the differences are
the most deliberate part of the design.

Deleting a user cascades to that user's ratings. A rating is one person's
opinion, and once the account is gone there is nobody for the opinion to belong
to.

Deleting a film is restricted. Removing a
single film would delete every rating of that film, and those ratings were
written by many different users who have nothing to do with the deletion. That
data cannot be recreated. This is why `movies` has an `is_available` flag: a
film that is no longer offered can be marked unavailable and disappear from the
catalogue while its rating history stays intact.

Inside `movie_genres` the two foreign keys split the same way. Deleting a film
cascades, because a junction row pointing at a film that no longer exists is
meaningless. Deleting a genre is restricted, because a genre still attached to
films is still in use.

### Rules enforced in the schema rather than the application

I put a rule in the schema when it is a fact about the data rather than a
decision about the product. The 1 to 10 score range is the clearest example. The
scale is part of what a rating is, so no score outside it should be storable by
any route. The same applies to the composite key on `ratings`: one
rating per user per film is structural, so the schema should make breaking it
impossible rather than trusting the application to do so.

I left a rule to the application when it depends on something a single row
cannot see. A rule such as "a user cannot rate a film before it has been
released" needs to compare a value in `ratings` against a value in `movies`.

Some rules that look like data rules are not rules the schema can hold at all.
Preventing coordinated manipulation of a film's average score is one: deciding
whether a rating is legitimate depends on information outside the row being
inserted, such as how many accounts were created in the last hour or how fast
one account is rating. Requiring a unique email does not solve it either, since
addresses are easy to obtain in bulk. What the schema can guarantee is narrower
and still worth having. one account can hold at most one rating per film, so
manipulation requires many accounts rather than one account voting repeatedly.

## Reflection

The decision another designer could reasonably have made differently is the
primary key of `ratings`. I chose `(user_id, movie_id)`, which allows one rating
per user per film. If a user changes their mind, the existing row is updated and
the previous score is gone. The alternative is to include `rated_at` in the key,
which would keep every version of every rating and turn the table into a history
of how opinions changed.

I chose against the history version because of what this platform mostly does.
The two things I assumed it needs constantly are the average score for a film and a check
on whether the current user has already rated it. With my key, the second is a
direct lookup on the primary key, and the first is a straightforward aggregate
over the rows for that film and with the history version, neither is simple any
more where every one of those queries first has to work out which row is the most
recent for each user and film pair, and only then can it aggregate. That extra
step would apply to the most common read on the site. Writes would get slightly
simpler, since a changed rating becomes an insert instead of an update, but
changed ratings are rare compared with reads.

Therefore my design cannot answer questions about how a film's ratings
shifted over time, and it cannot show that a user changed their mind. A platform
whose product was analysing rating behaviour should choose the opposite. My decisions
optemized for aggregate scores.