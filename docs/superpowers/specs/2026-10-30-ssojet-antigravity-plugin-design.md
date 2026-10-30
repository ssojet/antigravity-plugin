# SSOJet Antigravity Plugin — Design

Date: 2026-10-30
Status: approved (brainstorm complete)

## Goal

Publish an SSOJet plugin to the Google Antigravity Marketplace, modeled on the
Auth0 plugin (`auth0/agent-skills`, `plugins/auth0`). The plugin gives the
Antigravity agent one router skill that detects the developer's intent and
framework, then loads the right SSOJet reference guides to add "Sign in with
SSO", machine-to-machine auth, or team/tenant management.

## Scope

In scope:
- One Antigravity plugin, name `ssojet`, displayName `SSOJet`, license MIT.
- One skill `ssojet` (invocable as `/ssojet`) with a router `SKILL.md` and a
  `references/` directory.
- One background rule (`rules/ssojet-security.md`, `trigger: model_decision`).
- README, MIT LICENSE, square logo, `plugin.json` manifest.
- Local validation script plus `agy plugin validate --strict` when the CLI is
  available.

Out of scope (decided 2026-10-30):
- MCP servers. SSOJet has no production MCP server to bundle.
- Custom agents, hooks.
- Per-framework standalone skills (the existing `ssojet/skills` layout).
- Marketplace submission itself (done by SSOJet via the Google intake form
  `https://forms.gle/2EX5RFYPoJe1UgxR9` after the plugin is ready).

## Repository layout

This directory is the plugin root and its own git repository. Target remote:
`https://github.com/ssojet/antigravity-plugin` (placeholder until created).

```
plugin.json
README.md
LICENSE                          MIT
assets/logo.png                  1:1, >=128x128, ~10% transparent padding
scripts/check.sh                 local structural validation
skills/ssojet/
  SKILL.md                       router
  references/
    framework-generic-oidc.md
    framework-nextjs.md
    framework-node.md
    framework-react.md
    framework-angular.md
    framework-python.md
    framework-go.md
    framework-dotnet.md
    framework-java.md
    framework-laravel.md
    framework-php.md
    framework-android.md
    framework-ios.md
    feature-m2m.md
    feature-team-management.md
    api-users.md
    api-tenants.md
    api-roles.md
    api-permissions.md
    api-team-invites.md
    api-directory-sync.md
    pattern-security.md
    pattern-common-errors.md
rules/
  ssojet-security.md
docs/superpowers/specs/          this spec and future plans
```

## plugin.json

Follows the Antigravity v1 schema. Fields: `$schema`, `name` (`ssojet`),
`displayName` (`SSOJet`), `version` (`1.0.0`), `description` (120-160 chars),
`logo` (`assets/logo.png`), `suggestedPrompts` (max 3), `author`
(`{name: "SSOJet", email: "support@ssojet.com", url: "https://ssojet.com"}`),
`homepage` (`https://docs.ssojet.com`), `repository`, `license` (`MIT`),
`keywords`. No `category` field: the published schema sets
`additionalProperties: false` at the top level.

Suggested prompts:
1. "Add Sign in with SSO to my app with SSOJet"
2. "Set up team and tenant management with SSOJet"
3. "Debug why my SSOJet login callback is failing"

## Router skill (`skills/ssojet/SKILL.md`)

Frontmatter: `name: ssojet`, `description` (what it does, when to trigger,
including "use even if the user never mentions SSOJet" for SSO/OIDC/enterprise
login/tenant management requests), `license: MIT`.

Body, target 150-250 lines:

1. **Step 1: Detect intent.** Table mapping plain-language requests to an
   intent key: `integrate`, `m2m`, `team-management`, `api:users`,
   `api:tenants`, `api:roles`, `api:permissions`, `api:team-invites`,
   `api:directory-sync`, `debug`, `guidance`. If unclear, ask; never guess.
