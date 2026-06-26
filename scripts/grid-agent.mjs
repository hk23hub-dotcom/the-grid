#!/usr/bin/env node
/**
 * THE GRID — Agent
 * Runs on a schedule. Discovers your projects' live state and rewrites grid.json.
 * No manual editing of the grid ever again.
 *
 * Required env:
 *   GITHUB_TOKEN   - provided automatically inside GitHub Actions
 * Optional env:
 *   VERCEL_TOKEN   - https://vercel.com/account/tokens (enables live deploy status)
 *   VERCEL_TEAM_ID - only if your projects live under a team
 *   GITHUB_USER    - your GitHub username (defaults to the token owner)
 *   GRID_BASE_URL  - base URL for fallback previews (default: https://hk23universe.vercel.app)
 *   ANTHROPIC_API_KEY - if set, the agent writes/refreshes each world's tagline with an LLM
 *
 * Usage:  node scripts/grid-agent.mjs
 */

import { writeFile, readFile } from "node:fs/promises";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";

const __dirname = dirname(fileURLToPath(import.meta.url));
const OUT = join(__dirname, "..", "grid.json");

const {
  GITHUB_TOKEN,
  VERCEL_TOKEN,
  VERCEL_TEAM_ID,
  GITHUB_USER,
  GRID_BASE_URL = "https://hk23universe.vercel.app",
  ANTHROPIC_API_KEY,
  SUPABASE_URL,          // https://xxxx.supabase.co
  SUPABASE_KEY,          // service_role key (secret) — full read of command data
} = process.env;

const TAGLINE = "NOT GIVEN. TAKEN.";

// --- helpers ---------------------------------------------------------------

async function gh(path) {
  const res = await fetch(`https://api.github.com${path}`, {
    headers: {
      Accept: "application/vnd.github+json",
      Authorization: GITHUB_TOKEN ? `Bearer ${GITHUB_TOKEN}` : undefined,
      "User-Agent": "the-grid-agent",
    },
  });
  if (!res.ok) throw new Error(`GitHub ${path} -> ${res.status} ${await res.text()}`);
  return res.json();
}

async function vercel(path) {
  if (!VERCEL_TOKEN) return null;
  const sep = path.includes("?") ? "&" : "?";
  const teamQs = VERCEL_TEAM_ID ? `${sep}teamId=${VERCEL_TEAM_ID}` : "";
  const res = await fetch(`https://api.vercel.com${path}${teamQs}`, {
    headers: { Authorization: `Bearer ${VERCEL_TOKEN}` },
  });
  if (!res.ok) {
    console.warn(`Vercel ${path} -> ${res.status} (skipping)`);
    return null;
  }
  return res.json();
}

// thum.io needs no key — instant live preview thumbnails
const previewFor = (url) =>
  url ? `https://image.thum.io/get/width/800/crop/600/${url}` : null;

function deriveStatus(vercelState, lastPushISO) {
  if (vercelState === "READY") return "live";
  if (vercelState === "BUILDING" || vercelState === "QUEUED") return "building";
  if (vercelState === "ERROR" || vercelState === "CANCELED") return "down";
  // No Vercel data: infer from git activity
  if (lastPushISO) {
    const days = (Date.now() - new Date(lastPushISO)) / 86400000;
    return days < 30 ? "live" : "idle";
  }
  return "idle";
}

// Optional: LLM-written tagline per world
async function describe(world) {
  if (!ANTHROPIC_API_KEY) return world.description;
  try {
    const res = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: {
        "x-api-key": ANTHROPIC_API_KEY,
        "anthropic-version": "2023-06-01",
        "content-type": "application/json",
      },
      body: JSON.stringify({
        model: "claude-haiku-4-5-20251001",
        max_tokens: 60,
        messages: [{
          role: "user",
          content: `Write a single punchy <=12 word tagline for a project called "${world.name}". Repo description: "${world.description || "n/a"}". Topics: ${(world.topics || []).join(", ") || "none"}. Reply with ONLY the tagline, no quotes.`,
        }],
      }),
    });
    if (!res.ok) return world.description;
    const data = await res.json();
    return data?.content?.[0]?.text?.trim() || world.description;
  } catch {
    return world.description;
  }
}

