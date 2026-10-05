-- Row counts used to verify dumps/restores match. Output: table|count
SELECT 'admins', count(*) FROM admins
UNION ALL SELECT 'blog_posts', count(*) FROM blog_posts
UNION ALL SELECT 'contacts', count(*) FROM contacts
UNION ALL SELECT 'experiences', count(*) FROM experiences
UNION ALL SELECT 'page_views', count(*) FROM page_views
UNION ALL SELECT 'projects', count(*) FROM projects
UNION ALL SELECT 'schema_migrations', count(*) FROM schema_migrations
ORDER BY 1;
