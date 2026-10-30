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