2. **Step 2: Detect framework** (skip for `m2m`, `team-management`, `api:*`,
   `guidance`). Stop at the first tier that yields a result.
   - Tier 1: an OIDC client library already installed (`openid-client`,
     `react-oidc-context` / `oidc-client-ts`, `angular-auth-oidc-client`,
     `net.openid:appauth` (Android), `AppAuth` (Swift),
     `Microsoft.AspNetCore.Authentication.OpenIdConnect`,
     `spring-boot-starter-oauth2-client`, `laravel/socialite`,
     `jumbojett/openid-connect-php`, `coreos/go-oidc`, `authlib` / `flask`).
   - Tier 2: base framework from `package.json`, `requirements.txt` /
     `pyproject.toml`, `go.mod`, `*.csproj`, `pom.xml` / `build.gradle`,
     `composer.json`, `Package.swift` / `.xcodeproj`, `build.gradle` (Android).
   - Tier 3: ask the developer. Offer `framework-generic-oidc` if they want a
     framework-agnostic walkthrough.
3. **Step 3: Load references.** Per-intent table listing exactly which
   reference files to read. Load at most 3 per request. `integrate` loads
   `framework-<x>.md` + `pattern-security.md`; `debug` loads
   `pattern-common-errors.md` + the framework file; `team-management` loads
   `feature-team-management.md` + relevant `api-*.md`.
4. **Step 4: Execute with guardrails.** Secrets only in env vars
   (`SSOJET_CLIENT_ID`, `SSOJET_CLIENT_SECRET`, `SSOJET_ISSUER_URL`); confirm
   the callback URL is registered in the SSOJet dashboard; keep existing
   password login working; Management API calls are backend-only; WebFetch the
   linked docs page before writing API code when the reference says so.

## References

Content ported from `github.com/ssojet/skills` (15 `SKILL.md` files and 6
`apis/*.md`) with light cleanup:
- Strip skill frontmatter; add a one-line H1 and a "When to load" line.
- Unify env var names to `SSOJET_CLIENT_ID`, `SSOJET_CLIENT_SECRET`,
  `SSOJET_ISSUER_URL`, `SSOJET_REDIRECT_URI`.
- Fix broken links (for example the trailing `//` in the SSO Connection Setup
  Guide link) and drop image references that point to nonexistent files.
- Keep the "WebFetch the docs first" instructions in `api-*.md`.

Two new files written from scratch:
- `pattern-security.md`: PKCE, state/nonce, token storage per platform, secret
  handling, management token never in client code.
- `pattern-common-errors.md`: `redirect_uri` mismatch, `invalid_client`,
  `invalid_grant`, CORS on token endpoint, 401 vs 403 on Management API,
  clock skew on `id_token` validation.

## Rule (`rules/ssojet-security.md`)

```yaml
---
trigger: model_decision
description: Apply when writing or reviewing code that handles SSOJet credentials, OIDC tokens, or SSOJet Management API calls.
---
```
Body: three or four bullets. Client secret and management tokens never in
browser, mobile, or committed code; verify `id_token` signature and `aud`;
use PKCE for public clients.

## README

Marketplace-facing. Sections: what it does, install (`/plugin install
ssojet@antigravity-plugins-official`, `agy plugin install <repo-url>`, local
path), what the skill covers (table of frameworks and features), forcing with
`/ssojet`, link to docs.ssojet.com, license.

## Validation and testing

1. `scripts/check.sh` (bash, no external deps beyond `node` for JSON parsing):
   - `plugin.json` parses; required marketplace fields present; `name` matches
     `^[a-z0-9]+(-[a-z0-9]+)*$`; `suggestedPrompts` length <= 3; `logo` path
     exists.
   - Every `skills/*/SKILL.md` has frontmatter with `name` equal to its
     directory and a non-empty `description` <= 1024 chars.
   - Every `references/<file>` named in `SKILL.md` exists, and every file in
     `references/` is named in `SKILL.md`.
   - `rules/*.md` frontmatter has a valid `trigger`.
2. Schema check: fetch `https://antigravity.google/schemas/v1/plugin.json` and
   validate the manifest with `npx ajv-cli` (network required; skipped offline
   with a printed notice).
3. `agy plugin validate --strict .` then `agy plugin install .` and
   `agy plugin list --json`. The CLI is not installed on this machine; the
   implementation plan includes installing it. If install fails, the report
   states that this step was skipped.
4. Manual smoke in Antigravity: open a Next.js project, prompt "add SSO login",
   confirm `/ssojet` activates and loads `framework-nextjs.md`.

## Risks

- Antigravity plugin schema may change before submission. Mitigation: pin
  `$schema` URL and re-run validation before submitting.
- Ported reference content may contain stale SSOJet API details. Mitigation:
  keep "WebFetch docs first" steps; SSOJet team reviews references before
  submission.
