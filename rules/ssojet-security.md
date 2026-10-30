---
trigger: model_decision
description: Apply when writing or reviewing code that handles SSOJet credentials, OIDC tokens, or SSOJet Management API calls.
---

# SSOJet security rule

- Never place `SSOJET_CLIENT_SECRET` or a Management API token in browser code, mobile code, public env variables (`NEXT_PUBLIC_*`, `VITE_*`, `REACT_APP_*`), or committed files.
- Use Authorization Code + PKCE for SPAs and mobile apps. Confidential (server) clients may use a secret, server-side only.
- Validate every `id_token`: signature via JWKS, `iss`, `aud`, `exp`, and `nonce`. Verify `state` on every callback.
- Call `https://api.ssojet.com` only from backend code. Resolve tenant context from the authenticated session, not from a client-supplied ID alone.
