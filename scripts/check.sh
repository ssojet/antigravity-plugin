#!/usr/bin/env bash
# Structural validation for the SSOJet Antigravity plugin.
# Exit 0 = all checks pass. Prints one line per failure.
set -u
cd "$(dirname "$0")/.."
fail=0
err() { echo "FAIL: $*"; fail=1; }
ok()  { echo "ok:   $*"; }

# --- plugin.json ---------------------------------------------------------
[ -f plugin.json ] || { err "plugin.json missing"; echo "FAILED"; exit 1; }
node -e '
const m = JSON.parse(require("fs").readFileSync("plugin.json","utf8"));
const req = ["name","displayName","description","version","logo","suggestedPrompts","author","license"];
let bad = 0;
for (const k of req) if (!(k in m)) { console.log("FAIL: plugin.json missing field " + k); bad = 1; }
if (!/^[a-z0-9]+(-[a-z0-9]+)*$/.test(m.name||"")) { console.log("FAIL: plugin.json name not kebab-case: " + m.name); bad = 1; }
if (!Array.isArray(m.suggestedPrompts) || m.suggestedPrompts.length > 3) { console.log("FAIL: suggestedPrompts must be array of <=3"); bad = 1; }
if (typeof m.description !== "string" || m.description.length < 120 || m.description.length > 160) { console.log("FAIL: description length " + (m.description||"").length + " not in 120-160"); bad = 1; }
if (!require("fs").existsSync(m.logo||"")) { console.log("FAIL: logo path does not exist: " + m.logo); bad = 1; }
if ("category" in m) { console.log("FAIL: category is not in the Antigravity schema (additionalProperties=false)"); bad = 1; }
process.exit(bad);
' || fail=1
[ $fail -eq 0 ] && ok "plugin.json fields"

# --- skills ---------------------------------------------------------------
found_skill=0
for skill_md in skills/*/SKILL.md; do
  [ -f "$skill_md" ] || continue
  found_skill=1
  dir=$(basename "$(dirname "$skill_md")")
  head -1 "$skill_md" | grep -q '^---$' || err "$skill_md: no frontmatter"
  name=$(awk '/^---$/{c++; next} c==1 && /^name:/{sub(/^name:[ ]*/,""); print; exit}' "$skill_md")
  [ "$name" = "$dir" ] || err "$skill_md: name '$name' != dir '$dir'"
  desc=$(awk '/^---$/{c++; next} c==1 && /^description:/{sub(/^description:[ ]*/,""); print; exit}' "$skill_md")
  [ -n "$desc" ] || err "$skill_md: empty description"
  [ ${#desc} -le 1024 ] || err "$skill_md: description > 1024 chars"
  ok "$skill_md frontmatter"

  refdir="$(dirname "$skill_md")/references"
  if [ -d "$refdir" ]; then
    # every reference named in SKILL.md must exist
    for ref in $(grep -oE '`references/[a-z0-9-]+\.md`' "$skill_md" | tr -d '`' | sort -u); do
      [ -f "$(dirname "$skill_md")/$ref" ] || err "$skill_md names missing $ref"
    done
    # every reference file must be named in SKILL.md
    for f in "$refdir"/*.md; do
      base="references/$(basename "$f")"
      grep -q "\`$base\`" "$skill_md" || err "$base not referenced from $skill_md"
      head -1 "$f" | grep -q '^# ' || err "$f: first line must be an H1"
    done
    ok "$refdir cross-references"
  fi
done
[ $found_skill -eq 1 ] || err "no skills/*/SKILL.md found"

# --- rules -----------------------------------------------------------------
for rule in rules/*.md; do
  [ -f "$rule" ] || continue
  [ "$(basename "$rule")" = "AGENTS.md" ] && continue
  trig=$(awk '/^---$/{c++; next} c==1 && /^trigger:/{sub(/^trigger:[ ]*/,""); print; exit}' "$rule")
  case "$trig" in
    always_on|model_decision|glob|manual) ok "$rule trigger=$trig" ;;
    *) err "$rule: invalid trigger '$trig'" ;;
  esac
  if [ "$trig" = "model_decision" ]; then
    grep -q '^description:' "$rule" || err "$rule: model_decision requires description"
  fi
done

# --- stale content --------------------------------------------------------
grep -rn 'integrations//' skills rules README.md 2>/dev/null && err "double-slash docs link found"
grep -rn 'ssojet-applications-stepX' skills 2>/dev/null && err "placeholder image reference found"
grep -rln 'TODO\|TBD' skills rules 2>/dev/null && err "TODO/TBD found"

# --- README / LICENSE -----------------------------------------------------
[ -f README.md ] || err "README.md missing"
[ -f LICENSE ] || err "LICENSE missing"

if [ $fail -eq 0 ]; then echo "ALL CHECKS PASSED"; else echo "FAILED"; fi
exit $fail
