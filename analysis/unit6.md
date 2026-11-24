# Unit 6: Window Functions

All scores below leave out withdrawn ratings where an average is involved, because every withdrawn rating carries the 0.5 placeholder score found in Unit 4.

## Task 6.1

The window version of the title average returns 200 rows, one per rating, with the title's average on every row. The GROUP BY version returns 13 rows, one per rated title. The GROUP BY version loses the individual ratings, so there is no way to see which ratings are close to their title's average and which are far from it.

A question that needs each row next to its group's average is: which ratings are unusually low or high for the title they were given to? A score of 1.0 means something different on a title that averages 4.1 than on one that averages 2.8. This is useful for the trust and safety team, since a rating far below its title's usual score is worth a second look. GROUP BY can only give one average per title, so the individual ratings are gone, and comparing them would need a second query joined back to ratings. The window version shows, for example, that rating 123 is a 0.8 on Title_08, 2.61 below that title's 3.41 average, and that every withdrawn rating sits at least 2.26 below its title's average.

The ranking query shows four ties: title IDs 5 and 7 both have 18 ratings, 2 and 11 have 16, 1 and 13 have 11, and 14 and 15 have 0. ROW_NUMBER puts Title_05 above Title_07 only because of its lower ID. RANK puts both in 4th place and skips to 6th for Title_12. DENSE_RANK puts both in 4th and gives Title_12 5th place.

The feature that would use this ranking is a "most rated titles" list on the home page. It should use RANK. Two titles with the same number of ratings should share a place, so ROW_NUMBER is unfair because it decides the order by ID. RANK is better than DENSE_RANK here because the skipped number keeps the position honest. With RANK, Title_12 in 6th place means five titles have more ratings than it does. With DENSE_RANK it would be listed 5th even though five titles are ahead of it.

NTILE(4) splits the 15 titles into bands of 4, 4, 4, and 3. Title IDs 5 and 7 both have 18 ratings, but Title_05 lands in band 1 and Title_07 in band 2, because NTILE splits by row count and the tie is only broken by movie_id. Two titles with the same activity end up in different bands, so the bands should not be used for anything where a title's band changes how it is treated without checking the tie.

## Task 6.2

Part A uses Title_02. Two of its three largest drops land on withdrawn ratings with the 0.5 placeholder, -2.9 on December 17 (spam) and -2.0 on January 27. The third, -2.5 on June 3, is a real published score of 2.5 right after a 5.0. The published scores move between 2.2 and 5.0 with no steady trend up or down.

A large delta on this platform means the score changed a lot from one rating of a title to the next. The first thing to check is the rating status, since in this data a large drop to 0.5 is usually a withdrawn rating and not a real opinion. If the rating is published, a single large drop is just one user who disagreed. If one title gets several large drops close together from different users, that could be spam or a coordinated attack on the title, and the trust and safety team should review the users behind them.

For Part B, the target is 50 ratings per quarter. The quarter running total ends at 53, 48, 51, and 48, so Q1 and Q3 reach it and Q2 and Q4 end 2 short, at 96%. A plain SUM only gives one number, 200 ratings for the year. The running total shows where the total stood on each day, so it answers when a quarter reached its target or how far behind it was at any point, which a single total cannot.

I used a 7-row moving average. Ratings only happened on 155 days of the year, and ROWS counts rows and not days, so 7 rows usually covers about two weeks. A 3-row window would follow every busy or quiet day, and a 30-row window would cover about two months and hide a change for that long. Two weeks is short enough to show a slow period while it is happening.

ROWS and RANGE give the same result here because each day appears once in the daily series. If the running total were ordered by date at the rating level, where several ratings share a day, RANGE would add all of that day's ratings at once and give them the same running total, while ROWS would add them one at a time.

Part C finds three titles with a gap of 90 days or more. The longest is Title_09, with no ratings for 113 days between January 5 and April 28. Its usual gap between ratings is about 17 days.

I think this is a real stop in activity for Title_09 and not a data problem. During those 113 days the platform recorded 61 ratings for 11 other titles, so ratings were still being recorded. Title_09's ratings also start again on April 28 and continue at a normal pace for the rest of the year. A recording problem would more likely show up across many titles at once. What I cannot tell is why it stopped. Title_09 is currently marked unavailable, and it could have been unavailable during that stretch too, but the data only has the current is_available value and no history of when it changed. The response would be to check the catalogue's change history for Title_09 before deciding whether anything needs fixing.

## Task 6.3

The top-N query would power a "highest ratings" section on each title page, showing the three users who rated the title highest and their scores. It could also be used to pick users for recommendations, since people who rated a title highly are likely to want similar titles.

Three is a better number than one or ten. One rating is too easy to game, and spam on this platform is exactly one account leaving one rating, so a single top rating could be a fake. Ten is more than most titles can fill with good ratings. Title_04 only has 6 ratings, and its third highest is already 2.4, so a top ten would mostly be low scores. Three shows a few real opinions without padding the list.

Ties at third place are broken by the earlier rating. Title IDs 5, 7, 8, and 10 each have more than three 5.0 ratings, so their third place was decided by rated_at. A page with three slots needs exactly three rows, and the earliest rating has been on the title the longest, so the list does not reshuffle every time someone else gives it a 5.0.

In Part B, the spam rate jumps a lot from month to month, from 18.2% in March to 0% in April. A large month-over-month change here mostly comes from how few ratings there are. March's 18.2% is only 2 spam ratings out of 11. When the previous month had no spam, the percent change would divide by zero, so NULLIF turns it into NULL. Before reacting to a large change, someone should check the counts behind the rate. If the spam rate stays high for two or three months in a row, the trust and safety team should look at which titles and users the spam is coming from. A single high month with one or two spam ratings does not need its own response. No month was missing, so LAG compared each month with the one right before it.

## Reflection

A reporting question that is easy with a window function is: for each title, show every rating with the score of the rating before it, so a reviewer can see when a title's scores suddenly changed. With LAG partitioned by title and ordered by rated_at, this is one query, and every rating stays in the result with its previous score next to it.

With GROUP BY alone, this is awkward. GROUP BY collapses a title's ratings into one row, so the individual ratings and their order are gone. To get the previous rating I would have to join ratings to itself, matching each rating to the latest rating of the same title with an earlier rated_at, which needs a subquery with MAX on every row. That is harder to read, easy to get wrong when two ratings share a time, and slower as the table grows.

The same is true for the other questions in this unit. A title's average next to each rating, the top three ratings per title, and the month before each month all need information from other rows while keeping every row. GROUP BY answers questions about groups, and window functions answer questions about rows inside their groups. Most of the questions leadership asked in this unit were the second kind.
