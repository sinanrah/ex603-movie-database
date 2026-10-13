# Unit 3 Finding: The Spam Withdrawal Rate on the Dashboard

**To:** the team that owns the ratings dashboard
**From:** Sinan Rahman, Trust and Data team

The dashboard reported that roughly half of all ratings end up withdrawn as spam, and that number was used to freeze the quarterly reviewer payouts. The data does not support it. There are 200 ratings in total. 156 were published normally, 10 were flagged for review, and 34 were withdrawn. Only 12 of those withdrawals were for spam. That is about 6% of all ratings, not 50%. The other withdrawals were for policy violations, duplicate ratings, or because the user asked for the rating to be removed.

The error came from how the dashboard decided which ratings to count. It was meant to count every rating except the ones users withdrew themselves. Most ratings, though, were never withdrawn, so they have no withdrawal reason recorded at all. The filter treated "no reason" as "unknown" and quietly left all 166 of those ratings out, without any error or warning. That left only 27 ratings in the count, almost all of them withdrawals, and 12 of those 27 were spam, which is where the figure of about 44% came from. When the ratings with no withdrawal reason are counted as they should be, 193 ratings are included and the spam rate is about 6%.

We recommend lifting the freeze on the reviewer payouts, since the reason for it came from this counting error and not from a real spam problem. The 10 flagged ratings and the 12 spam withdrawals, which come from 10 users, can still be reviewed individually if needed. That is a much smaller group than the dashboard suggested. The calculation behind the dashboard should be replaced with the corrected version before it is used for any more decisions.
