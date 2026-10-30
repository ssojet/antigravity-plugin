# SSOJet Directory Sync (SCIM) API

> **Load for:** intent api:directory-sync

## Step 1: Fetch Documentation
**STOP. WebFetch the relevant docs for latest implementation details before proceeding.**

- [List Directories](https://api.ssojet.com/api/v1/tenants/{tenantid}/directories)
- [Get Directory](https://api.ssojet.com/api/v1/tenants/{tenantid}/directories/{directoryid})
- [List Directory Users](https://api.ssojet.com/api/v1/tenants/{tenantid}/directories/{directoryid}/users)
- [List Directory Groups](https://api.ssojet.com/api/v1/tenants/{tenantid}/directories/{directoryid}/groups)

## Operation Decision Tree
```
Need to sync identities from IdP?
├─ Listing directories for a tenant → GET /tenants/{tenantid}/directories
├─ Fetching directory details → GET /tenants/{tenantid}/directories/{directoryid}
├─ Listing synced users → GET /tenants/{tenantid}/directories/{directoryid}/users
└─ Listing synced groups → GET /tenants/{tenantid}/directories/{directoryid}/groups
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
| GET | `/tenants/{tenantid}/directories` | List configured directories for a tenant |
| GET | `/tenants/{tenantid}/directories/{directoryid}` | Get details of a specific directory |
| GET | `/tenants/{tenantid}/directories/{directoryid}/users` | List users synced from directory |
| GET | `/tenants/{tenantid}/directories/{directoryid}/users/{userid}` | Get raw synced user details |
| GET | `/tenants/{tenantid}/directories/{directoryid}/groups` | List groups synced from directory |
| GET | `/tenants/{tenantid}/directories/{directoryid}/groups/{groupid}` | Get raw synced group details |

## Request/Response Patterns

### List Directories
**Request:**

```bash
curl "https://api.ssojet.com/api/v1/tenants/tenant_123/directories?client_id=${CLIENT_ID}" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}"
```

**Response (200 OK):**

```json
{
  "directories": [
    {
      "id": "dir_01H2...",
      "name": "Acme Azure AD",
      "type": "azure_ad",
      "state": "active",
      "created_at": "2023-01-01T00:00:00Z"
    }
  ]
}
```

### List Directory Users
**Request:**

```bash
curl "https://api.ssojet.com/api/v1/tenants/tenant_123/directories/dir_01H2.../users?client_id=${CLIENT_ID}&limit=10" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}"
```

**Response (200 OK):**

```json
{
  "limit": 10,
  "next_cursor": "eyJ...",
  "users": [
    {
      "id": "user_01H...",
      "username": "jane.doe@acme.com",
      "first_name": "Jane",
      "last_name": "Doe",
      "emails": [{"value": "jane.doe@acme.com", "primary": true}],
      "raw_attributes": { "jobTitle": "Engineer" }
    }
  ]
}
```

### List Directory Groups
**Request:**

```bash
curl "https://api.ssojet.com/api/v1/tenants/tenant_123/directories/dir_01H2.../groups?client_id=${CLIENT_ID}&limit=10" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}"
```

**Response (200 OK):**

```json
{
  "limit": 10,
  "next_cursor": "eyJ...",
  "groups": [
    {
      "id": "grp_01H...",
      "name": "Engineering",
      "raw_attributes": {}
    }
  ]
}
```

## Pagination Handling
The List Users and Groups endpoints use cursor-based pagination:

- **Initial request:** `GET ...?limit=10`
- **Response** includes `next_cursor`
- **Next page:** `GET ...?limit=10&cursor=eyJ...`
- **Repeat** until `next_cursor` is null or empty.

## Error Code Mapping

| Status Code | Cause | Fix |
| :--- | :--- | :--- |
| **401 Unauthorized** | Missing/Invalid Token | Verify Bearer token. |
| **404 Not Found** | Tenant or Directory ID not found | Check URIs and IDs. |
| **500 Internal Server Error** | Service Error | Retry with backoff. |

## Runnable Verification

### Verify Directory Access
```bash
## List Directories
curl "https://api.ssojet.com/api/v1/tenants/${TENANT_ID}/directories?client_id=${CLIENT_ID}" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}"
```
