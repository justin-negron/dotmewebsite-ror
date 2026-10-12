-- Removes the sample data that db/seeds.rb inserted into production on
-- 2026-03-19 at 04:04:17 UTC (the old seeds created fake contacts, backdated
-- page views, and placeholder blog posts). Real content is never touched: every
-- row must fall inside the seed run's window (04:04:16-04:04:18 UTC) AND match
-- the seed's content (names, backdated timestamps, exact blog body hashes).
--
-- Dry run (default, rolls back):
--   psql -d <db> -f purge-fake-seed-data.sql
-- Apply (only the exact value 1 commits):
--   psql -v commit=1 -d <db> -f purge-fake-seed-data.sql

\set ON_ERROR_STOP on
\if :{?commit}
\else
  \set commit 0
\endif
SELECT :'commit' = '1' AS do_commit \gset

\set seed_from '''2026-03-19 04:04:16'''
\set seed_to   '''2026-03-19 04:04:18'''

BEGIN;

\echo '== contacts: seed samples (Sarah Johnson, Mike Chen) =='
DELETE FROM contacts
 WHERE created_at BETWEEN :seed_from AND :seed_to
   AND (name, email) IN (('Sarah Johnson', 'sarah.j@example.com'),
                         ('Mike Chen', 'mchen@techcorp.com'))
RETURNING id, name;

\echo '== page_views: backdated seed rows =='
WITH deleted AS (
  DELETE FROM page_views
   WHERE updated_at BETWEEN :seed_from AND :seed_to
     AND abs(extract(epoch FROM updated_at - created_at)) > 1
  RETURNING id
)
SELECT count(*) AS deleted, min(id), max(id) FROM deleted;

\echo '== blog_posts: unedited seed placeholders (matched by exact body) =='
DELETE FROM blog_posts
 WHERE created_at BETWEEN :seed_from AND :seed_to
   AND updated_at = created_at
   AND md5(content) IN ('0dcc52347712199337ab6200bbf9edd7',  -- Find My History
                        'fe58fd5f62792ee9b0b34a0da8526fad',  -- Autonomous Robot Swarm
                        '61a72d8b5fde2d3df6bc34910a206f37',  -- University Discord Bot
                        '922e53ee7e14a91296376be54b662be9',  -- Logic Gates using MOSFETs
                        '121d4e5ab971ea3358a594a6de19409c')  -- Blackjack Emulator
RETURNING id, title, published;

\echo '== remaining rows =='
SELECT 'blog_posts' AS tbl, count(*) FROM blog_posts
UNION ALL SELECT 'contacts', count(*) FROM contacts
UNION ALL SELECT 'page_views', count(*) FROM page_views;

\if :do_commit
  COMMIT;
  \echo 'COMMITTED'
\else
  ROLLBACK;
  \echo 'DRY RUN: rolled back. Re-run with -v commit=1 to apply.'
\endif
