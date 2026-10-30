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
