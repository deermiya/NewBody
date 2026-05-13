CREATE TABLE IF NOT EXISTS user_snapshots (
  sync_key TEXT PRIMARY KEY,
  data_json TEXT NOT NULL,
  updated_at INTEGER NOT NULL
);
