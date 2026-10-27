# Unit 4: Aggregation

## Choices and defaults

Each of these choices changes the numbers, so here is why I made them and what a different choice would show.

- **Failure means a spam withdrawal.** That is the failure the dashboard reported on. Counting every withdrawal instead would give 17% (34 of 200) and put title ID 11 near the top, with 5 of its 16 ratings withdrawn, even though only one of those was spam.
- **Every rating is in the denominator.** A rating with no withdrawal reason (NULL) was never withdrawn, so it counts as a normal rating. Leaving out the 7 ratings users withdrew themselves, as the old dashboard meant to, gives 12 of 193 (6.2%), which tells the same story.
- **At least 10 ratings in 4.1c.** Below 10, one spam rating moves a title's rate by more than 10 percentage points, so the rate says more about a single rating than about the title. Title ID 4, with 6 ratings, is the only rated title left out. A higher threshold of 15 would also drop title ID 3 (13 ratings, 15.4%), one of the two titles I would investigate. A lower threshold of 5 would let in title ID 4 at 16.7%, based on a single spam rating.
- **Region is where the rating was made.** I used the device country because it describes the rating itself. Grouping by the user's home country tells a different story: Vietnam goes from the lowest rate (2.3%) to the highest (11.1%), and Brazil rises to 10.6%. If a region is singled out, both views should be checked.
- **High volume means more ratings than the average rated title (15.4).** This keeps the cutoff tied to the data instead of a number I picked. Using the 10-rating threshold instead gives a baseline of 5.7%, close to 4.8%, so the same titles stand out either way.
- **Withdrawn ratings stay in the score averages.** The task asked for the metric across the whole table, so 4.1a and 4.1b include them. Their 0.5 placeholder pulls averages down. Title ID 2 averages 2.77 with them and 3.53 without.

## Task 4.1

**Who would act on the per-title breakdown.** The trust and safety lead who decides which titles get a closer spam review.

**What the aggregate hides.** The platform average score of 2.85 hides its distribution. All 34 withdrawn ratings have the same placeholder score of 0.5, which pulls the average down. Published ratings alone average 3.32, and a title with more withdrawals looks worse than it is for the same reason. The counts hide who is counted. A title's rating count includes its withdrawn and spam ratings, the 12 spam ratings come from only 10 users, and title IDs 14 and 15 have no ratings at all, so they do not show up in any per-title result.

**What I would need to see next.** Each title's spam rate next to the users behind its spam ratings, to tell whether a high rate comes from the title or from a few accounts, and average scores calculated without the withdrawn ratings.

## Task 4.2

**Part A.** For each title, the query answers two questions side by side: how many ratings does the title have, and how many of them were withdrawn as spam?

**Part B.** The regional director needs the subtotals rather than the detail rows. The five rows with a region name are the regional subtotals, and the row labeled "All regions" is the grand total. The grand total supports a platform-wide decision, such as whether spam is a big enough problem to justify freezing payouts or changing policy for everyone, which no single region's row can answer.

**Part C.** What is the normal spam rate for a high-volume title, meaning a title with more ratings than the average rated title? The answer is 4.8%, across 8 titles.

## Reflection

Conditional aggregation answers several questions in one pass. In Part A, one query reads every rating once and, for each title, counts all of its ratings and its spam ratings at the same time. The CASE expression decides for each row whether it adds to the spam column, so both numbers always come from the same set of rows.

The other way is to run two filtered queries, one counting all ratings per title and one counting only spam ratings with a WHERE clause, then match the two results by title. That means reading the table twice and doing extra work to put the results back together. With 200 ratings this makes no real difference, but with a million rows each extra pass means reading a million more rows, and a report that runs often pays that cost every time.

The bigger risk is correctness. With two queries, the numerator and the denominator are written separately, so a small difference between their filters can make them count different rows. That is the same kind of problem behind the Unit 3 dashboard error, where a filter silently left out most of the ratings. A title with no spam ratings would also be missing from the spam query and would have to be added back as zero. In one pass, every title appears and its rate is always calculated from the same rows.
