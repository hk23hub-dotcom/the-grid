#!/usr/bin/env node
// ORACLE daily report — runs in GitHub Actions, writes reports/YYYY-MM-DD.md + report.json.
// Deliverable for downstream agents at: https://hk23universe.vercel.app/report.json
import { readFileSync, writeFileSync, mkdirSync, readdirSync } from "node:fs";
import { execSync } from "node:child_process";

const today = new Date().toISOString().slice(0, 10);
const grid = JSON.parse(readFileSync("grid.json", "utf8"));

const sh = (cmd) => { try { return execSync(cmd, { encoding: "utf8" }).trim(); } catch { return ""; } };
const commits24h = sh(`git log --since="24 hours ago" --pretty=format:"%h %s"`).split("\n").filter(Boolean);
const commits7d = sh(`git log --since="7 days ago" --oneline`).split("\n").filter(Boolean);
const lastCommit = sh(`git log -1 --pretty=format:"%h %s (%cr)"`);

const worlds = grid.worlds || [];
const byStatus = worlds.reduce((m, w) => ((m[w.status] = (m[w.status] || 0) + 1), m), {});
const stale = worlds.filter(w => w.lastPush && (Date.now() - new Date(w.lastPush)) > 30 * 864e5);

const actions = [];
if (stale.length) actions.push(`Reactivar ${stale.length} mundo(s) sin push en 30d: ${stale.map(w => w.name).join(", ")}`);
if (!worlds.some(w => w.status === "live")) actions.push("Ningún mundo está LIVE — conectar VERCEL_TOKEN o desplegar uno");
actions.push("Revisar leads y sugerencias capturadas en el universo (ORACLE in-page → export JSON)");
actions.push("Repartir links ?ref= de la semana a los referidos");

const md = `# ORACLE · REPORTE DIARIO — ${today}

## ESTADO DEL UNIVERSO
- Mundos en THE GRID: **${worlds.length}** (${Object.entries(byStatus).map(([k, v]) => `${v} ${k}`).join(" · ")})
- Destacado: **${grid.featured || "—"}**
- Último commit: ${lastCommit}

## HECHO (últimas 24h)
${commits24h.length ? commits24h.map(c => `- ${c}`).join("\n") : "- Sin commits en 24h"}

## RITMO (7 días)
- ${commits7d.length} commits esta semana

## PARA DÓNDE VAMOS — ACCIONES EJECUTABLES
${actions.map(a => `- [ ] ${a}`).join("\n")}

---
_Generado automáticamente por ORACLE (cron diario). JSON gemelo para agentes: /report.json_
`;

mkdirSync("reports", { recursive: true });
writeFileSync(`reports/${today}.md`, md);

const json = {
  generated: new Date().toISOString(),
  date: today,
  worlds: worlds.map(w => ({ id: w.id, name: w.name, status: w.status, lastPush: w.lastPush })),
  byStatus,
  featured: grid.featured || null,
  commits24h,
  weekCommitCount: commits7d.length,
  actions,
  reports: readdirSync("reports").filter(f => f.endsWith(".md")).sort().reverse().slice(0, 30),
};
writeFileSync("report.json", JSON.stringify(json, null, 2) + "\n");
console.log(`ORACLE: wrote reports/${today}.md + report.json (${worlds.length} worlds, ${commits24h.length} commits 24h)`);
