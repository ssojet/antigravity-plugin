# SSOJet Team Invites API

> **Load for:** intent api:team-invites, or team-management when inviting members

## Step 1: Fetch Documentation
**STOP. WebFetch the relevant docs for latest implementation details before proceeding.**

- [List Team Invitations](https://api.ssojet.com/api/v1/tenants/{tenantid}/invitations)
- [Invite Team Member](https://api.ssojet.com/api/v1/tenants/{tenantid}/invitations)
- [Revoke Invitation](https://api.ssojet.com/api/v1/tenants/{tenantid}/invitations)
- [Resend Invitation](https://api.ssojet.com/api/v1/tenants/{tenantid}/invitations/resend)

## Operation Decision Tree
```
Need to manage team invites?
├─ Inviting a new member → POST /tenants/{tenantid}/invitations
├─ Listing all invites → GET /tenants/{tenantid}/invitations
├─ Revoking an invite → DELETE /tenants/{tenantid}/invitations?invitation_id={id}
└─ Resending an invite → POST /tenants/{tenantid}/invitations/resend
```

## Authentication Setup
All API requests require a Bearer token and a Client ID.

**Headers:**
```bash
Authorization: Bearer <your_access_token>
```

**Query Parameters:**
```bash
client_id=<your_client_id>
```

## Endpoint Catalog
| Method | Endpoint | Purpose |
| ------ | -------- | ------- |
| GET | `/auth/tenants/{tenantid}/users` | List tenant members using User Access Token |
| GET | `/tenants/{tenantid}/invitations` | List and filter team invitations |
| POST | `/tenants/{tenantid}/invitations` | Create and send a new invitation |
| DELETE | `/tenants/{tenantid}/invitations` | Revoke a pending invitation |
| DELETE | `/tenants/{tenantid}/users` | Remove active members from a tenant |
| POST | `/tenants/{tenantid}/invitations/resend` | Resend an existing invitation |

## Request/Response Patterns

### Invite Team Member
**Request:**

```bash
curl -X POST "https://api.ssojet.com/api/v1/tenants/tenant_123/invitations?client_id=${CLIENT_ID}" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "invitee": {
      "email": "new.member@acme.com",
      "first_name": "New",
      "last_name": "Member"
    },
    "inviter": {
      "email": "admin@acme.com",
      "first_name": "Admin",
      "last_name": "User"
    },
    "role_ids": ["role_admin"],
    "expire_in_minutes": 1440,
    "description": "Welcome to the team!",
    "send_invitation_email": true
  }'
```

**Response (201 Created):**

```json
{
  "invitee": {
    "email": "new.member@acme.com",
    "first_name": "New",
    "last_name": "Member"
  },
  "role_ids": ["role_admin"],
  "created_at": "2024-01-01T12:00:00Z",
  "expire_in_minutes": 1440
}
```

### List Invitations
**Request:**

```bash
curl "https://api.ssojet.com/api/v1/tenants/tenant_123/invitations?client_id=${CLIENT_ID}&status=pending&limit=10" \
  -H "Authorization: Bearer ${MANAGEMENT_TOKEN}"
```

**Response (200 OK):**

```json
{
  "limit": 10,
  "next_cursor": "",
  "invitation": [
    {
      "id": "inv_12345",
      "status": "pending",
      "email": "new.member@acme.com",
      "roles": [
        {
          "role_id": "role_admin",
          "role_name": "Admin"
        }
      ],
      "created_at": "2024-01-01T12:00:00Z"
    }
  ]
}
```

### Fetch Users of a Tenant (Team Listing)
**Request (Using User Access Token):**

```bash
curl "https://api.ssojet.com/api/v1/auth/tenants/tenant_123/users?client_id=${CLIENT_ID}" \
  -H "Authorization: Bearer ${USER_ACCESS_TOKEN}"
```

**Response (200 OK):**

```json
{
    "limit": 10,
    "next_cursor": "",
    "users": [
        {
            "id": "66c4dfbde1cb5f47418fcb27",
            "email": "admin@acme.com",
            "first_name": "admin",
            "last_name": "User",
            "tenants": [
                {
                    "tenant_id": "tenant_123",
                    "roles": [
                        {
                            "role_name": "Owner"
                        }
                    ],
                    "status": "active"
                }
            ],
            "is_active": true
        }
    ]
}
```

### Remove Pending Invitation
**Request:**

```bash
curl -X DELETE "https://api.ssojet.com/api/v1/tenants/tenant_123/invitations?client_id=${CLIENT_ID}&invitation_id=inv_12345" \
  -H "Authorization: Bearer ${MANAGEMENT_TOKEN}"
```

**Response (200 OK):**

```json
{
  "success": true
}
```

### Remove Active Member
**Request:**

```bash
curl -X DELETE "https://api.ssojet.com/api/v1/tenants/tenant_123/users?client_id=${CLIENT_ID}" \
  -H "Authorization: Bearer ${MANAGEMENT_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "user_ids": ["user_123"]
  }'
```

**Response (200 OK):**

```json
{
  "success": true
}
```

### Resend Invitation
**Request:**

```bash
curl -X POST "https://api.ssojet.com/api/v1/tenants/tenant_123/invitations/resend?client_id=${CLIENT_ID}" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "invitation_id": "inv_12345",
    "invitee": {
      "email": "new.member@acme.com",
      "first_name": "New",
      "last_name": "Member"
    }
  }'
```

**Response (200 OK):**

```json
{
  "success": true
}
```

## Error Code Mapping

| Status Code | Cause | Fix |
| :--- | :--- | :--- |
| **400 Bad Request** | Invalid email or parameters | Validate email format and required fields. |
| **401 Unauthorized** | Missing/Invalid Token or Permissions | Verify Bearer token and admin privileges. |
| **404 Not Found** | Tenant or Invitation ID not found | Check IDs. Invitation may be expired/revoked. |
| **500 Internal Server Error** | Service Error | Retry with backoff. |

## Runnable Verification

### Cycle: Invite -> List -> Revoke
```bash
## 1. Invite
INVITE_RESP=$(curl -s -X POST "https://api.ssojet.com/api/v1/tenants/${TENANT_ID}/invitations?client_id=${CLIENT_ID}" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "invitee": { "email": "test.invite.'$(date +%s)'@example.com", "first_name": "Test", "last_name": "User" },
    "inviter": { "email": "admin@example.com", "first_name": "Admin", "last_name": "User" },
    "role_ids": ["role_viewer"],
    "expire_in_minutes": 60,
    "send_invitation_email": false
  }')
echo "Invite Sent: $INVITE_RESP"

## 2. List
curl "https://api.ssojet.com/api/v1/tenants/${TENANT_ID}/invitations?client_id=${CLIENT_ID}&status=pending" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}"

## 3. Revoke (Assuming we can fish out the ID from List response if needed, but for now just showing the command)
## curl -X DELETE "https://api.ssojet.com/api/v1/tenants/${TENANT_ID}/invitations?client_id=${CLIENT_ID}&invitation_id=<INVITE_ID>" \
##   -H "Authorization: Bearer ${ACCESS_TOKEN}"
```
