#!/usr/bin/env bash
# drip-publisher — release the next batch of held-back drafts for one site.
#
# Usage:   bash .github/scripts/release.sh <site-dir> [batch-size] [timezone]
# Example: bash .github/scripts/release.sh blog 5 Asia/Jakarta
#
# Generator-agnostic. Configure via env vars (or edit the defaults below). Defaults
# match an Astro project. See references/generators.md for the exact settings per
# generator. Writes `released_count` and `release_date` to $GITHUB_OUTPUT so the
# workflow can skip build+deploy when nothing was released.
#
#   DRIP_MODE   how drafts are hidden — one of:
#     prefix_flag  (default) filename starts with "_"  AND/OR frontmatter flag; on
#                  release the "_" is stripped and the flag is cleared. (Astro)
#     flag         frontmatter flag only; held-back files are found by DRAFT_HIDDEN_REGEX
#                  and the flag is flipped to DRAFT_RELEASE_VALUE. (Hugo/Eleventy/Next/Jekyll-flag)
#     folder       drafts live in DRAFTS_DIR and are moved into POSTS_DIR on release.
#                  (Jekyll _drafts/, plain HTML)
#
#   DRIP_CONTENT_DIR   articles dir, relative to <site-dir>  (default src/content/articles)
#   DRIP_DRAFTS_DIR    folder-mode: draft dir   (default src/content/drafts)
#   DRIP_POSTS_DIR     folder-mode: live dir    (default = DRIP_CONTENT_DIR)
#   DRAFT_FIELD        frontmatter flag field   (default draft;   Jekyll: published)
#   DRAFT_RELEASE_VALUE value to set on release (default false;   Jekyll published: true)
#   DRAFT_HIDDEN_REGEX  flag-mode: regex matching a held-back file's flag line
#                       (default '^draft:[[:space:]]*true'; Jekyll '^published:[[:space:]]*false')
#   DATE_FIELD         publish-date field       (default pubDate; Hugo/Jekyll: date)
#   TEMPLATE_GLOB      never-released template   (default _TEMPLATE)
set -euo pipefail

SITE_DIR="${1:?usage: release.sh <site-dir> [batch-size] [timezone]}"
BATCH="${2:-${DRIP_BATCH:-5}}"
TZNAME="${3:-${DRIP_TZ:-UTC}}"

MODE="${DRIP_MODE:-prefix_flag}"
CONTENT_DIR="${DRIP_CONTENT_DIR:-src/content/articles}"
DRAFTS_DIR="${DRIP_DRAFTS_DIR:-src/content/drafts}"
POSTS_DIR="${DRIP_POSTS_DIR:-$CONTENT_DIR}"
DRAFT_FIELD="${DRAFT_FIELD:-draft}"
DRAFT_RELEASE_VALUE="${DRAFT_RELEASE_VALUE:-false}"
DRAFT_HIDDEN_REGEX="${DRAFT_HIDDEN_REGEX:-^draft:[[:space:]]*true}"
DATE_FIELD="${DATE_FIELD:-pubDate}"
TEMPLATE_GLOB="${TEMPLATE_GLOB:-_TEMPLATE}"

ROOT="$(git rev-parse --show-toplevel)"
OUT="${GITHUB_OUTPUT:-/dev/stdout}"
TODAY="$(TZ="$TZNAME" date +%F)"

# Clear the frontmatter flag + stamp the publish date on a now-published file.
release_frontmatter () {
  local f="$1"
  if grep -q "^${DRAFT_FIELD}:" "$f"; then
    sed -i "s/^${DRAFT_FIELD}:.*/${DRAFT_FIELD}: ${DRAFT_RELEASE_VALUE}/" "$f"
  fi
  if grep -q "^${DATE_FIELD}:" "$f"; then
    sed -i "s/^${DATE_FIELD}:.*/${DATE_FIELD}: $TODAY/" "$f"
  fi
}

count=0
case "$MODE" in
  prefix_flag)
    ART="$ROOT/$SITE_DIR/$CONTENT_DIR"
    [ -d "$ART" ] || { echo "ERROR: content dir not found: $ART" >&2; exit 1; }
    mapfile -t drafts < <(cd "$ART" && ls _*.md 2>/dev/null | grep -v "$TEMPLATE_GLOB" \
                            | sed 's/^_//' | sort -t- -k1,1n | head -n "$BATCH")
    for base in "${drafts[@]:-}"; do
      [ -z "$base" ] && continue
      git -C "$ROOT" mv "$SITE_DIR/$CONTENT_DIR/_$base" "$SITE_DIR/$CONTENT_DIR/$base"
      release_frontmatter "$ART/$base"
      echo "released: $SITE_DIR/$CONTENT_DIR/$base  ($DATE_FIELD $TODAY)"
      count=$((count+1))
    done
    ;;
  flag)
    ART="$ROOT/$SITE_DIR/$CONTENT_DIR"
    [ -d "$ART" ] || { echo "ERROR: content dir not found: $ART" >&2; exit 1; }
    mapfile -t drafts < <(cd "$ART" && grep -ilE "$DRAFT_HIDDEN_REGEX" *.md 2>/dev/null \
                            | grep -v "$TEMPLATE_GLOB" | sort -t- -k1,1n | head -n "$BATCH")
    for base in "${drafts[@]:-}"; do
      [ -z "$base" ] && continue
      release_frontmatter "$ART/$base"
      echo "released: $SITE_DIR/$CONTENT_DIR/$base  ($DATE_FIELD $TODAY)"
      count=$((count+1))
    done
    ;;
  folder)
    D="$ROOT/$SITE_DIR/$DRAFTS_DIR"; P="$ROOT/$SITE_DIR/$POSTS_DIR"
    [ -d "$D" ] || { echo "ERROR: drafts dir not found: $D" >&2; exit 1; }
    mkdir -p "$P"
    mapfile -t drafts < <(cd "$D" && ls *.md *.html 2>/dev/null | grep -v "$TEMPLATE_GLOB" \
                            | sort -t- -k1,1n | head -n "$BATCH")
    for base in "${drafts[@]:-}"; do
      [ -z "$base" ] && continue
      git -C "$ROOT" mv "$SITE_DIR/$DRAFTS_DIR/$base" "$SITE_DIR/$POSTS_DIR/$base"
      release_frontmatter "$P/$base"
      echo "released: $SITE_DIR/$POSTS_DIR/$base  ($DATE_FIELD $TODAY)"
      count=$((count+1))
    done
    ;;
  *)
    echo "ERROR: unknown DRIP_MODE='$MODE' (use prefix_flag | flag | folder)" >&2
    exit 1
    ;;
esac

if [ "$count" -eq 0 ]; then
  echo "DONE: no drafts left for '$SITE_DIR' (backlog empty)."
fi
echo "released_count=$count" >> "$OUT"
echo "release_date=$TODAY" >> "$OUT"
