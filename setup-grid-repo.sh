#!/usr/bin/env bash
# THE GRID — sube este folder a GitHub y deja al agente listo. Ejecutar en el Mac:
#   cd "/Users/hk23neo/Documents/Claude/Projects/THE GRID/grid-agent"
#   bash setup-grid-repo.sh
set -e

USER="hk23hub-dotcom"
REPO="the-grid"
DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$DIR"

echo "════════════════════════════════════════════"
echo "  THE GRID → GitHub  ($USER/$REPO)"
echo "════════════════════════════════════════════"
echo
echo "Pegá tu token de GitHub (empieza con ghp_) y apretá Enter."
echo "(No se guarda en el historial.)"
printf "Token: "
read -r GH_PAT
if [ -z "$GH_PAT" ]; then echo "❌ No pegaste el token. Volvé a correr: bash setup-grid-repo.sh"; exit 1; fi
echo

# 1. repo git local
if [ ! -d .git ]; then
  git init -b main >/dev/null
  echo "✓ repo local iniciado"
fi
printf '.DS_Store\nnode_modules/\n*.log\n.env\n.env.*\n' > .gitignore
git add -A
git commit -m "THE GRID — agent + command center" >/dev/null 2>&1 || echo "· (nada nuevo para commitear)"
echo "✓ commit listo"

# 2. crear el repo en GitHub (si ya existe, seguimos)
code=$(curl -s -o /tmp/grid_repo.json -w "%{http_code}" \
  -H "Authorization: token $GH_PAT" -H "Accept: application/vnd.github+json" \
  https://api.github.com/user/repos -d "{\"name\":\"$REPO\",\"private\":true,\"description\":\"THE GRID — self-updating world grid + command center\"}")
if [ "$code" = "201" ]; then echo "✓ repo creado en GitHub"
elif [ "$code" = "422" ]; then echo "· el repo ya existía, seguimos"
elif [ "$code" = "401" ]; then echo "❌ token inválido o sin permisos. Generá uno nuevo con scopes repo + workflow."; exit 1
else echo "⚠ respuesta inesperada de GitHub ($code):"; cat /tmp/grid_repo.json; fi

# 3. push (token solo en memoria, se borra del remote al final)
git remote remove origin 2>/dev/null || true
git remote add origin "https://$USER:$GH_PAT@github.com/$USER/$REPO.git"
echo "Subiendo..."
if git push -u origin main; then
  git remote set-url origin "https://github.com/$USER/$REPO.git"
  echo
  echo "════════════════════════════════════════════"
  echo "  ✅ LISTO"
  echo "  Repo:    https://github.com/$USER/$REPO"
  echo "  Agente:  https://github.com/$USER/$REPO/actions"
  echo "════════════════════════════════════════════"
else
  git remote set-url origin "https://github.com/$USER/$REPO.git"
  echo "❌ El push falló. Copiá lo que salió arriba y mandámelo."
  exit 1
fi
