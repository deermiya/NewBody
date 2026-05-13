const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET,POST,OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type",
};

export default {
  async fetch(request, env) {
    if (request.method === "OPTIONS") {
      return new Response(null, { status: 204, headers: corsHeaders });
    }

    const url = new URL(request.url);
    const match = url.pathname.match(/^\/sync\/([A-Za-z0-9_-]{6,80})$/);
    if (!match) {
      return json({ error: "Not found" }, 404);
    }

    const syncKey = match[1];

    try {
      if (request.method === "GET") {
        const row = await env.DB.prepare(
          "SELECT data_json, updated_at FROM user_snapshots WHERE sync_key = ?"
        )
          .bind(syncKey)
          .first();

        if (!row) {
          return json({ error: "No data for this sync key" }, 404);
        }

        return json({
          data: JSON.parse(row.data_json),
          updated_at: row.updated_at,
        });
      }

      if (request.method === "POST") {
        const body = await request.json();
        if (!body || typeof body !== "object" || !body.data) {
          return json({ error: "Missing data" }, 400);
        }

        const dataJson = JSON.stringify(body.data);
        if (dataJson.length > 1024 * 1024) {
          return json({ error: "Snapshot is too large" }, 413);
        }

        const updatedAt = Date.now();
        await env.DB.prepare(
          `INSERT INTO user_snapshots (sync_key, data_json, updated_at)
           VALUES (?, ?, ?)
           ON CONFLICT(sync_key)
           DO UPDATE SET data_json = excluded.data_json, updated_at = excluded.updated_at`
        )
          .bind(syncKey, dataJson, updatedAt)
          .run();

        return json({ ok: true, updated_at: updatedAt });
      }

      return json({ error: "Method not allowed" }, 405);
    } catch (error) {
      return json({ error: "Server error" }, 500);
    }
  },
};

function json(body, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      "Content-Type": "application/json; charset=utf-8",
      ...corsHeaders,
    },
  });
}
