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
