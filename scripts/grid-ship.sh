#!/usr/bin/env bash
#
# THE GRID — ship.  Run this ON YOUR MACBOOK (not in Claude's sandbox).
# It turns every project folder into a GitHub repo and pushes it.
# After this, the scheduled grid-agent picks them up automatically.
#
# One-time prerequisites:
#   1. Install GitHub CLI:   brew install gh
#   2. Log in once:          gh auth login        (pick GitHub.com → HTTPS → browser)
#
# Then just run:
#   cd "/Users/hk23neo/Documents/Claude/Projects"
#   bash "THE GRID/grid-agent/scripts/grid-ship.sh"
#
# Defaults: PRIVATE repos under your own account. Edit VISIBILITY below for public.

set -euo pipefail

PROJECTS_DIR="${1:-$HOME/Documents/Claude/Projects}"
VISIBILITY="--private"          # change to --public to make them public
SKIP=("THE GRID")              # folders to ignore

cd "$PROJECTS_DIR"
echo "Shipping projects from: $PROJECTS_DIR"
echo

GH_USER="$(gh api user --jq .login)"
echo "GitHub account: $GH_USER"
echo

for dir in */; do
  name="${dir%/}"
  for s in "${SKIP[@]}"; do [ "$name" = "$s" ] && continue 2; done

  # repo slug: lowercase, spaces/underscores -> hyphens
  slug="$(echo "$name" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+|-+$//g')"

  echo "── $name  →  $GH_USER/$slug"

  ( cd "$name"
    rm -rf .git                                   # clear any partial init
    printf '.DS_Store\nnode_modules/\n*.log\n.env\n.env.*\nThumbs.db\n' > .gitignore
    git init -q -b main
    git add -A
    git commit -qm "Initial commit — imported to THE GRID"

    if gh repo view "$GH_USER/$slug" >/dev/null 2>&1; then
      echo "   repo exists — pushing"
      git remote add origin "https://github.com/$GH_USER/$slug.git" 2>/dev/null || true
      git push -u origin main --force
    else
      gh repo create "$GH_USER/$slug" $VISIBILITY --source=. --remote=origin --push \
        --description "A world in THE GRID — hk23universe.vercel.app/grid"
    fi
    echo "   ✓ https://github.com/$GH_USER/$slug"
  )
  echo
done

echo "All projects shipped to GitHub."
echo "Next: import each repo at https://vercel.com/new so the agent can read live deploy status,"
echo "then add VERCEL_TOKEN to THE GRID repo's Actions secrets. The grid maintains itself from there."
