# SSOJet Antigravity Plugin Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a validated, marketplace-ready Antigravity plugin `ssojet` containing one router skill, ported reference guides, a security rule, README, logo, and manifest.

**Architecture:** Plugin root is this repo. `plugin.json` is the Antigravity v1 manifest. `skills/ssojet/SKILL.md` routes intent and framework to 2-3 files in `skills/ssojet/references/`. References are ported from `github.com/ssojet/skills` (already cloned at `SRC` below) with scripted cleanup. `scripts/check.sh` is the structural test suite and is written before the content it checks.

**Tech Stack:** Markdown, JSON, bash, node (JSON parsing only), `npx ajv-cli` (schema check), Antigravity CLI `agy`.

**Spec:** `docs/superpowers/specs/2026-10-30-ssojet-antigravity-plugin-design.md`

**Paths used throughout:**
- `ROOT=/Users/vijay/Work/Identity/ssojet/extension/antigravity/ssojet-auth`
- `SRC=/private/tmp/claude-501/-Users-vijay-Work-Identity-ssojet-extension-antigravity-ssojet-auth/57af4a80-76e1-4b48-919d-21dcbd67982a/scratchpad/repos/ssojet-skills/skills` (clone of `github.com/ssojet/skills`; if missing, re-clone: `git clone --depth 1 https://github.com/ssojet/skills.git` and point `SRC` at its `skills/` dir)
- `LOGO_SRC=/Users/vijay/Work/Identity/ssojet/b-auth-corp-website/dist/icons/icon-512.png` (512x512 PNG)

Commit with: `git -c user.name="Vijay" -c user.email="sanakee01@gmail.com" commit -m "..."` and end every message with `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>`.

---

### Task 1: Structural check script (the test suite)

**Files:**
- Create: `scripts/check.sh`

- [ ] **Step 1: Write the check script**

```bash
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
```

- [ ] **Step 2: Make executable and run; expect failure (nothing exists yet)**

Run: `chmod +x scripts/check.sh && ./scripts/check.sh`
Expected: `FAIL: plugin.json missing` then `FAILED`, exit code 1.

- [ ] **Step 3: Commit**

```bash
git add scripts/check.sh
git commit -m "test: add structural check script for plugin"
```

---

### Task 2: Scaffold manifest, license, logo, gitignore

**Files:**
- Create: `plugin.json`, `LICENSE`, `.gitignore`, `assets/logo.png`

- [ ] **Step 1: Write `.gitignore`**

```
.DS_Store
node_modules/
```

- [ ] **Step 2: Write `LICENSE` (MIT)**

