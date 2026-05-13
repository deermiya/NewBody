# NewBody Cloud Sync Worker

This Worker stores one JSON snapshot per sync key.

## Deploy

```bash
cd sync_worker
npm create cloudflare@latest
wrangler d1 create newbody_sync
```

Copy the generated D1 `database_id` into `wrangler.toml`, then run:

```bash
wrangler d1 execute newbody_sync --remote --file=schema.sql
wrangler deploy
```

After deploy, set `AppConfig.syncBaseUrl` in `lib/config.dart` to your Worker URL, for example:

```dart
static const String syncBaseUrl = 'https://newbody-sync.yourname.workers.dev';
```
