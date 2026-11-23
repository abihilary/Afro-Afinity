# Feed (parked)

The news-feed screens from the original prototype. They ran on a hardcoded
in-memory store (`feed_store.dart`) and there is no feed in the API or on the
website, so they are kept here, outside `lib/`, and not built.

To bring the feed back: add the feed tables, routes and moderation in
`afroaffinity` (API + web) first, then move these files back under
`lib/features/feed` and wire them to the real endpoints. The legacy site had
`wp_dsp_news_feed` (1 717 rows) if the content is wanted.