```
MIT License

Copyright (c) 2026 SSOJet

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

- [ ] **Step 3: Copy logo**

Run:
```bash
mkdir -p assets
cp "$LOGO_SRC" assets/logo.png
sips -g pixelWidth -g pixelHeight assets/logo.png
```
Expected: `pixelWidth: 512`, `pixelHeight: 512`. Open `assets/logo.png` (Read tool) and confirm the mark has visible padding around it and is legible on dark and light backgrounds. If padding is under ~10%, pad with:
```bash
python3 -c "
from PIL import Image
im=Image.open('assets/logo.png').convert('RGBA'); s=im.width; pad=int(s*0.12)
out=Image.new('RGBA',(s+2*pad,s+2*pad),(0,0,0,0)); out.paste(im,(pad,pad)); out.save('assets/logo.png')"
```
(If Pillow is missing: `python3 -m pip install --user pillow`.)

- [ ] **Step 4: Write `plugin.json`**

```json
{
  "$schema": "https://antigravity.google/schemas/v1/plugin.json",
  "name": "ssojet",
  "displayName": "SSOJet",
  "version": "1.0.0",
  "description": "Add enterprise SSO login, machine-to-machine auth, and team management to any app with SSOJet. Covers Next.js, React, Node, Python, Go, .NET, Java, PHP, and mobile.",
  "logo": "assets/logo.png",
  "suggestedPrompts": [
    "Add Sign in with SSO to my app with SSOJet",
    "Set up team and tenant management with SSOJet",
    "Debug why my SSOJet login callback is failing"
  ],
  "author": {
    "name": "SSOJet",
    "email": "support@ssojet.com",
    "url": "https://ssojet.com"
  },
  "homepage": "https://docs.ssojet.com",
  "repository": "https://github.com/ssojet/antigravity-plugin",
  "license": "MIT",
  "keywords": [
    "ssojet",
    "sso",
    "oidc",
    "oauth",
    "authentication",
    "enterprise-sso",
    "saml",
    "scim",
    "team-management",
    "multi-tenant",
    "b2b",
    "nextjs",
    "react",
    "angular",
    "node",
    "express",
    "python",
    "flask",
    "go",
    "dotnet",
    "java",
    "springboot",
    "laravel",
    "php",
    "android",
    "ios"
  ]
}
```

- [ ] **Step 5: Verify description length is 120-160**

Run: `node -e 'console.log(JSON.parse(require("fs").readFileSync("plugin.json")).description.length)'`
Expected: a number between 120 and 160 (the text above is 154). Adjust wording if not.

- [ ] **Step 6: Run check; expect only skill/README/LICENSE-stage failures**

Run: `./scripts/check.sh`
Expected: `ok:   plugin.json fields`, then `FAIL: no skills/*/SKILL.md found`, `FAIL: README.md missing`. No plugin.json failures.

- [ ] **Step 7: Commit**

```bash
git add .gitignore LICENSE assets/logo.png plugin.json
git commit -m "feat: scaffold plugin manifest, license, and logo"
```

---

### Task 3: Port framework and API references

**Files:**
- Create: `skills/ssojet/references/framework-*.md` (13 files), `feature-m2m.md`, `feature-team-management.md`, `api-*.md` (6 files)

- [ ] **Step 1: Run the port script (one-off, not committed)**

```bash
cd "$ROOT"
mkdir -p skills/ssojet/references
R=skills/ssojet/references

# strip YAML frontmatter, fix links, drop placeholder image lines
port() { # port <src> <dest> <H1 title> <load-for line>
  {
    printf '# %s\n\n> **Load for:** %s\n\n' "$3" "$4"
    awk 'NR==1 && /^---$/ {fm=1; next} fm==1 && /^---$/ {fm=0; next} fm==1 {next} {print}' "$1"
  } \
  | sed 's#https://docs.ssojet.com/en/how-to-guides/integrations//#https://docs.ssojet.com/en/how-to-guides/integrations/#g' \
  | grep -v 'ssojet-applications-stepX' \
  | sed -E 's/^# (Implement|SSOJet) .*$//; 1!{/^$/N;/^\n$/D}' \
  > "$2"
}

A=$SRC/authentication
port $A/oidc-hosted-page/SKILL.md          $R/framework-generic-oidc.md "SSOJet OIDC: framework-agnostic flow"        "intent integrate when no framework file matches, or when the developer wants the raw OIDC flow"
port $A/oidc-hosted-page-nextjs/SKILL.md   $R/framework-nextjs.md       "SSOJet OIDC for Next.js (App Router)"       "intent integrate, framework nextjs"
port $A/oidc-hosted-page-node/SKILL.md     $R/framework-node.md         "SSOJet OIDC for Node.js / Express"          "intent integrate, framework node"
port $A/oidc-hosted-page-react/SKILL.md    $R/framework-react.md        "SSOJet OIDC for React SPA (PKCE)"           "intent integrate, framework react"
port $A/oidc-hosted-page-angular/SKILL.md  $R/framework-angular.md      "SSOJet OIDC for Angular SPA (PKCE)"         "intent integrate, framework angular"
port $A/oidc-hosted-page-python/SKILL.md   $R/framework-python.md       "SSOJet OIDC for Python / Flask"             "intent integrate, framework python"
port $A/oidc-hosted-page-go/SKILL.md       $R/framework-go.md           "SSOJet OIDC for Go"                         "intent integrate, framework go"
port $A/oidc-hosted-page-dotnet/SKILL.md   $R/framework-dotnet.md       "SSOJet OIDC for ASP.NET Core"               "intent integrate, framework dotnet"
port $A/oidc-hosted-page-java/SKILL.md     $R/framework-java.md         "SSOJet OIDC for Java Spring Boot"           "intent integrate, framework java"
port $A/oidc-hosted-page-laravel/SKILL.md  $R/framework-laravel.md      "SSOJet OIDC for Laravel (Socialite)"        "intent integrate, framework laravel"
port $A/oidc-hosted-page-php/SKILL.md      $R/framework-php.md          "SSOJet OIDC for vanilla PHP"                "intent integrate, framework php"
port $A/oidc-hosted-page-android/SKILL.md  $R/framework-android.md      "SSOJet OIDC for Android (AppAuth)"          "intent integrate, framework android"
port $A/oidc-hosted-page-ios/SKILL.md      $R/framework-ios.md          "SSOJet OIDC for iOS / Swift (AppAuth)"      "intent integrate, framework ios"
port $A/m2m-client-credentials/SKILL.md    $R/feature-m2m.md            "SSOJet machine-to-machine (client credentials)" "intent m2m"
port $SRC/management/team-management/SKILL.md $R/feature-team-management.md "SSOJet team and tenant management"      "intent team-management"

P=$SRC/apis
port $P/users.md          $R/api-users.md          "SSOJet Users API"            "intent api:users, or team-management when touching users"
port $P/tenants.md        $R/api-tenants.md        "SSOJet Tenants API"          "intent api:tenants, or team-management when creating or listing tenants"
port $P/roles.md          $R/api-roles.md          "SSOJet Roles API"            "intent api:roles, or team-management when assigning roles"
port $P/permissions.md    $R/api-permissions.md    "SSOJet Permissions API"      "intent api:permissions"
port $P/team-invites.md   $R/api-team-invites.md   "SSOJet Team Invites API"     "intent api:team-invites, or team-management when inviting members"
port $P/directory-sync.md $R/api-directory-sync.md "SSOJet Directory Sync (SCIM) API" "intent api:directory-sync"

# unify env var names in the Next.js guide (other guides already use SSOJET_* or native constants)
perl -pi -e 's/(?<!SSOJET_)(?<!YOUR_)\b(CLIENT_ID|CLIENT_SECRET|ISSUER_URL|REDIRECT_URI)\b/SSOJET_$1/g' $R/framework-nextjs.md

ls $R | wc -l
```
Expected: `21`.

- [ ] **Step 2: Spot-check three ported files**

Run: `head -12 skills/ssojet/references/framework-nextjs.md; grep -c SSOJET_ skills/ssojet/references/framework-nextjs.md; head -8 skills/ssojet/references/api-users.md`
Expected: each file starts with `# <title>` then the `> **Load for:**` line, no `---` frontmatter, no leftover `# Implement ...` H1 duplicate, and nextjs shows `SSOJET_ISSUER_URL`, `SSOJET_CLIENT_SECRET`.

- [ ] **Step 3: Grep for leftovers**

Run: `grep -rn 'integrations//\|stepX\|^---$' skills/ssojet/references | head`
Expected: no output.

- [ ] **Step 4: Commit**

```bash
git add skills/ssojet/references
git commit -m "feat: port SSOJet framework, feature, and API references"
```

---

### Task 4: Write security and common-errors pattern references

**Files:**
- Create: `skills/ssojet/references/pattern-security.md`, `skills/ssojet/references/pattern-common-errors.md`

- [ ] **Step 1: Write `pattern-security.md`**

```markdown
# SSOJet security patterns

> **Load for:** every `integrate` request, every `guidance` request, and whenever code touches secrets or tokens

## Secrets

- `SSOJET_CLIENT_SECRET` and any Management API access token live only in server-side environment variables or a secrets manager. Never in browser bundles, mobile binaries, `NEXT_PUBLIC_*` / `VITE_*` / `REACT_APP_*` variables, or committed files.
- Public clients (React, Angular, Android, iOS) have no client secret. They use Authorization Code + PKCE.
- Add `.env`, `.env.local`, and equivalents to `.gitignore` before writing credentials.

## Authorization Code flow hygiene

- Always send `state` and verify it on callback. Store it in the session (server) or `sessionStorage` (SPA).
- Always send `nonce` and verify it inside the `id_token`.
- Use PKCE (`code_challenge_method=S256`) for all public clients, and for confidential clients when the library supports it.
- Register the exact `redirect_uri` in the SSOJet dashboard. Match scheme, host, port, and path exactly.

## Token validation

- Validate `id_token` with the issuer's JWKS (from `${SSOJET_ISSUER_URL}/.well-known/openid-configuration`). Check `iss`, `aud` (= client ID), `exp`, `nonce`.
- Prefer library validation (`openid-client`, `go-oidc`, `authlib`, Spring Security, ASP.NET OIDC middleware) over hand-rolled JWT parsing.
- Allow 60 seconds clock skew at most.

## Token storage

| Platform | Store |
|---|---|
| Server-rendered web (Next.js, Express, Flask, Spring, ASP.NET, Laravel, PHP) | Server session, `HttpOnly; Secure; SameSite=Lax` cookie |
| SPA (React, Angular) | Memory first; `sessionStorage` if persistence needed. Never `localStorage` for refresh tokens |
| Android | `EncryptedSharedPreferences` or Keystore-backed storage |
| iOS | Keychain |

## Management API

- Call `https://api.ssojet.com/api/v1/...` only from backend code.
- Scope management tokens narrowly and keep them short-lived.
- Resolve tenant context from the authenticated user, never from a client-supplied ID alone.

## Logout

- Clear the local session, then redirect to the SSOJet `end_session_endpoint` with `post_logout_redirect_uri` registered in the dashboard.
```

- [ ] **Step 2: Write `pattern-common-errors.md`**

```markdown
# SSOJet common errors and fixes

> **Load for:** intent `debug`, together with the matching `framework-*.md`

Work top-down. Ask the developer for the exact error string and the URL in the browser bar when the error appears.

| Symptom | Cause | Fix |
|---|---|---|
| `redirect_uri_mismatch` / `invalid_redirect_uri` | Callback URL in code differs from the one registered in SSOJet dashboard (scheme, host, port, trailing slash) | Copy the exact URL from code into **Applications → your app → Redirect URIs**. Check `http` vs `https` and `localhost` vs `127.0.0.1`. |
| `invalid_client` | Wrong `client_id` or `client_secret`, or secret sent from a public client | Re-copy credentials from dashboard. Public clients must use PKCE with no secret. |
| `invalid_grant` on token exchange | Code already used, expired (>60s), or PKCE verifier does not match challenge | Ensure the callback handler runs once (React StrictMode double-invokes effects in dev). Persist `code_verifier` across the redirect. |
| `state` mismatch | State lost between redirect and callback | Server: session cookie not set (check `Secure` on http localhost, `SameSite`). SPA: using `localStorage` cleared or a different origin. |
| `nonce` mismatch / `id_token` rejected | Nonce not persisted, or clock skew | Persist nonce like state. Sync system clock; allow <=60s skew. |
| CORS error calling `/token` from browser | Token endpoint called directly from SPA with secret | SPAs must use PKCE through the OIDC library. Server-side apps exchange the code on the server. |
| Discovery fails (`.well-known/openid-configuration` 404) | Wrong `SSOJET_ISSUER_URL` | Copy Issuer URL from **Applications → Advanced → Endpoints**. No trailing slash. |
| `401 Unauthorized` from Management API | Missing or expired bearer token, or missing `client_id` query parameter | Fetch a fresh token via client credentials (`feature-m2m.md`); include `client_id` as the API reference shows. |
| `403 Forbidden` from Management API | Token lacks permission for the tenant or resource | Check role and permission assignment (`api-roles.md`, `api-permissions.md`). |
| User lands on SSOJet login, then loops back to login | Session not persisted after callback | Confirm the callback sets the session before redirecting; check cookie domain and `SameSite`. |
| Enterprise user sees "no connection found" | No SSO connection configured for the user's email domain | Configure the IdP connection: https://docs.ssojet.com/en/how-to-guides/integrations/ |

If none match, WebFetch https://docs.ssojet.com and search for the error string before guessing.
```

- [ ] **Step 3: Commit**

```bash
git add skills/ssojet/references/pattern-security.md skills/ssojet/references/pattern-common-errors.md
git commit -m "feat: add security and common-errors pattern references"
```

---

### Task 5: Router skill `SKILL.md`

**Files:**
- Create: `skills/ssojet/SKILL.md`

- [ ] **Step 1: Write the router**

```markdown
---
name: ssojet
description: Use when adding, fixing, or improving how an app signs users in with SSO or OIDC, protects a backend with machine-to-machine tokens, or manages teams, tenants, roles, invitations, and directory sync (SCIM) — or when using or configuring any SSOJet feature or API. Covers Next.js, React, Angular, Node/Express, Python/Flask, Go, ASP.NET Core, Spring Boot, Laravel, PHP, Android, and iOS. Also use to debug login or callback failures and for auth security guidance. Use even if the user never mentions SSOJet when they ask for enterprise SSO, "Sign in with SSO", B2B tenant management, or SCIM.
license: MIT
---

# SSOJet

Detect intent → detect framework → load 2–3 reference files → implement with guardrails.

Reference files live in `references/`. Read only the files this router names. Never load all of them.

---

## Step 1: Detect intent

| What the developer wants | Intent |
|---|---|
| Add "Sign in with SSO", enterprise login, OIDC login, or an SSO button next to existing email/password login | **integrate** |
| A backend service, cron job, CLI, or API calling SSOJet or an SSOJet-protected API with no user present. *Client credentials, M2M, service account.* | **m2m** |
| Build B2B team or organization features: create tenants, invite members, assign roles, let one user belong to many orgs | **team-management** |
| Create, list, update, or delete users via API | **api:users** |
| Create, list, or manage tenants or organizations via API | **api:tenants** |
| Create or assign roles via API | **api:roles** |
| Define or check permissions via API | **api:permissions** |
| Send, list, or revoke team invitations via API | **api:team-invites** |
| SCIM provisioning, directory sync, auto-provision users from an IdP | **api:directory-sync** |
| Login fails: redirect loop, `redirect_uri_mismatch`, `invalid_client`, `invalid_grant`, state or nonce error, CORS on token endpoint, 401/403 from the API | **debug** |
| "Is this secure?", where to store tokens, how to handle secrets, best practices | **guidance** |

If the request fits two intents (for example "add SSO login and then team management"), handle **integrate** first, then the second intent as a follow-up.

If nothing clearly matches, ask the developer what they are trying to accomplish. Do not guess.

---

## Step 2: Detect framework

Skip this step for **m2m**, **team-management**, **api:\***, and **guidance**. Those references are language-agnostic.

Work top-down. Stop at the first tier that yields a framework.

### Tier 1 — an OIDC client library is already installed

| Signal (file → dependency) | Framework |
|---|---|
| `package.json` → `next` + `openid-client` | `nextjs` |
| `package.json` → `react-oidc-context` or `oidc-client-ts` | `react` |
| `package.json` → `angular-auth-oidc-client` | `angular` |
| `package.json` → `express` + `openid-client` | `node` |
| `requirements.txt` / `pyproject.toml` → `authlib` | `python` |
| `go.mod` → `github.com/coreos/go-oidc` | `go` |
| `*.csproj` → `Microsoft.AspNetCore.Authentication.OpenIdConnect` | `dotnet` |
| `pom.xml` / `build.gradle` → `spring-boot-starter-oauth2-client` | `java` |
| `composer.json` → `laravel/socialite` | `laravel` |
| `composer.json` → `jumbojett/openid-connect-php` | `php` |
| `build.gradle(.kts)` → `net.openid:appauth` | `android` |
| `Podfile` / `Package.swift` → `AppAuth` | `ios` |

### Tier 2 — base framework from ordinary dependencies

| Signal | Framework |
|---|---|
| `package.json` → `next` | `nextjs` |
| `package.json` → `@angular/core` | `angular` |
| `package.json` → `react` (no `next`) | `react` |
| `package.json` → `express`, `fastify`, `koa`, or `hono` (no `react`, no `next`) | `node` |
| `requirements.txt` / `pyproject.toml` → `flask`, `fastapi`, or `django` | `python` |
| `go.mod` present | `go` |
| `*.csproj` present | `dotnet` |
| `pom.xml` or `build.gradle` with `spring-boot` | `java` |
| `composer.json` → `laravel/framework` | `laravel` |
| `composer.json` present (no Laravel) | `php` |
| `build.gradle` + `AndroidManifest.xml` | `android` |
| `*.xcodeproj` or `Package.swift` with UIKit/SwiftUI | `ios` |

Node variants: `node` reference uses Express. For Fastify, Koa, or Hono, apply the same `openid-client` flow and adapt the route handlers. Python variants: `python` reference uses Flask. For FastAPI or Django, keep `authlib` and adapt the route layer.

### Tier 3 — ask

If no tier matches, ask: "Which framework is this app built with?" Offer `framework-generic-oidc` if the developer wants a framework-agnostic walkthrough.

---

## Step 3: Load references

Load at most three files. Read them fully before writing code.

### integrate
- `references/framework-<framework>.md` where `<framework>` is the Step 2 result:
  `references/framework-nextjs.md`, `references/framework-react.md`, `references/framework-angular.md`, `references/framework-node.md`, `references/framework-python.md`, `references/framework-go.md`, `references/framework-dotnet.md`, `references/framework-java.md`, `references/framework-laravel.md`, `references/framework-php.md`, `references/framework-android.md`, `references/framework-ios.md`, or `references/framework-generic-oidc.md`
- `references/pattern-security.md`

### m2m
- `references/feature-m2m.md`
- `references/pattern-security.md`

### team-management
- `references/feature-team-management.md`
- Then the one or two `api-*.md` files the task touches: `references/api-tenants.md`, `references/api-team-invites.md`, `references/api-roles.md`, `references/api-users.md`

### api:users → `references/api-users.md`
### api:tenants → `references/api-tenants.md`
### api:roles → `references/api-roles.md`
### api:permissions → `references/api-permissions.md`
### api:team-invites → `references/api-team-invites.md`
### api:directory-sync → `references/api-directory-sync.md`

For any `api:*` intent also load `references/feature-m2m.md` if the project has no Management API token helper yet.

### debug
- `references/pattern-common-errors.md`
- `references/framework-<framework>.md` for the detected framework

### guidance
- `references/pattern-security.md`
- `references/pattern-common-errors.md` if the question is about a failure

---

## Step 4: Implement with guardrails

1. **Credentials.** Read `SSOJET_CLIENT_ID`, `SSOJET_CLIENT_SECRET`, `SSOJET_ISSUER_URL`, `SSOJET_REDIRECT_URI` from environment variables. Create a `.env.example` with placeholder values. Never commit real values. Public clients (React, Angular, Android, iOS) get no secret.
2. **Dashboard setup.** Before writing code, tell the developer which values to create or copy in the SSOJet dashboard: application type, redirect URI, client ID, issuer URL (**Applications → Advanced → Endpoints**). Confirm the redirect URI in code matches the dashboard exactly.
3. **Do not break existing login.** Add SSO alongside the current email/password flow. Do not remove existing auth routes unless asked.
4. **Backend only for management.** Management API calls (`api-*.md`) run on the server. Never expose a management token to a browser or mobile client.
5. **Fetch docs when told.** `api-*.md` files begin with a "WebFetch the docs first" step. Do it. The API reference files are summaries; the live docs are authoritative.
6. **Verify.** After implementing, list the manual test: start the app, click Sign in with SSO, complete login on the SSOJet hosted page, confirm the callback sets a session and the user lands on the intended page. Run the project's existing tests.

## Forcing this skill

If auto-detection misses, the developer can type `/ssojet <request>`.
```

- [ ] **Step 2: Run the check script**

Run: `./scripts/check.sh`
Expected: `ok:   skills/ssojet/SKILL.md frontmatter`, `ok:   skills/ssojet/references cross-references`, no `FAIL:` lines about references. Remaining failures: `README.md missing` only. If a reference file is reported as unreferenced, add it to Step 3 of SKILL.md; if SKILL.md names a missing file, fix the name.

- [ ] **Step 3: Commit**

```bash
git add skills/ssojet/SKILL.md
git commit -m "feat: add ssojet router skill"
```

---

### Task 6: Security rule

**Files:**
- Create: `rules/ssojet-security.md`

- [ ] **Step 1: Write the rule**

```markdown
---
trigger: model_decision
description: Apply when writing or reviewing code that handles SSOJet credentials, OIDC tokens, or SSOJet Management API calls.
---

# SSOJet security rule

- Never place `SSOJET_CLIENT_SECRET` or a Management API token in browser code, mobile code, public env variables (`NEXT_PUBLIC_*`, `VITE_*`, `REACT_APP_*`), or committed files.
- Use Authorization Code + PKCE for SPAs and mobile apps. Confidential (server) clients may use a secret, server-side only.
- Validate every `id_token`: signature via JWKS, `iss`, `aud`, `exp`, and `nonce`. Verify `state` on every callback.
- Call `https://api.ssojet.com` only from backend code. Resolve tenant context from the authenticated session, not from a client-supplied ID alone.
```

- [ ] **Step 2: Run the check script**

Run: `./scripts/check.sh`
Expected: `ok:   rules/ssojet-security.md trigger=model_decision`.

- [ ] **Step 3: Commit**

```bash
git add rules/ssojet-security.md
git commit -m "feat: add SSOJet security rule"
```

---

### Task 7: README

**Files:**
- Create: `README.md`

- [ ] **Step 1: Write README**

```markdown
# SSOJet for Antigravity

Add enterprise SSO login, machine-to-machine authentication, and B2B team management to any app with [SSOJet](https://ssojet.com). One skill detects your framework and loads the right implementation guide.

## Install

From the Antigravity Marketplace (App: **Customizations → Marketplace**, or CLI):

```
/plugin install ssojet@antigravity-plugins-official
```

From source:

```bash
agy plugin install https://github.com/ssojet/antigravity-plugin
# or a local clone
agy plugin install ./antigravity-plugin
```

No credentials or MCP servers are required to install. You add your own SSOJet client ID, secret, and issuer URL to your app's environment when you integrate.

## What it does

Ask in plain language, for example:

- "Add Sign in with SSO to my Next.js app"
- "Set up team and tenant management with SSOJet"
- "Debug why my SSOJet login callback is failing"

The `ssojet` skill detects intent and framework, then loads two or three focused reference guides.

| Area | Coverage |
|---|---|
| Sign in with SSO (OIDC Authorization Code) | Next.js, React, Angular, Node/Express, Python/Flask, Go, ASP.NET Core, Spring Boot, Laravel, PHP, Android, iOS, generic OIDC |
| Machine-to-machine | OAuth2 client credentials for services, CLIs, and jobs |
| Team management | Tenants, members, roles, invitations, multi-org users |
| Management API | Users, tenants, roles, permissions, team invites, directory sync (SCIM) |
| Debugging | Redirect URI mismatch, invalid client/grant, state and nonce errors, CORS, 401/403 |
| Security | PKCE, token storage per platform, secret handling, token validation |

A background rule reminds the agent to keep client secrets and management tokens server-side whenever it writes auth code.

## Forcing the skill

If the agent does not pick the skill up automatically, name it:

```
/ssojet add SSO login to this Flask app
```

## Links

- Docs: https://docs.ssojet.com
- API reference: https://api-docs.ssojet.com
- Source skills: https://github.com/ssojet/skills

## License

MIT
```

- [ ] **Step 2: Run the check script; expect all pass**

Run: `./scripts/check.sh`
Expected: last line `ALL CHECKS PASSED`, exit 0.

- [ ] **Step 3: Commit**

```bash
git add README.md
git commit -m "docs: add marketplace README"
```

---

### Task 8: Schema validation against the published Antigravity schema

**Files:** none created (scratch only)

- [ ] **Step 1: Fetch the schema**

Run:
```bash
S=/private/tmp/claude-501/-Users-vijay-Work-Identity-ssojet-extension-antigravity-ssojet-auth/57af4a80-76e1-4b48-919d-21dcbd67982a/scratchpad
curl -fsSL https://antigravity.google/schemas/v1/plugin.json -o $S/plugin.schema.json && head -c 400 $S/plugin.schema.json
```
Expected: JSON beginning with `{"$schema"` or `{"$id"`. If `curl` fails (404 or network), print `SCHEMA CHECK SKIPPED: <reason>` and continue to Task 9.

- [ ] **Step 2: Validate**

Run:
```bash
npx --yes ajv-cli@5 validate -s $S/plugin.schema.json -d plugin.json --spec=draft2020 2>&1 | tail -5
```
Expected: `plugin.json valid`. If the schema uses draft-07, drop `--spec=draft2020`. If `additionalProperties` errors name a field, remove that field from `plugin.json`, re-run `./scripts/check.sh`, commit with `fix: align plugin.json with published schema`.

---

### Task 9: Official validation with `agy` and local install smoke test

**Files:** none created

- [ ] **Step 1: Confirm `agy` is installed**

Run: `which agy && agy --version`
Expected: a path and a version. If missing: `brew install --cask antigravity-cli` (already approved), then re-check. If install fails, print `AGY STEPS SKIPPED: <error>` and go to Task 10; report this in the final summary.

- [ ] **Step 2: Strict validate**

Run: `agy plugin validate --strict .`
Expected: success with zero errors and zero warnings. For each warning or error, fix the file it names, re-run `./scripts/check.sh`, re-run validate, commit as `fix: <what>`.

- [ ] **Step 3: Install locally and list**

Run:
```bash
agy plugin install .
agy plugin list --json | node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>{const j=JSON.parse(s);console.log(JSON.stringify(j,null,1).slice(0,1500))})'
```
Expected: an entry with `"name": "ssojet"` listing one skill `ssojet` and one rule. If the plugin shows as disabled, that indicates a variables/MCP config problem; this plugin has none, so investigate the validate output.

- [ ] **Step 4: Uninstall the local copy**

Run: `agy plugin uninstall ssojet`
Expected: success. (Keeps the machine clean; the user reinstalls from the marketplace later.)

---

### Task 10: Final review and handoff notes

**Files:**
- Modify: `README.md` only if Task 8/9 forced manifest changes that affect install text

- [ ] **Step 1: Full check**

Run: `./scripts/check.sh && git status --short`
Expected: `ALL CHECKS PASSED` and a clean tree.

- [ ] **Step 2: Tree review**

Run: `find . -type f -not -path './.git/*' | sort`
Expected exactly:
```
./.gitignore
./LICENSE
./README.md
./assets/logo.png
./docs/superpowers/plans/2026-10-30-ssojet-antigravity-plugin.md
./docs/superpowers/specs/2026-10-30-ssojet-antigravity-plugin-design.md
./plugin.json
./rules/ssojet-security.md
./scripts/check.sh
./skills/ssojet/SKILL.md
./skills/ssojet/references/api-directory-sync.md
./skills/ssojet/references/api-permissions.md
./skills/ssojet/references/api-roles.md
./skills/ssojet/references/api-team-invites.md
./skills/ssojet/references/api-tenants.md
./skills/ssojet/references/api-users.md
./skills/ssojet/references/feature-m2m.md
./skills/ssojet/references/feature-team-management.md
./skills/ssojet/references/framework-android.md
./skills/ssojet/references/framework-angular.md
./skills/ssojet/references/framework-dotnet.md
./skills/ssojet/references/framework-generic-oidc.md
./skills/ssojet/references/framework-go.md
./skills/ssojet/references/framework-ios.md
./skills/ssojet/references/framework-java.md
./skills/ssojet/references/framework-laravel.md
./skills/ssojet/references/framework-nextjs.md
./skills/ssojet/references/framework-node.md
./skills/ssojet/references/framework-php.md
./skills/ssojet/references/framework-python.md
./skills/ssojet/references/framework-react.md
./skills/ssojet/references/pattern-common-errors.md
./skills/ssojet/references/pattern-security.md
```

- [ ] **Step 3: Commit the plan (if not yet committed) and report**

```bash
git add docs/superpowers/plans
git commit -m "docs: add implementation plan"
git log --oneline
```

Report to the user: what passed (check.sh, schema, agy validate), what was skipped and why, and the two remaining manual steps that only SSOJet can do: create `github.com/ssojet/antigravity-plugin` and push, then submit via https://forms.gle/2EX5RFYPoJe1UgxR9.
