# THE GRID — Agent

Makes THE GRID run on its own. You stop editing the grid; a scheduled agent discovers
your projects' real state and rewrites `grid.json`. Vercel auto-rebuilds. Done.

```
grid-agent (every 6h via GitHub Actions)
  ├─ GitHub API  → which repos exist, descriptions, last push
  ├─ Vercel API  → live deploy status + canonical URLs
  ├─ thum.io     → live preview thumbnails (no key needed)
  ├─ (optional) Anthropic → auto-writes each world's tagline
  └─ writes grid.json → commits → Vercel rebuilds THE GRID
```

## Install (drop into your repo)

Copy these into the **root of THE GRID repo**:

```
grid.json                          → /grid.json   (or /public/grid.json)
scripts/grid-agent.mjs             → /scripts/grid-agent.mjs
.github/workflows/grid-agent.yml   → /.github/workflows/grid-agent.yml
```

## 1. Point the page at grid.json

Replace your hardcoded worlds array with a fetch. Minimal vanilla version:

```js
const { worlds, tagline } = await fetch("/grid.json").then(r => r.json());

document.querySelector("#grid").innerHTML = worlds.map(w => `
  <a class="world world--${w.status}" href="${w.url}" target="_blank">
    <img loading="lazy" src="${w.preview}" alt="${w.name}">
    <h3>${w.name}</h3>
    <p>${w.description}</p>
    <span class="status">${w.status}</span>
  </a>
`).join("");
```

If THE GRID is Next.js, fetch `grid.json` in a server component or import it directly:
`import grid from "@/grid.json"`.

## 2. Add secrets (GitHub repo → Settings → Secrets → Actions)

| Secret | Required | Where |
|---|---|---|
| `GITHUB_TOKEN` | auto | provided by Actions — nothing to do |
| `VERCEL_TOKEN` | recommended | https://vercel.com/account/tokens |
| `VERCEL_TEAM_ID` | only if team | Vercel team settings |
| `ANTHROPIC_API_KEY` | optional | enables auto-written taglines |

Without `VERCEL_TOKEN` it still works — status is inferred from git activity instead of live deploys.

## 3. Run it

- It runs automatically every 6 hours.
- Run on demand: repo → **Actions** tab → **grid-agent** → **Run workflow**.
- Test locally: `GITHUB_USER=hk23 node scripts/grid-agent.mjs`

## Status values the agent sets

`live` (deploy READY or pushed <30d) · `building` · `idle` (stale) · `down` (deploy error).
Worlds are auto-sorted live-first, then most recently pushed. `featured` = first live world.

## Make it more autonomous (optional next steps)

- **Notify on change** — add a Slack/Discord webhook step after the commit step.
- **Filter what's grid-worthy** — add a `grid` GitHub topic and have the agent only include tagged repos.
- **Screenshots you control** — swap thum.io for a Vercel OG/Puppeteer route.
