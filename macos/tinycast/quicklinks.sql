CREATE TABLE IF NOT EXISTS quicklinks(
  id TEXT PRIMARY KEY NOT NULL,
  name TEXT NOT NULL,
  link TEXT NOT NULL,
  open_with TEXT,
  icon TEXT,
  in_root_search INTEGER NOT NULL DEFAULT 1,
  pinned_at REAL,
  created_at REAL NOT NULL,
  is_enabled INTEGER NOT NULL DEFAULT 1
);

CREATE INDEX IF NOT EXISTS quicklinks_pinned_at
  ON quicklinks(pinned_at) WHERE pinned_at IS NOT NULL;

INSERT OR REPLACE INTO quicklinks
  (id, name, link, open_with, icon, in_root_search, pinned_at, created_at, is_enabled)
VALUES
  ('2308C421-2E21-4970-84B2-F8BEEA1CF786',
   'Search Google',
   'https://google.com/search?q={argument}',
   NULL,
   NULL,
   1,
   NULL,
   1789350269.205,
   1);
