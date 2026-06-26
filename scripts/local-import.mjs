#!/usr/bin/env node
/**
 * THE GRID — Local importer (one-time seeder)
 * Scans a folder of project directories and seeds grid.json with real worlds.
 * The scheduled grid-agent.mjs takes over maintenance once repos are deployed.
 *
 * Usage:  node scripts/local-import.mjs "/path/to/Projects"
 *   - Defaults to the parent folder of THE GRID.
 *   - Skips the grid itself, node_modules, and dotfolders.
 */

import { readdir, readFile, stat, writeFile } from "node:fs/promises";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";

const __dirname = dirname(fileURLToPath(import.meta.url));
const OUT = join(__dirname, "..", "grid.json");
const ROOT = process.argv[2] || join(__dirname, "..", "..");
const SKIP = new Set(["THE GRID", "node_modules", ".git"]);
const BASE = process.env.GRID_BASE_URL || "https://hk23universe.vercel.app";

const slug = (s) =>
  s.toLowerCase().trim().replace(/[^a-z0-9]+/g, "-").replace(/^-+|-+$/g, "");

const titleCase = (s) =>
  s.replace(/[-_]+/g, " ").replace(/\s+/g, " ").trim().toUpperCase();

// Pull a one-line description from the most descriptive markdown/doc in a folder.
async function describe(dir) {
  let files;
  try { files = await readdir(dir); } catch { return ""; }
  const prefer = ["readme.md", "start-here.md", "00-start-here.md", "claude.md", "vision.md"];
  const mds = files.filter((f) => f.toLowerCase().endsWith(".md"));
  mds.sort((a, b) => {
    const ai = prefer.indexOf(a.toLowerCase());
    const bi = prefer.indexOf(b.toLowerCase());
    return (ai === -1 ? 99 : ai) - (bi === -1 ? 99 : bi);
  });
  for (const f of mds) {
    let txt;
    try { txt = await readFile(join(dir, f), "utf8"); } catch { continue; }
    const lines = txt.split("\n").map((l) => l.trim());
    // first non-empty, non-heading, non-frontmatter line
    let inFm = false;
    for (const l of lines) {
      if (l === "---") { inFm = !inFm; continue; }
      if (inFm || !l) continue;
      if (l.startsWith("#")) {
        // use heading only if nothing better follows; keep scanning first
        continue;
      }
      const clean = l.replace(/[*_`>#]/g, "").replace(/\[(.*?)\]\(.*?\)/g, "$1").trim();
      if (clean.length > 12) return clean.slice(0, 140);
    }
    // fall back to first heading text
    const h = lines.find((l) => l.startsWith("#"));
    if (h) return h.replace(/^#+\s*/, "").slice(0, 140);
  }
  return "";
}

async function detectType(dir, files) {
  if (files.includes("next.config.js") || files.includes("next.config.mjs")) return "next";
  if (files.includes("package.json")) return "node";
  if (files.some((f) => f.toLowerCase() === "index.html")) return "html";
  if (files.some((f) => f.toLowerCase().endsWith(".html"))) return "html";
  return "static";
}

async function gitRemote(dir) {
  try {
    const cfg = await readFile(join(dir, ".git", "config"), "utf8");
    const m = cfg.match(/\[remote "origin"\][^[]*url\s*=\s*(.+)/);
    return m ? m[1].trim() : "";
  } catch { return ""; }
}

async function main() {
  const entries = await readdir(ROOT, { withFileTypes: true });
  const worlds = [];

  for (const e of entries) {
    if (!e.isDirectory() || SKIP.has(e.name) || e.name.startsWith(".")) continue;
    const dir = join(ROOT, e.name);
    const files = await readdir(dir).catch(() => []);
    const s = await stat(dir);
    const remote = await gitRemote(dir);
    const id = slug(e.name);

    worlds.push({
      id,
      name: titleCase(e.name),
      description: (await describe(dir)) || "A world in progress.",
      url: remote ? remote.replace(/\.git$/, "") : `${BASE}/${id}`,
      repo: remote ? remote.replace(/.*[:/]([^/]+\/[^/]+?)(\.git)?$/, "$1") : null,
      status: remote ? "live" : "local",
      preview: remote ? `https://image.thum.io/get/width/800/crop/600/${remote.replace(/\.git$/, "")}` : null,
      lastPush: s.mtime.toISOString(),
      topics: [],
    });
  }

  const order = { live: 0, building: 1, local: 2, idle: 3, down: 4 };
  worlds.sort(
    (a, b) =>
      (order[a.status] - order[b.status]) ||
      (new Date(b.lastPush) - new Date(a.lastPush))
  );

  const grid = {
    generatedAt: new Date().toISOString(),
    tagline: "NOT GIVEN. TAKEN.",
    featured: worlds[0]?.id ?? null,
    worlds,
  };

  await writeFile(OUT, JSON.stringify(grid, null, 2) + "\n");
  console.log(`Imported ${worlds.length} worlds:`);
  for (const w of worlds) console.log(`  • ${w.name} [${w.status}] — ${w.description}`);
}

main().catch((e) => { console.error(e); process.exit(1); });
