#!/usr/bin/bash
set -euo pipefail

PKG='astah-professional'
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GITHUB_URL='https://github.com/KingDasWinx/astah-professional-aur-update'

if [[ -z "${AUR_USERNAME:-}" || -z "${AUR_PASSWORD:-}" ]]; then
  echo "Defina AUR_USERNAME e AUR_PASSWORD para publicar o comentário no AUR." >&2
  exit 1
fi

COOKIE="$(mktemp)"
trap 'rm -f "$COOKIE"' EXIT

curl -s -c "$COOKIE" 'https://aur.archlinux.org/login' \
  -d "user=${AUR_USERNAME}" \
  -d "passwd=${AUR_PASSWORD}" >/dev/null

TOKEN="$(curl -s -b "$COOKIE" "https://aur.archlinux.org/pkgbase/${PKG}" \
  | rg -o 'name="token" value="\K[a-z0-9]+' | head -1)"

if [[ -z "$TOKEN" ]]; then
  echo "Falha ao autenticar no AUR (token CSRF não encontrado)." >&2
  exit 1
fi

COMMENT="$(cat <<EOF
@jflake Proposed update to Astah Professional 12.0.0 (upstream released 2026-07-15).

Changes:
- pkgver 12.0.0, revision 4fa570
- depends: jre25-openjdk (was jre21-openjdk; v12 requires Java 25 per upstream system requirements)
- optdepends: graphviz (PlantUML plugin preview; set GRAPHVIZ_DOT=/usr/bin/dot on Linux if needed)
- install script notes for Java 25 and graphviz

Source deb (verified): https://cdn.change-vision.com/files/astah-professional_12.0.0.4fa570-0_all.deb
Release notes: https://astah.net/support/astah-pro/release-notes/

Prepared PKGBUILD, .SRCINFO and install file:
${GITHUB_URL}

Tested locally with makepkg -si on Arch; package builds and Astah 12.0.0 launches successfully.
EOF
)"

curl -s -b "$COOKIE" "https://aur.archlinux.org/pkgbase/${PKG}" \
  --data-urlencode "action=do_AddComment" \
  --data-urlencode "ID=0" \
  --data-urlencode "token=${TOKEN}" \
  --data-urlencode "comment=${COMMENT}" >/dev/null

echo "Comentário publicado em https://aur.archlinux.org/pkgbase/${PKG}"