// Read Command Center cloud data (notes / schedules / ideas) so the agent can act on it.
async function readCommandData() {
  if (!SUPABASE_URL || !SUPABASE_KEY) return null;
  try {
    const res = await fetch(
      `${SUPABASE_URL}/rest/v1/grid_command?id=eq.hk23&select=data`,
      { headers: { apikey: SUPABASE_KEY, Authorization: `Bearer ${SUPABASE_KEY}` } }
    );
    if (!res.ok) { console.warn(`Supabase read -> ${res.status}`); return null; }
    const rows = await res.json();
    return rows?.[0]?.data ?? null;
  } catch (e) { console.warn("Supabase read failed:", e.message); return null; }
}

// Surface schedules whose time has arrived (the agent's hook to execute them).
function dueSchedules(data) {
  const now = Date.now();
  return (data?.schedules ?? [])
    .filter((s) => !s.done && new Date(s.when).getTime() <= now)
    .sort((a, b) => new Date(a.when) - new Date(b.when));
}

// --- main ------------------------------------------------------------------

async function main() {
  // 0. Read Command Center cloud state (notes / ideas / scheduled executions)
  const cmd = await readCommandData();
  if (cmd) {
    console.log(`Command Center: ${cmd.notes?.length || 0} notes · ${cmd.ideas?.length || 0} ideas · ${cmd.schedules?.length || 0} schedules`);
    const due = dueSchedules(cmd);
    if (due.length) {
      console.log(`▶ ${due.length} scheduled execution(s) DUE now:`);
      for (const s of due) console.log(`   • ${s.title}${s.cmd ? `  [${s.cmd}]` : ""}${s.world ? `  →${s.world}` : ""}`);
      // Hook: run s.cmd here, or post to Slack/Discord. Left explicit for safety.
    }
  }

  // 1. Vercel projects (live deploy state + canonical URL)
  const vProjects = (await vercel("/v9/projects?limit=100"))?.projects ?? [];
  const vByName = new Map(vProjects.map((p) => [p.name, p]));

  // 2. GitHub repos (source of truth for what exists)
  const user = GITHUB_USER || (await gh("/user")).login;
  const repos = await gh(`/users/${user}/repos?per_page=100&sort=pushed`);

  // 3. Build each world
  const worlds = [];
  for (const r of repos) {
    if (r.fork || r.archived) continue;
    const v = vByName.get(r.name);
    const latestDeploy = v?.targets?.production;
    const url =
      v?.alias?.[0] ? `https://${v.alias[0]}` :
      latestDeploy?.url ? `https://${latestDeploy.url}` :
      r.homepage || `${GRID_BASE_URL}/${r.name}`;
    const status = deriveStatus(latestDeploy?.readyState, r.pushed_at);

    const world = {
      id: r.name,
      name: r.name.replace(/[-_]/g, " ").toUpperCase(),
      description: r.description || "",
      url,
      repo: r.full_name,
      status,
      preview: previewFor(url),
      lastPush: r.pushed_at,
      topics: r.topics || [],
    };
    world.description = await describe(world);
    worlds.push(world);
  }

  // 4. Rank: live first, then most-recently pushed
  const order = { live: 0, building: 1, idle: 2, down: 3 };
  worlds.sort(
    (a, b) =>
      (order[a.status] - order[b.status]) ||
      (new Date(b.lastPush) - new Date(a.lastPush))
  );

  const grid = {
    generatedAt: new Date().toISOString(),
    tagline: TAGLINE,
    featured: worlds.find((w) => w.status === "live")?.id ?? null,
    worlds,
  };

  // 5. Only write if changed (keeps git history clean)
  let prev = "";
  try { prev = await readFile(OUT, "utf8"); } catch {}
  const next = JSON.stringify(grid, null, 2) + "\n";
  const stripTs = (s) => s.replace(/"generatedAt":\s*"[^"]*",?/g, "");
  if (stripTs(prev) === stripTs(next)) {
    console.log("No changes. Grid is current.");
    process.exit(0);
  }
  await writeFile(OUT, next);
  console.log(`Wrote ${worlds.length} worlds to grid.json`);
}

main().catch((e) => { console.error(e); process.exit(1); });
